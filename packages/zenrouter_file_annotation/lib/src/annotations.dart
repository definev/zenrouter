/// Annotations for file-based routing with ZenRouter.
///
/// These annotations are used by the code generator to create
/// type-safe routing infrastructure based on file structure.
///
/// The annotations in this file are used by the build system to generate
/// route classes, layouts, and coordinators from your file structure.
library;

/// Strategy for handling deep links.
///
/// This enum matches zenrouter's `DeeplinkStrategy` enum and is used
/// during code generation. The generator maps these values to zenrouter's
/// `DeeplinkStrategy` when generating code.
///
/// The values are:
/// - `replace` - Replace entire navigation stack with this route (default)
/// - `push` - Push this route onto the existing stack
/// - `custom` - Use custom `deeplinkHandler()` method
enum DeeplinkStrategyType {
  /// Replace entire navigation stack with this route (default).
  replace,

  /// Push this route onto the existing stack.
  push,

  /// Use custom deeplinkHandler() method.
  custom,
}

/// Type of navigation path for layouts.
enum LayoutType {
  /// Stack-based navigation with push/pop operations.
  /// Uses NavigationPath internally.
  stack,

  /// Index-based navigation for tabs/drawers.
  /// Uses IndexedStackPath internally.
  indexed,
}

/// Marks a class as a route in the file-based routing system.
///
/// The route's URI path is derived from its file location within
/// the `routes/` directory.
///
/// ## Basic Usage
///
/// ```dart
/// // lib/routes/about.dart -> /about
/// @ZenRoute()
/// class AboutRoute extends _$AboutRoute {
///   @override
///   Widget build(AppCoordinator coordinator, BuildContext context) {
///     return AboutScreen();
///   }
/// }
/// ```
///
/// ## Dynamic Parameters
///
/// For files named with brackets like `[id].dart`, the parameter
/// is automatically extracted:
///
/// ```dart
/// // lib/routes/profile/[id].dart -> /profile/:id
/// @ZenRoute()
/// class ProfileIdRoute extends _$ProfileIdRoute {
///   @override
///   Widget build(AppCoordinator coordinator, BuildContext context) {
///     return ProfileScreen(userId: id); // 'id' is auto-generated
///   }
/// }
/// ```
///
/// ## Route Mixins
///
/// Enable optional route behaviors:
///
/// ```dart
/// @ZenRoute(
///   guard: true,      // Enable RouteGuard mixin
///   redirect: true,   // Enable RouteRedirect mixin
///   deepLink: DeeplinkStrategyType.custom, // Enable RouteDeepLink mixin
/// )
/// class CheckoutRoute extends _$CheckoutRoute {
///   // Implement required mixin methods...
/// }
/// ```
///
/// ## Query Parameters
///
/// Declare expected query parameters:
///
/// ```dart
/// @ZenRoute(queries: ['search', 'page'])
/// class SearchRoute extends _$SearchRoute {
///   @override
///   Widget build(AppCoordinator coordinator, BuildContext context) {
///     final searchTerm = query('search');
///     final page = query('page');
///     return SearchScreen(search: searchTerm, page: page);
///   }
/// }
/// ```
class ZenRoute {
  /// Whether this route should have the RouteGuard mixin.
  ///
  /// When true, you must implement `popGuard()` to control
  /// whether navigation away from this route is allowed.
  final bool guard;

  /// Whether this route should have the RouteRedirect mixin.
  ///
  /// When true, you must implement `redirect()` to conditionally
  /// redirect to a different route (e.g., for auth checks).
  final bool redirect;

  /// Deep link handling strategy for this route.
  ///
  /// - `null` - No special deep link handling (default behavior)
  /// - `DeeplinkStrategyType.replace` - Replace stack when deep linking
  /// - `DeeplinkStrategyType.push` - Push onto existing stack
  /// - `DeeplinkStrategyType.custom` - Use custom `deeplinkHandler()`
  ///
  /// This maps to zenrouter's `DeeplinkStrategy` enum when generating code.
  final DeeplinkStrategyType? deepLink;

  /// Whether this route should have the RouteTransition mixin.
  ///
  /// When true, you must implement `transition()` to provide
  /// custom page transition animations.
  final bool transition;

