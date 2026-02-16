import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// Strategy for controlling page transition animations in the navigator.
///
/// This enum defines how routes animate when pushed or popped from the
/// navigation stack. The strategy is used by [RouteLayout] when building
/// pages to determine the appropriate [PageTransitionsBuilder].
///
/// **Platform Recommendations:**
/// - **Android/Web/Desktop**: Use [material] for consistency with Material Design
/// - **iOS/macOS**: Use [cupertino] for native iOS-style transitions
/// - **Testing/Screenshots**: Use [none] to disable animations
///
/// Example:
/// ```dart
/// @override
/// DefaultTransitionStrategy get transitionStrategy {
///   // Use platform-appropriate transitions
///   if (Platform.isIOS || Platform.isMacOS) {
///     return DefaultTransitionStrategy.cupertino;
///   }
///   return DefaultTransitionStrategy.material;
/// }
/// ```
enum DefaultTransitionStrategy {
  /// Uses Material Design transitions.
  ///
  /// Provides slide-up, fade, and shared-axis transitions typical of
  /// Android applications. This is the default strategy.
  material,

  /// Uses Cupertino (iOS-style) transitions.
  ///
  /// Provides horizontal slide and parallax transitions typical of
  /// iOS applications, including the edge-swipe-to-go-back gesture.
  cupertino,

  /// Disables transition animations.
  ///
  /// Routes appear and disappear instantly without any animation.
  /// Useful for testing, taking screenshots, or when you want to
  /// implement fully custom transitions.
  none,
}

