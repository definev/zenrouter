import 'dart:async';

import 'package:meta/meta.dart';
import 'package:zenrouter_core/src/coordinator/modular.dart';

import 'package:zenrouter_core/src/internal/equatable.dart';
import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/src/internal/type.dart';
import 'package:zenrouter_core/src/mixin/deeplink.dart';
import 'package:zenrouter_core/src/mixin/identity.dart';
import 'package:zenrouter_core/src/mixin/layout.dart';
import 'package:zenrouter_core/src/mixin/redirect.dart';
import 'package:zenrouter_core/src/path/base.dart';
import 'package:zenrouter_core/src/path/navigatable.dart';

/// Strategy for resolving parent layouts during navigation.
enum _ResolveLayoutStrategy {
  /// Pushes the layout to the top of the stack.
  ///
  /// Used when pushing new routes (e.g., [CoordinatorCore.push]) to ensure
  /// the new route's layout is added on top of the current stack.
  pushToTop,

  /// Directly activates the layout, potentially resetting the stack.
  ///
  /// This is the default strategy used for [CoordinatorCore.replace] or
  /// when recovering deep links, where the goal is to set a specific state.
  override,
}

/// The core class that manages navigation state and logic.
///
/// ## Architecture Overview
///
/// ZenRouter uses a coordinator-based architecture where the [CoordinatorCore]
/// is the central hub for all navigation operations.
///
/// ## Core Components
///
/// - **[CoordinatorCore]**: Manages navigation state, handles deep links, and
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
/// 5. **URL Update**: Browser URL synced via [CoordinatorCoreRouterDelegate]
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
/// class AppCoordinatorCore extends CoordinatorCore<AppRoute> {
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
abstract class CoordinatorCore<T extends RouteIdentity> extends Equatable
    with ListenableObject
    implements RouteModule<T> {
  CoordinatorCore({this.initialRoutePath}) {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
    defineLayout();
    defineConverter();
  }

  /// {@macro zenrouter.coordinator.modular.coordinator}
  @override
  CoordinatorModular<T> get coordinator => throw UnimplementedError(
    'This coordinator is standalone and does not belong to any [CoordinatorCoreModular] \n'
    'If you want to make it a part of a [CoordinatorCoreModular] you should override `coordinator` getter or passing it through constructor',
  );

  /// The [rootCoordinator] coordinator return a top level coordinator which used as [routeConfig].
  ///
  /// If this coordinator is a part of another [CoordinatorCoreModular], it will return the [coordinator].
  /// Otherwise, it will return itself.
  late final CoordinatorCore<T> rootCoordinator = isRouteModule
      ? coordinator
      : this;

  @override
  void dispose() {
    for (final path in paths) {
      path.removeListener(notifyListeners);
      path.dispose();
    }
    super.dispose();
  }

  /// Whether this coordinator is a part of a [CoordinatorCoreModular].
  ///
  /// If it is a part of a [CoordinatorCoreModular], it will not have a root path.
  /// And it will not be able to use [routerDelegate] and [routeInformationParser].
  late final bool isRouteModule = () {
    try {
      coordinator;
      return true;
    } on UnimplementedError {
      return false;
    }
  }();

  /// The root (primary) navigation path.
  ///
  /// All coordinators have at least this one path.
  ///
  /// If this coordinator is a part of a [CoordinatorCoreModular], the root path will point to the root path of the [CoordinatorCoreModular].
  StackPath<T> get root;

  /// All navigation paths managed by this coordinator.
  ///
  /// If you add custom paths, make sure to override [paths]
  @override
  @mustCallSuper
  List<StackPath> get paths => isRouteModule ? [] : [root];

  /// Defines the layout structure for this coordinator.
  ///
  /// This method is called during initialization. Override this to register
  /// custom layouts using [RouteLayout.defineLayout].
  @override
  void defineLayout() {}

  /// Defines the restorable converters for this coordinator.
  ///
  /// Override this method to register custom restorable converters using
  /// [RestorableConverter.defineConverter].
  @override
  void defineConverter() {}

  /// The initial route path for this coordinator.
  ///
  /// This path is used to set the initial route when the app is launched.
  final Uri? initialRoutePath;

  /// Returns the current URI based on the active route.
  Uri get currentUri => activePath.activeRoute?.toUri() ?? Uri.parse('/');

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// This traverses through nested layouts to find the most deeply nested
  /// layout that is currently active. Returns `null` if the root layout is active.
  @protected
  RouteLayoutParent? get activeRouteLayout {
    T? current = root.activeRoute;
    if (current == null || current is! RouteLayoutParent) return null;

    RouteLayoutParent? deepestRoutePath = current as RouteLayoutParent;

    // Traverse through nested layouts to find the deepest one
    while (current is RouteLayoutParent) {
      deepestRoutePath = current as RouteLayoutParent;
      final path = deepestRoutePath.resolvePath(this);
      current = path.activeRoute as T?;

      // If the next route is not a layout, we've found the deepest layout
      if (current is! RouteLayoutParent) break;
    }

    return deepestRoutePath;
  }

  /// Returns all active [RouteLayout] instances in the navigation hierarchy.
  ///
  /// This traverses through the active route to collect all layouts from root
  /// to the deepest layout. Returns an empty list if no layouts are active.
  @protected
  List<RouteLayoutParent> get activeRouteLayoutList {
    List<RouteLayoutParent> layouts = [];
    T? current = root.activeRoute;

    // Traverse through the hierarchy and collect all RouteLayout instances
    while (current != null && current is RouteLayoutParent) {
      final routePath = current as RouteLayoutParent;
      layouts.add(routePath);
      final path = routePath.resolvePath(this);
      current = path.activeRoute as T?;
    }

    return layouts;
  }

  /// Returns the currently active [StackPath].
  ///
  /// This is the path that contains the currently active route.
  StackPath<T> get activePath =>
      (activePaths.lastOrNull ?? root) as StackPath<T>;

  /// Returns the list of active layout paths in the navigation hierarchy.
  ///
  /// This starts from the [root] path and traverses down through active layouts,
  /// collecting the [StackPath] for each level.
  @Deprecated('Use activeStackPaths instead')
  List<StackPath> get activeLayoutPaths => activePaths;

  List<StackPath> get activePaths {
    List<StackPath> pathSegment = [root];
    StackPath path = root;
    T? current = root.stack.lastOrNull;
    if (current == null) return pathSegment;

    while (current is RouteLayoutParent) {
      final layout = current as RouteLayoutParent;
      path = layout.resolvePath(this);
      pathSegment.add(path);
      current = path.activeRoute as T?;
    }

    return pathSegment;
  }

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
  @override
  FutureOr<T?> parseRouteFromUri(Uri uri);

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
    if (route == null) {
      throw StateError(
        'If you want to use coordinator deeplink feature, you must return route from [parseRouteFromUri]',
      );
    }
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
    RouteLayoutParent? layout, {
    _ResolveLayoutStrategy strategy = _ResolveLayoutStrategy.override,
  }) async {
    List<RouteLayoutParent> layouts = [];
    List<StackPath> layoutPaths = [];
    while (layout != null) {
      layouts.add(layout);
      layoutPaths.add(layout.resolvePath(this));
      layout = layout.resolveParentLayout(this);
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
  /// This method is primarily used by [CoordinatorCoreRouterDelegate.setNewRoutePath]
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

    final layout = target.resolveParentLayout(this);
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

    final layout = target.resolveParentLayout(this);
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

    final layout = target.resolveParentLayout(this);
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

    final layout = target.resolveParentLayout(this);
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

    final layout = target.resolveParentLayout(this);
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
    final dynamicPaths = activePaths.whereType<StackMutatable>().toList();

    // Try to pop from the farthest element if stack length >= 2
    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        await path.pop(result);
      }
    }
  }

  /// Attempts to pop the nearest dynamic path.
  /// The [RouteGuard] logic is handled here.
  ///
  /// Returns:
  /// - `true` if the route can pop
  /// - `false` if the route can't pop
  /// - `null` if the [RouteGuard] want manual control
  Future<bool?> tryPop([Object? result]) async {
    // Get all dynamic paths from the active layout paths
    final mutatablePaths = activePaths.whereType<StackMutatable>().toList();

    // Try to pop from the farthest element if stack length >= 2
    for (var i = mutatablePaths.length - 1; i >= 0; i--) {
      final path = mutatablePaths[i];
      if (path.stack.length >= 2) {
        return await path.pop(result);
      }
    }

    return false;
  }

  /// Marks the coordinator as needing a rebuild.
  void markNeedRebuild() => notifyListeners();

  RouteLayoutParent? resolveRouteLayoutParent(Object layoutKey);

  void defineRouteLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  );
}
