import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

part 'layout.dart';

/// The Flutter-specific implementation of navigation coordinator.
///
/// ## Inheritance Architecture
///
/// ```
/// Coordinator<T extends RouteUnique>
///   extends CoordinatorCore<T>           // Core state
///   with CoordinatorLayoutCore<T>,       // Layout-parent activation (core)
///        CoordinatorNavigatable<T>,      // navigate
///        CoordinatorMutatable<T>,        // push / pop / replace
///        CoordinatorRecoverable<T>,      // recover / deep links
///        CoordinatorLayout<T>,           // Flutter layout builders
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
        CoordinatorLayoutCore<T>,
        CoordinatorNavigatable<T>,
        CoordinatorMutatable<T>,
        CoordinatorRecoverable<T>,
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

  /// Defines new layout parent constructor so [RouteLayoutChild] can look it up via
  /// [RouteLayoutChild.parentLayoutKey] and create new instance of layout parent.
  ///
  /// ## When to Override
  /// Prefer [bindLayout] on the [StackPath] instead of calling this directly.
  ///
  /// ## Relationship
  /// - Registers constructor with [CoordinatorLayoutCore.defineLayoutParentConstructor]
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
  /// Supplies the initial URI, preferring any platform-provided route
  /// (e.g. from [PlatformDispatcher.defaultRouteName]), then falling back to
  /// [initialRoutePath] if set, and finally defaulting to `/`.
  @override
  late final RouteInformationProvider routeInformationProvider =
      CoordinatorRouteInformationProvider(coordinator: this);

  /// Access to the navigator state.
  ///
  /// ## Relationship
  /// Retrieved from [routerDelegate.navigatorKey]. Useful for imperative
  /// navigator operations like showing dialogs or bottom sheets.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
}
