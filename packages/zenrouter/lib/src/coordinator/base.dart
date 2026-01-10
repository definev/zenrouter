import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/src/internal/equatable.dart';
import 'package:zenrouter/zenrouter.dart';

/// Strategy for resolving parent layouts during navigation.
enum _ResolveLayoutStrategy {
  /// Pushes the layout to the top of the stack.
  ///
  /// Used when pushing new routes (e.g., [Coordinator.push]) to ensure
  /// the new route's layout is added on top of the current stack.
  pushToTop,

  /// Directly activates the layout, potentially resetting the stack.
  ///
  /// This is the default strategy used for [Coordinator.replace] or
  /// when recovering deep links, where the goal is to set a specific state.
  override,
}

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
abstract class Coordinator<T extends RouteUnique> extends Equatable
    with ChangeNotifier
    implements RouterConfig<Uri> {
  Coordinator({this.initialRoutePath}) {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
    defineLayout();
    defineConverter();
  }

  @override
  void dispose() {
    routerDelegate.dispose();
    for (final path in paths) {
      path.removeListener(notifyListeners);
    }
    root.dispose();
    super.dispose();
  }

  /// The root (primary) navigation path.
  ///
  /// All coordinators have at least this one path.
  late final NavigationPath<T> root = NavigationPath.createWith(
    label: 'root',
    coordinator: this,
  );

  /// All navigation paths managed by this coordinator.
  ///
  /// If you add custom paths, make sure to override [paths]
  @mustCallSuper
  List<StackPath> get paths => [root];

  /// Defines the layout structure for this coordinator.
  ///
  /// This method is called during initialization. Override this to register
  /// custom layouts using [RouteLayout.defineLayout].
  void defineLayout() {}

  /// Defines the restorable converters for this coordinator.
  ///
  /// Override this method to register custom restorable converters using
  /// [RestorableConverter.defineConverter].
  void defineConverter() {}

  String resolveRouteId(covariant T route) {
    RouteLayout? layout = route.resolveLayout(this);
    List<RouteLayout> layouts = [];
    List<StackPath> layoutPaths = [];
    while (layout != null) {
      layouts.add(layout);
      layoutPaths.add(layout.resolvePath(this));
      layout = layout.resolveLayout(this);
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

  /// The restoration ID for the root path.
  ///
  /// This ID is used to restore the root path when the app is re-launched.
  String get rootRestorationId => root.debugLabel ?? 'root';

  /// The initial route path for this coordinator.
  ///
  /// This path is used to set the initial route when the app is launched.
  final Uri? initialRoutePath;

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

  /// Returns the current URI based on the active route.
  Uri get currentUri => activePath.activeRoute?.toUri() ?? Uri.parse('/');

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// This traverses through nested layouts to find the most deeply nested
  /// layout that is currently active. Returns `null` if the root layout is active.
  RouteLayout? get activeLayout {
    T? current = root.activeRoute;
    if (current == null || current is! RouteLayout) return null;

    RouteLayout? deepestLayout = current;

    // Traverse through nested layouts to find the deepest one
    while (current is RouteLayout) {
      deepestLayout = current;
      final path = current.resolvePath(this);
      current = path.activeRoute as T?;

      // If the next route is not a layout, we've found the deepest layout
      if (current is! RouteLayout) break;
    }

    return deepestLayout;
  }

  /// Returns all active [RouteLayout] instances in the navigation hierarchy.
  ///
  /// This traverses through the active route to collect all layouts from root
  /// to the deepest layout. Returns an empty list if no layouts are active.
  List<RouteLayout> get activeLayouts {
    List<RouteLayout> layouts = [];
    T? current = root.activeRoute;

    // Traverse through the hierarchy and collect all RouteLayout instances
    while (current != null && current is RouteLayout) {
      layouts.add(current);
      final path = current.resolvePath(this);
      current = path.activeRoute as T?;
    }

    return layouts;
  }

  // coverage:ignore-start
  /// Returns the list of active layout paths in the navigation hierarchy.
  ///
  /// This starts from the [root] path and traverses down through active layouts,
  /// collecting the [StackPath] for each level.
  @Deprecated('Use `activeLayoutPaths` instead')
  List<StackPath> get activeHostPaths => activeLayoutPaths;
  // coverage:ignore-end

  /// Returns the list of active layout paths in the navigation hierarchy.
  ///
  /// This starts from the [root] path and traverses down through active layouts,
  /// collecting the [StackPath] for each level.
  List<StackPath> get activeLayoutPaths {
    List<StackPath> pathSegment = [root];
    StackPath path = root;
    T? current = root.stack.lastOrNull;
    if (current == null) return pathSegment;

    while (current is RouteLayout) {
      final layout = current as RouteLayout;
      path = layout.resolvePath(this);
      pathSegment.add(path);
      current = path.activeRoute as T?;
    }

    return pathSegment;
  }

  /// Returns the currently active [StackPath].
  ///
  /// This is the path that contains the currently active route.
  StackPath<T> get activePath =>
      (activeLayoutPaths.lastOrNull ?? root) as StackPath<T>;

  /// Parses a [Uri] into a route object.
  ///
  /// **Required override.** This is how deep links and web URLs become routes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// AppRoute parseRouteFromUri(Uri uri) {
  ///   return switch (uri.pathSegments) {
  ///     ['product', final id] => ProductRoute(id),
  ///     _ => HomeRoute(),
  ///   };
  /// }
  /// ```
  FutureOr<T> parseRouteFromUri(Uri uri);

  /// Parses a [Uri] into a route object synchronously.
  ///
  /// If you have an asynchronous [parseRouteFromUri] and still want [restoration] working,
  /// you have to provide a synchronous version of it.
  RouteUriParserSync<T> get parseRouteFromUriSync =>
      (uri) => parseRouteFromUri(uri) as T;

  /// Handles navigation from a deep link URI.
  ///
  /// If the route has [RouteDeepLink], its custom handler is called.
  /// Otherwise, [replace] is called.
  Future<void> recoverRouteFromUri(Uri uri) async {
    final route = await parseRouteFromUri(uri);
    return recover(route);
  }

  /// Resolves and activates layouts for a given [layout].
  ///
  /// This ensures that all parent layouts in the hierarchy are properly
  /// activated or pushed onto their respective paths.
  ///
  /// [preferPush] determines whether to push the layout onto the stack
  /// or just activate it if it already exists.
  Future<void> _resolveLayouts(
    RouteLayout? layout, {
    _ResolveLayoutStrategy strategy = _ResolveLayoutStrategy.override,
  }) async {
    List<RouteLayout> layouts = [];
    List<StackPath> layoutPaths = [];
    while (layout != null) {
      layouts.add(layout);
      layoutPaths.add(layout.resolvePath(this));
      layout = layout.resolveLayout(this);
    }
    layoutPaths.add(root);

    for (var i = layoutPaths.length - 1; i >= 1; i--) {
      final layoutOfLayoutPath = layoutPaths[i];
      final layout = layouts[i - 1];
      switch (strategy) {
        case _ResolveLayoutStrategy.pushToTop
            when layoutOfLayoutPath is StackMutatable:
          layoutOfLayoutPath.pushOrMoveToTop(layout);
        default:
          layoutOfLayoutPath.activateRoute(layout);
      }
    }
  }

  /// Recovers navigation state from a route, respecting deep link strategies.
  ///
  /// **When to use:**
  /// Use this when handling deep links or restoring navigation state.
  /// Prefer [push] for regular navigation and [replace] for resetting state.
  ///
  /// **Behavior:**
  /// - If the route implements [RouteDeepLink], uses its [DeeplinkStrategy]:
  ///   - [DeeplinkStrategy.push]: Calls [push] to add route to stack
  ///   - [DeeplinkStrategy.replace]: Calls [replace] to reset stack
  ///   - [DeeplinkStrategy.custom]: Calls the route's [deeplinkHandler]
  /// - Otherwise, defaults to [replace]
  ///
  /// **Error Handling:**
  /// Exceptions from redirect resolution or deep link handlers propagate
  /// to the caller. Handle these in your app's error boundary.
  Future<void> recover(T route) async {
    T? target = await RouteRedirect.resolve(route, this);
    if (target == null) return;
    if (target is RouteDeepLink) {
      switch (target.deeplinkStrategy) {
        case DeeplinkStrategy.navigate:
          navigate(target);
        case DeeplinkStrategy.push:
          push(target);
        case DeeplinkStrategy.replace:
          replace(target);
        case DeeplinkStrategy.custom:
          await target.deeplinkHandler(this, target.toUri());
      }
    } else {
      replace(target);
    }
  }

  /// Navigates to a specific route, handling history restoration and stack management.
  ///
  /// **Why this exists:**
  /// Standard [push] always adds a new route to the stack, which can lead to
  /// duplicate entries and confusing browser history (e.g., A -> B -> A -> B).
  /// [navigate] is smarter: it checks if the target route already exists in the
  /// stack (e.g., in a browser "Back" scenario) and pops back to it instead of
  /// pushing a new instance. This ensures the navigation stack mirrors the
  /// user's expected history state.
  ///
  /// This method is primarily used by [CoordinatorRouterDelegate.setNewRoutePath]
  /// to handle browser back/forward navigation or direct URL updates.
  ///
  /// **Behavior:**
  /// 1. Resolves the layout and path for the target [route].
  /// 2. If the active path is a [NavigationPath]:
  ///    - **Existing Route:** If the route is already in the stack (back navigation),
  ///      it progressively pops the stack until the target route is reached.
  ///      - Respects [RouteGuard]s during popping.
  ///      - If a guard blocks popping, navigation is aborted and the URL is restored.
  ///    - **New Route:** If the route is not in the stack, it calls [push] to add it.
  /// 3. If the active path is an [IndexedStackPath]:
  ///    - Resolves parent layouts and activates the target route (switching tabs).
  ///
  /// **Failure Handling:**
  /// If layout resolution fails or a guard blocks the navigation, [notifyListeners]
  /// is called to sync the browser URL back to the current application state.
  Future<void> navigate(T route) async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    final layout = target.resolveLayout(this);
    final routePath = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.pushToTop);

    assert(
      routePath is StackNavigatable,
      UnimplementedError(
        'ZenRouter: routePath (${routePath.runtimeType}) does not implement '
        'StackNavigatable. The navigate() call for route $route will have no '
        'effect on the navigation stack or browser history.',
      ),
    );

    if (routePath case StackNavigatable routePath) {
      await routePath.navigate(target);
    }
  }

  /// Clears all navigation stacks and navigates to a single route.
  ///
  /// **When to use:**
  /// - App startup/initialization
  /// - After logout (clear all navigation history)
  /// - Deep link recovery (default strategy)
  /// - Resetting to a known state
  ///
  /// **Avoid when:**
  /// - User is navigating forward (use [push] instead)
  /// - You want to preserve back navigation history
  ///
  /// **Behavior:**
  /// 1. Calls [reset] on ALL paths (clears entire navigation history)
  /// 2. Resolves any [RouteRedirect]s
  /// 3. Activates required layouts
  /// 4. Places the final route on its appropriate path
  ///
  /// **Error Handling:**
  /// Exceptions from redirect resolution propagate to the caller.
  /// Guards are NOT consulted since all routes are cleared.
  Future<void> replace(T route) async {
    T? target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    for (final path in paths) {
      path.reset();
    }

    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.override);

    await path.activateRoute(target);
  }

  /// Pushes a new route onto the navigation stack.
  ///
  /// **When to use:**
  /// - Standard forward navigation (user taps a button/link)
  /// - Opening details, forms, or modals
  /// - Any navigation where back should return to current screen
  ///
  /// **Avoid when:**
  /// - Handling deep links (use [recover] instead)
  /// - Resetting navigation state (use [replace] instead)
  /// - Browser back/forward navigation (use [navigate] instead)
  ///
  /// **Behavior:**
  /// 1. Resolves any [RouteRedirect]s (authentication, permissions, etc.)
  /// 2. Ensures required [RouteLayout] hierarchy is active
  /// 3. Adds the route to its [StackPath]
  ///
  /// **Result handling:**
  /// Returns a [Future] that completes when the route is popped:
  /// ```dart
  /// final result = await coordinator.push<String>(SelectColorRoute());
  /// if (result != null) {
  ///   print('User selected: $result');
  /// }
  /// ```
  ///
  /// **Error Handling:**
  /// Exceptions from redirect resolution propagate to the caller.
  Future<R?> push<R extends Object>(T route) async {
    T? target = await RouteRedirect.resolve(route, this);
    if (target == null) return null;

    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.pushToTop);

    switch (path) {
      case StackMutatable():
        return path.push(target);
      default:
        path.activateRoute(target);
        return null;
    }
  }

  /// Pushes a route or moves it to the top if already present.
  ///
  /// Useful for tab navigation where you don't want duplicates.
  void pushOrMoveToTop(T route) async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.pushToTop);

    switch (path) {
      case StackMutatable():
        path.pushOrMoveToTop(target);
      default:
        path.activateRoute(target);
    }
  }

  /// Pops the current route and pushes a new route in its place.
  ///
  /// **When to use:**
  /// - Swap screens during a wizard/onboarding flow
  /// - Replace a loading/splash screen with actual content
  /// - Login → Home transition where back should not return to login
  ///
  /// **Avoid when:**
  /// - You need to clear all navigation history (use [replace] instead)
  ///
  /// **Behavior:**
  /// 1. Resolves any [RouteRedirect]s
  /// 2. Ensures required [RouteLayout] hierarchy is active
  /// 3. Delegates to [StackMutatable.pushReplacement] which:
  ///    - On single-element stack: completes the route and pushes new one
  ///    - On multi-element stack: pops (respecting guards), then pushes
  ///
  /// **Result handling:**
  /// Pass [result] to complete the popped route's push future:
  /// ```dart
  /// // In screen A:
  /// final result = await coordinator.push<String>(ScreenB());
  /// print('Got: $result'); // Prints: Got: from_c
  ///
  /// // In screen B, replacing with C:
  /// coordinator.pushReplacement<void, String>(ScreenC(), result: 'from_c');
  /// ```
  ///
  /// **Error Handling:**
  /// - Returns `null` if redirect resolution returns null
  /// - Returns `null` if a [RouteGuard] blocks the pop operation
  /// - Exceptions from redirect resolution propagate to the caller
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T route, {
    RO? result,
  }) async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return null;

    final layout = target.resolveLayout(this);
    final path = layout?.resolvePath(this) ?? root;
    await _resolveLayouts(layout, strategy: _ResolveLayoutStrategy.pushToTop);

    if (path case StackMutatable()) {
      return path.pushReplacement(target, result: result);
    }

    return null;
  }

  /// Pops the last route from the nearest dynamic path.  /// Pops the last route from all eligible dynamic paths.
  ///
  /// This method looks up all active [StackMutatable] paths and attempts
  /// to pop from those whose stack contains at least two elements.
  ///
  /// The returned [Future] completes when all eligible pops have finished.
  /// If no dynamic paths can be popped, this method completes without
  /// performing any action.
  Future<void> pop([Object? result]) async {
    // Get all dynamic paths from the active layout paths
    final dynamicPaths = activeLayoutPaths.whereType<StackMutatable>().toList();

    // Try to pop from the farthest element if stack length >= 2
    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        await path.pop(result);
      }
    }
  }

  /// Builds the root widget (the primary navigator).
  ///
  /// Override to customize the root navigation structure.
  Widget layoutBuilder(BuildContext context) => RouteLayout.buildRoot(this);

  /// Attempts to pop the nearest dynamic path.
  /// The [RouteGuard] logic is handled here.
  ///
  /// Returns:
  /// - `true` if the route can pop
  /// - `false` if the route can't pop
  /// - `null` if the [RouteGuard] want manual control
  Future<bool?> tryPop([Object? result]) async {
    // Get all dynamic paths from the active layout paths
    final dynamicPaths = activeLayoutPaths.whereType<StackMutatable>().toList();

    // Try to pop from the farthest element if stack length >= 2
    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        return await path.pop(result);
      }
    }

    return false;
  }

  /// Marks the coordinator as needing a rebuild.
  void markNeedRebuild() => notifyListeners();

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
  final BackButtonDispatcher? backButtonDispatcher = null;

  /// The [RouteInformationProvider] that is used to configure the [Router].
  @override
  late final RouteInformationProvider routeInformationProvider =
      PlatformRouteInformationProvider(
        initialRouteInformation: RouteInformation(
          uri: initialRoutePath ?? Uri.parse('/'),
        ),
      );

  /// Creates a new router delegate with the given initial route.
  @Deprecated(
    'This method is deprecated. Use `routerDelegate` property instead. You can override `initialRoutePath` property to set initial route. Will be removed in v1.0.0',
  )
  CoordinatorRouterDelegate routerDelegateWithInitialRoute(T initialRoute) =>
      routerDelegate;

  /// Access to the navigator state.
  NavigatorState get navigator => routerDelegate.navigatorKey.currentState!;
}
