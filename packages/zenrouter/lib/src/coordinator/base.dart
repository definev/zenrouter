import 'package:flutter/material.dart';
import 'package:zenrouter/src/coordinator/layout.dart';
import 'package:zenrouter/zenrouter.dart';

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
    with
        CoordinatorLayout<T>,
        CoordinatorRestoration<T>,
        CoordinatorTransitionStrategy<T>
    implements RouterConfig<Uri>, RouteModule<T>, ChangeNotifier {
  Coordinator({super.initialRoutePath});

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

  /// Parses a [Uri] into a route object synchronously.
  ///
  /// If you have an asynchronous [parseRouteFromUri] and still want [restoration] working,
  /// you have to provide a synchronous version of it.
  RouteUriParserSync<T> get parseRouteFromUriSync =>
      (uri) => parseRouteFromUri(uri) as T;

  /// Returns all active [RouteLayout] instances in the navigation hierarchy.
  ///
  /// This traverses through the active route to collect all layouts from root
  /// to the deepest layout. Returns an empty list if no layouts are active.
  List<RouteLayout> get activeLayouts => activeLayoutParentList;

  @override
  List<RouteLayout> get activeLayoutParentList =>
      super.activeLayoutParentList.cast();

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// This traverses through nested layouts to find the most deeply nested
  /// layout that is currently active. Returns `null` if the root layout is active.
  RouteLayout? get activeLayout => activeLayoutParent;

  @override
  RouteLayout? get activeLayoutParent =>
      super.activeLayoutParent as RouteLayout?;

  /// [ChangeNotifier] compatibility implementation for [Coordinator]
  // coverage:ignore-start
  final _proxy = ChangeNotifier();

  @override
  void addListener(VoidCallback listener) => _proxy.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _proxy.removeListener(listener);

  @override
  void notifyListeners() => _proxy.notifyListeners();

  @override
  bool get hasListeners => _proxy.hasListeners;
  // coverage:ignore-end

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget layoutBuilder(BuildContext context) => RouteLayout.buildRoot(this);

  /// Defines new layout parent constructor so [RouteLayoutChild] can look it up via
  /// [RouteLayoutChild.parentLayoutKey] and create new instance of layout parent.
  ///
  /// Normally, in [Coordinator] context, the [RouteLayoutChild.parentLayoutKey] is the [runtimeType] the [RouteLayout].
  ///
  /// You can override this behavior by defining your own [RouteLayoutChild.parentLayoutKey] in your [RouteLayout].
  void defineLayoutParent(RouteLayoutConstructor constructor) {
    final instance = constructor()..onDiscard();
    defineLayoutParentConstructor(instance.layoutKey, (_) => constructor());
    encodeLayoutKey(instance.layoutKey);
  }

  /// {@macro zenrouter.CoordinatorRouterDelegate}
  @override
  late final CoordinatorRouterDelegate routerDelegate =
      CoordinatorRouterDelegate(coordinator: this);

  /// {@macro zenrouter.CoordinatorRouteParser}
  @override
  late final CoordinatorRouteParser routeInformationParser =
      CoordinatorRouteParser(coordinator: this);

  /// Report to a [Router] when the user taps the back button on platforms that
  /// support back buttons (such as Android).
  ///
  /// When [Router] widgets are nested, consider using a
  /// [ChildBackButtonDispatcher], passing it the parent [BackButtonDispatcher],
  /// so that the back button requests get dispatched to the appropriate [Router].
  /// To make this work properly, it's important that whenever a [Router] thinks
  /// it should get the back button messages (e.g. after the user taps inside it),
  /// it calls [takePriority] on its [BackButtonDispatcher] (or
  /// [ChildBackButtonDispatcher]) instance.
  ///
  /// The class takes a single callback, which must return a [Future<bool>]. The
  /// callback's semantics match [WidgetsBindingObserver.didPopRoute]'s, namely,
  /// the callback should return a future that completes to true if it can handle
  /// the pop request, and a future that completes to false otherwise.
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
