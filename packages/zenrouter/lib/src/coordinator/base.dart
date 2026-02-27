import 'package:flutter/material.dart';
import 'package:zenrouter/src/coordinator/layout.dart';
import 'package:zenrouter/zenrouter.dart';

/// The Flutter-specific implementation of navigation coordinator.
///
/// ## Inheritance Architecture
///
/// ```
/// Coordinator<T extends RouteUnique>
///   extends CoordinatorCore<T>           // Core navigation logic
///   with CoordinatorLayout<T>,           // Layout builders
///        CoordinatorRestoration<T>,      // State restoration
///        CoordinatorTransitionStrategy<T> // Page transitions
///   implements RouterConfig<Uri>,         // Flutter Router integration
///            RouteModule<T>,              // Modular navigation support
///            ChangeNotifier               // Observable state
/// ```
///
/// ## Role in Navigation Flow
///
/// [Coordinator] orchestrates navigation by:
/// 1. Receiving navigation calls via [push], [pop], [replace], [navigate]
/// 2. Processing redirects through [RouteRedirect.resolve]
/// 3. Resolving layout hierarchies via [RouteLayoutParent]
/// 4. Updating appropriate [StackPath] (push/pop/activate)
/// 5. Triggering UI rebuilds through [NavigationStack]
/// 6. Synchronizing browser URL via [CoordinatorRouterDelegate]
///
/// ## Class Architecture
///
/// This class composes functionality from multiple sources:
///
/// | Component | Responsibility |
/// |-----------|----------------|
/// | [CoordinatorCore] | Core navigation logic (push, pop, replace) |
/// | [CoordinatorLayout] | Layout builder registration and parent constructors |
/// | [CoordinatorRestoration] | State restoration key encoding/decoding |
/// | [CoordinatorTransitionStrategy] | Default page transition configuration |
///
/// ## Abstract Nature
///
/// This is an **abstract class** that requires implementation of:
/// - [parseRouteFromUri]: Convert URIs to route objects
///
/// You must extend this class and provide the required implementation:
///
/// ```dart
/// class AppCoordinator extends Coordinator<AppRoute> {
///   @override
///   FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
///     // Your URI parsing logic
///   }
/// }
/// ```
///
/// ## Relationship with CoordinatorModular
///
/// [Coordinator] can operate in two modes:
///
/// **Standalone Mode** (default):
/// - Has its own root [NavigationPath]
/// - Can be used directly with [MaterialApp.router]
/// - Full control over navigation state
///
/// **Modular Mode** (part of [CoordinatorModular]):
/// - Shares root path with parent coordinator
/// - Cannot use [routerDelegate] or [routeInformationParser]
/// - Integrates into larger navigation hierarchy
/// - Access parent via [coordinator] getter
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
///   routerConfig: coordinator,
/// )
/// ```
abstract class Coordinator<T extends RouteUnique> extends CoordinatorCore<T>
    with
        CoordinatorLayout<T>,
        CoordinatorRestoration<T>,
        CoordinatorTransitionStrategy<T>
    implements RouterConfig<Uri>, RouteModule<T>, ChangeNotifier {
  Coordinator({super.initialRoutePath});

  /// Disposes the coordinator and its resources.
  ///
  /// ## Relationship
  /// Disposes in order: [routerDelegate], internal notifier, then [CoordinatorCore].
  /// Ensures proper cleanup of Flutter Router integration.
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
  /// ## When to Override
  /// Override if you need a custom root path configuration.
  ///
  /// ## Relationship
  /// In modular mode, returns parent's root via [coordinator].
  @override
  NavigationPath<T> get root => _root;

  /// Parses a [Uri] into a route object synchronously.
  ///
  /// ## When to Override
  /// Override if [parseRouteFromUri] is asynchronous and you need state restoration.
  ///
  /// ## Relationship
  /// Used by [NavigationPathRestorable] during state restoration.
  RouteUriParserSync<T> get parseRouteFromUriSync =>
      (uri) => parseRouteFromUri(uri) as T;

  /// Returns all active [RouteLayout] instances in the navigation hierarchy.
  ///
  /// ## Relationship
  /// Traverses from root to deepest layout, collecting all [RouteLayoutParent]
  /// instances. Returns empty list if no layouts are active.
  List<RouteLayout> get activeLayouts => activeLayoutParentList;

  @override
  List<RouteLayout> get activeLayoutParentList =>
      super.activeLayoutParentList.cast();

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// ## Relationship
  /// Finds the most deeply nested active layout by traversing the hierarchy.
  /// Returns `null` if only the root layout is active.
  RouteLayout? get activeLayout => activeLayoutParent;

  @override
  RouteLayout? get activeLayoutParent =>
      super.activeLayoutParent as RouteLayout?;

  // coverage:ignore-start
  /// ChangeNotifier implementation for observing state changes.
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
  /// ## When to Override
  /// Override to customize the root navigation structure.
  ///
  /// ## Relationship
  /// Called by [CoordinatorRouterDelegate.build] to create the widget tree.
  /// Delegates to [RouteLayout.buildRoot] by default.
  Widget layoutBuilder(BuildContext context) => RouteLayout.buildRoot(this);

  /// Defines new layout parent constructor so [RouteLayoutChild] can look it up via
  /// [RouteLayoutChild.parentLayoutKey] and create new instance of layout parent.
  ///
  /// ## When to Override
  /// Override [defineLayout] in your coordinator subclass instead of calling
  /// this directly.
  ///
  /// ## Relationship
  /// - Registers constructor with [CoordinatorLayout.defineLayoutParentConstructor]
  /// - Encodes layout key for restoration via [CoordinatorRestoration.encodeLayoutKey]
  void defineLayoutParent(RouteLayoutConstructor constructor) {
    final instance = constructor()..onDiscard();
    defineLayoutParentConstructor(instance.layoutKey, (_) => constructor());
    encodeLayoutKey(instance.layoutKey);
  }

  /// {@macro zenrouter.CoordinatorRouterDelegate}
  ///
  /// ## Relationship
  /// Bridges the coordinator to Flutter's Router widget. Manages navigator stack
  /// and handles browser navigation events.
  @override
  late final CoordinatorRouterDelegate routerDelegate =
      CoordinatorRouterDelegate(coordinator: this);

  /// {@macro zenrouter.CoordinatorRouteParser}
  ///
  /// ## Relationship
  /// Parses [RouteInformation] to and from [Uri] for Flutter's Router.
  @override
  late final CoordinatorRouteParser routeInformationParser =
      CoordinatorRouteParser(coordinator: this);

  /// Report to a [Router] when the user taps the back button on platforms that
  /// support back buttons (such as Android).
  ///
  /// ## Relationship
  /// Reports back button taps to the [Router]. Uses [RootBackButtonDispatcher]
  /// for the root coordinator. Nested routers should use [ChildBackButtonDispatcher].
  @override
  final BackButtonDispatcher backButtonDispatcher = RootBackButtonDispatcher();

  /// The [RouteInformationProvider] that is used to configure the [Router].
  ///
  /// ## Relationship
  /// Supplies the initial URI from [initialRoutePath] or defaults to `/`.
  @override
  late final RouteInformationProvider routeInformationProvider =
      PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
          uri: _resolveInitialUri(initialRoutePath),
        ),
      );

  Uri _resolveInitialUri(Uri? initialUri) {
    final defaultUri = Uri.tryParse(
      WidgetsBinding.instance.platformDispatcher.defaultRouteName,
    );
    if (defaultUri?.hasEmptyPath == true && initialUri != null) {
      return initialUri;
    }

    if (defaultUri != null && defaultUri.hasEmptyPath) {
      return defaultUri.replace(path: '/');
    }

    return defaultUri ?? Uri();
  }

  /// Access to the navigator state.
  ///
  /// ## Relationship
  /// Retrieved from [routerDelegate.navigatorKey]. Useful for imperative
  /// navigator operations like showing dialogs or bottom sheets.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
}