/// The core class that manages navigation state and logic.
///
/// ## Architecture Overview
///
/// ZenRouter uses a coordinator-based architecture where the [Coordinator]
/// is the central hub for all navigation operations.
///
/// ## Core Components
///
/// - **[Coordinator]**: Manages navigation state, handles deep links, and
///   coordinates between stack paths. Your app typically has one coordinator.
///
/// - **[StackPath]**: A container holding a stack of routes. Two variants:
///   - [NavigationPath]: Mutable stack (push/pop) for standard navigation
///   - [IndexedStackPath]: Fixed stack for indexed navigation (tabs)
///
/// - **[RouteTarget]**: Base class for all navigable destinations. Mix in:
///   - [RouteUnique]: Required for coordinator integration
///   - [RouteGuard]: Intercept and conditionally prevent pops
///   - [RouteRedirect]: Redirect to different routes
///   - [RouteLayout]: Define shell/wrapper with nested [StackPath]
///   - [RouteTransition]: Custom page transitions
///
/// ## Navigation Flow
///
/// When you call a navigation method:
///
/// 1. **Route Resolution**: [RouteRedirect.resolve] follows any redirects
/// 2. **Layout Resolution**: Find/create required [RouteLayout] hierarchy
/// 3. **Stack Update**: Push/pop/activate routes on appropriate [StackPath]
/// 4. **Widget Rebuild**: [NavigationStack] rebuilds with new pages
/// 5. **URL Update**: Browser URL synced via [CoordinatorRouterDelegate]
///
/// ## Navigation Methods
///
/// Choose the right navigation method for your use case:
///
/// | Method        | Use Case                                              |
/// |---------------|-------------------------------------------------------|
/// | [push]        | Standard forward navigation (adds to stack)           |
/// | [pop]         | Go back (removes from stack)                          |
/// | [replace]     | Reset navigation to a single route (clears stack)     |
/// | [navigate]    | Browser back/forward (smart stack manipulation)       |
/// | [recover]     | Deep link handling (respects [RouteDeepLink] strategy)|
///
/// See each method's documentation for detailed behavior and examples.
///
/// ## Quick Start
///
/// ```dart
/// // 1. Define your route type
/// abstract class AppRoute extends RouteTarget with RouteUnique {}
///
/// // 2. Create a coordinator
/// class AppCoordinator extends Coordinator<AppRoute> {
///   @override
///   FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
///     return switch (uri.pathSegments) {
///       ['product', final id] => ProductRoute(id),
///       _ => HomeRoute(),
///     };
///   }
/// }
///
/// // 3. Use in MaterialApp.router
/// MaterialApp.router(
///   routerDelegate: coordinator.routerDelegate,
///   routeInformationParser: coordinator.routeInformationParser,
/// )
/// ```
abstract class Coordinator<T extends RouteUnique> extends CoordinatorCore<T>
    with _CoordinatorRestorationImpl<T>, _CoordinatorRouteLayoutImpl<T>
    implements RouterConfig<Uri>, RouteModule<T>, ChangeNotifier {
  Coordinator({super.initialRoutePath}) {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
    defineLayout();
    defineConverter();
  }

  static final kDefaultLayoutBuilderTable = <PathKey, RouteLayoutBuilder>{
    NavigationPath.key: (coordinator, path, layout) {
      final restorationId = switch (layout) {
        RouteUnique route => coordinator.resolveRouteId(route),
        _ => coordinator.rootRestorationId,
      };

      return NavigationStack(
        path: path as NavigationPath<RouteUnique>,
        navigatorKey: layout == null
            ? coordinator.routerDelegate.navigatorKey
            : null,
        coordinator: coordinator,
        restorationId: restorationId,
        resolver: (route) {
          switch (route) {
            case RouteTransition():
              return route.transition(coordinator);
            default:
              final routeRestorationId = coordinator.resolveRouteId(route);
              final builder = Builder(
                builder: (context) => route.build(coordinator, context),
              );
              return switch (coordinator.transitionStrategy) {
                DefaultTransitionStrategy.material => StackTransition.material(
                  builder,
                  restorationId: routeRestorationId,
                ),
                DefaultTransitionStrategy.cupertino =>
                  StackTransition.cupertino(
                    builder,
                    restorationId: routeRestorationId,
                  ),
                DefaultTransitionStrategy.none => StackTransition.none(
                  builder,
                  restorationId: routeRestorationId,
                ),
              };
          }
        },
      );
    },
    IndexedStackPath.key: (coordinator, path, layout, [restorationId]) {
      return ListenableBuilder(
        listenable: path as Listenable,
        builder: (context, child) {
          final indexedStackPath = path as IndexedStackPath<RouteUnique>;
          return IndexedStackPathBuilder(
            path: indexedStackPath,
            coordinator: coordinator,
            restorationId: restorationId,
          );
        },
      );
    },
  };

  /// The [rootCoordinator] coordinator return a top level coordinator which used as [routeConfig].
  ///
  /// If this coordinator is a part of another [CoordinatorModular], it will return the [coordinator].
  /// Otherwise, it will return itself.
  @override
  Coordinator<T> get rootCoordinator =>
      isRouteModule ? (coordinator as Coordinator<T>) : this;

  @override
  void dispose() {
    routerDelegate.dispose();
    _proxy.dispose();
    super.dispose();
  }

  late final NavigationPath<T> _root = isRouteModule
      ? coordinator.root as NavigationPath<T>
      : NavigationPath.createWith(label: 'root', coordinator: this);

  /// The root (primary) navigation path.
  ///
  /// All coordinators have at least this one path.
  ///
  /// If this coordinator is a part of a [CoordinatorModular], the root path will point to the root path of the [CoordinatorModular].
  @override
  NavigationPath<T> get root => _root;

  /// The restoration ID for the root path.
  ///
  /// This ID is used to restore the root path when the app is re-launched.
  String get rootRestorationId => root.debugLabel ?? 'root';

  String resolveRouteId(covariant T route) {
    RouteLayout? layout = route.resolveLayout(this);
    List<RouteLayout> layouts = [];
    List<StackPath> layoutPaths = [];
    while (layout != null) {
      layouts.add(layout);
      layoutPaths.add(layout.resolvePath(this));
      layout = (layout as RouteUnique).resolveLayout(this);
    }

    String layoutRestorationId = layoutPaths
        .map((p) {
          final label = p.debugLabel;
          assert(
            label != null,
            '[StackPath] must have an unique label in order to use with Coordinator restorable',
          );
          return label!;
        })
        .join('_');
    layoutRestorationId = '${rootRestorationId}_$layoutRestorationId';
    final routeRestorationId = route is RouteRestorable
        ? (route as RouteRestorable).restorationId
        : route.toUri().toString();

    return '${layoutRestorationId}_$routeRestorationId';
  }

  /// The transition strategy for this coordinator.
  ///
  /// Override this getter to customize how page transitions are animated
  /// throughout your navigation stack. The strategy applies to all routes
  /// managed by this coordinator.
  ///
  /// **Default Behavior:**
  /// Returns [DefaultTransitionStrategy.material], which provides Material
  /// Design transitions (slide-up, fade effects).
  ///
  /// **Common Overrides:**
  /// ```dart
  /// // Platform-adaptive transitions
  /// @override
  /// DefaultTransitionStrategy get transitionStrategy {
  ///   return Platform.isIOS
  ///       ? DefaultTransitionStrategy.cupertino
  ///       : DefaultTransitionStrategy.material;
  /// }
  ///
  /// // Disable all transitions
  /// @override
  /// DefaultTransitionStrategy get transitionStrategy =>
  ///     DefaultTransitionStrategy.none;
  /// ```
  ///
  /// **Note:** This strategy is used by [RouteLayout] when constructing
  /// [Page] objects. If you need per-route transition control, consider
  /// implementing custom [RouteTransition] logic on individual routes instead.
  DefaultTransitionStrategy get transitionStrategy =>
      DefaultTransitionStrategy.material;

  /// Returns all active [RouteLayout] instances in the navigation hierarchy.
  ///
  /// This traverses through the active route to collect all layouts from root
  /// to the deepest layout. Returns an empty list if no layouts are active.
  List<RouteLayout> get activeLayouts =>
      activeRouteLayoutList.cast<RouteLayout>();

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// This traverses through nested layouts to find the most deeply nested
  /// layout that is currently active. Returns `null` if the root layout is active.
  RouteLayout? get activeLayout => activeRouteLayout as RouteLayout?;

  final ChangeNotifier _proxy = ChangeNotifier();
  @override
  void addListener(VoidCallback listener) => _proxy.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _proxy.removeListener(listener);

  // coverage:ignore-start
  @override
  void notifyListeners() => _proxy.notifyListeners();

  @override
  bool get hasListeners => _proxy.hasListeners;
  // coverage:ignore-end

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget layoutBuilder(BuildContext context) => RouteLayout.buildRoot(this);

  void defineRouteLayout(Object key, RouteLayoutConstructor constructor) {
    defineRouteLayoutParent(key, (key) => constructor());
    defineLayoutKey(key.toString(), key);
  }

  /// The router delegate for [Router] of this coordinator
  @override
  late final CoordinatorRouterDelegate routerDelegate =
      CoordinatorRouterDelegate(coordinator: this);

  /// The route information parser for [Router]
  @override
  late final CoordinatorRouteParser routeInformationParser =
      CoordinatorRouteParser(coordinator: this);

  /// The [BackButtonDispatcher] that is used to configure the [Router].
  @override
  final BackButtonDispatcher backButtonDispatcher = RootBackButtonDispatcher();

  /// The [RouteInformationProvider] that is used to configure the [Router].
  @override
  late final RouteInformationProvider routeInformationProvider =
      PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
          uri: initialRoutePath ?? Uri.parse('/'),
        ),
      );

  /// Access to the navigator state.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
}