  /// Whether this route can have the deferred import.
  ///
  /// When true, the generator will use this route as a `deferred as` import.
  /// It's useful to reduce the initial app size. One caveat is that the
  /// deferred import [Route] can't be used in [IndexedStackPath] since it fixed,
  /// loaded at runtime and can't be changed at runtime.
  final bool deferredImport;

  /// List of expected query parameter names.
  ///
  /// When provided, the route will have access to query parameters
  /// via the `queries` field and `query()` method.
  ///
  /// Example: `queries: ['search', 'page']` enables `query('search')` and `query('page')`.
  final List<String>? queries;

  /// Creates a route annotation.
  const ZenRoute({
    this.guard = false,
    this.redirect = false,
    this.deepLink,
    this.transition = false,
    this.deferredImport = false,
    this.queries,
  });
}

/// Marks a class as a layout in the file-based routing system.
///
/// Layouts manage nested navigation by wrapping child routes in a
/// common UI structure (like a tab bar or navigation shell).
///
/// ## Stack Layout (NavigationPath)
///
/// For stack-based push/pop navigation:
///
/// ```dart
/// // lib/routes/settings/_layout.dart
/// @ZenLayout(type: LayoutType.stack)
/// class SettingsLayout extends _$SettingsLayout {
///   @override
///   Widget build(AppCoordinator coordinator, BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Settings')),
///       body: buildPath(coordinator),
///     );
///   }
/// }
/// ```
///
/// ## Indexed Layout (IndexedStackPath)
///
/// For tab-based or indexed navigation:
///
/// ```dart
/// // lib/routes/tabs/_layout.dart
/// @ZenLayout(
///   type: LayoutType.indexed,
///   routes: [FeedRoute, ProfileRoute, SettingsRoute],
/// )
/// class TabsLayout extends _$TabsLayout {
///   @override
///   Widget build(AppCoordinator coordinator, BuildContext context) {
///     final path = resolvePath(coordinator);
///     return Scaffold(
///       body: buildPath(coordinator),
///       bottomNavigationBar: BottomNavigationBar(
///         currentIndex: path.activePathIndex,
///         onTap: (i) => coordinator.push(path.stack[i]),
///         items: [...], // User defines UI
///       ),
///     );
///   }
/// }
/// ```
class ZenLayout {
  /// The type of navigation path this layout manages.
  final LayoutType type;

  /// For indexed layouts, the route types in order.
  ///
  /// The order determines the index of each tab.
  /// Only used when [type] is [LayoutType.indexed].
  final List<Type>? routes;

  /// Creates a layout annotation.
  const ZenLayout({required this.type, this.routes});
}

/// Configuration for the generated Coordinator.
///
/// Place this annotation on a class in `routes/_coordinator.dart`
/// to customize the generated coordinator.
///
/// ```dart
/// // lib/routes/_coordinator.dart
/// @ZenCoordinator(
///   name: 'AppCoordinator',
///   routeBase: 'AppRoute',
///   deferredImport: true,
/// )
/// class CoordinatorConfig {}
/// ```
class ZenCoordinator {
  /// The name of the generated Coordinator class.
  /// Defaults to 'AppCoordinator'.
  final String name;

  /// The name of the base route class.
  /// Defaults to 'AppRoute'.
  final String routeBase;

  /// Path to import the base route class from.
  ///
  /// When set, the generator will import and export the base class from
  /// this path instead of generating it. Use this when you have a custom
  /// base route class defined elsewhere.
  ///
  /// Example:
  /// ```dart
  /// @ZenCoordinator(
  ///   routeBase: 'MyAppRoute',
  ///   routeBasePath: 'package:my_app/routes/base_route.dart',
  /// )
  /// ```
  final String? routeBasePath;

  /// Global deferred import configuration.
  ///
  /// When true, all routes will use deferred imports unless explicitly
  /// disabled with `@ZenRoute(deferredImport: false)`.
  ///
  /// This setting overrides the `deferredImport` option in `build.yaml`.
  /// Defaults to null (uses `build.yaml` config or false if not specified).
  final bool? deferredImport;

  /// Creates a coordinator configuration annotation.
  const ZenCoordinator({
    this.name = 'AppCoordinator',
    this.routeBase = 'AppRoute',
    this.routeBasePath,
    this.deferredImport,
  });
}