mixin CoordinatorRestoration<T extends RouteUnique> on CoordinatorCore<T> {
  Object? getLayoutKey(String key);

  void defineLayoutKey(String key, Object value);
}

mixin _CoordinatorRestorationImpl<T extends RouteUnique> on CoordinatorCore<T>
    implements CoordinatorRestoration<T> {
  final _layoutKeyTable = <String, Object>{};

  @override
  Object? getLayoutKey(String key) => _layoutKeyTable[key];

  @override
  void defineLayoutKey(String key, Object value) =>
      _layoutKeyTable[key] = value;
}

mixin _CoordinatorRouteLayoutImpl<T extends RouteUnique> on CoordinatorCore<T> {
  final Map<Object, RouteLayoutParentConstructor>
  _layoutParentConstructorTable = {};

  Map<Object, RouteLayoutParentConstructor>
  get routeLayoutParentConstructorTable => isRouteModule
      ? (coordinator as _CoordinatorRouteLayoutImpl)
            .routeLayoutParentConstructorTable
      : _layoutParentConstructorTable;

  @override
  void defineRouteLayoutParent(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  ) {
    if (isRouteModule) {
      return coordinator.defineRouteLayoutParent(layoutKey, constructor);
    }

    _layoutParentConstructorTable[layoutKey] = constructor;
  }

  @override
  RouteLayoutParent? resolveRouteLayoutParent(Object layoutKey) {
    if (isRouteModule) return coordinator.resolveRouteLayoutParent(layoutKey);

    final constructor = _layoutParentConstructorTable[layoutKey];
    return constructor?.call(layoutKey);
  }

  final Map<PathKey, RouteLayoutBuilder> _layoutBuilderTable = {
    ...Coordinator.kDefaultLayoutBuilderTable,
  };

  RouteLayoutBuilder? getLayoutBuilder(PathKey key) => _layoutBuilderTable[key];

  void defineLayoutBuilder(PathKey key, RouteLayoutBuilder builder) =>
      _layoutBuilderTable[key] = builder;

  @override
  void dispose() {
    _layoutParentConstructorTable.clear();
    _layoutBuilderTable.clear();
    super.dispose();
  }
}
