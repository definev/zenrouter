import 'dart:async';

import 'package:meta/meta.dart';
import 'package:zenrouter_core/src/contracts/mutatable.dart';
import 'package:zenrouter_core/src/contracts/navigatable.dart';
import 'package:zenrouter_core/src/coordinator/modular.dart';
import 'package:zenrouter_core/src/history/intent.dart';
import 'package:zenrouter_core/src/internal/equatable.dart';
import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/src/mixin/deeplink.dart';
import 'package:zenrouter_core/src/mixin/layout.dart';
import 'package:zenrouter_core/src/mixin/redirect.dart';
import 'package:zenrouter_core/src/mixin/uri.dart';
import 'package:zenrouter_core/src/path/base.dart';
import 'package:zenrouter_core/src/path/navigatable.dart';
import 'package:zenrouter_core/src/routing/resolution.dart';

part 'layout.dart';
part 'mutatable.dart';
part 'navigatable.dart';
part 'recoverable.dart';

/// The central hub for navigation state in ZenRouter.
///
/// [CoordinatorCore] owns path state, layout-parent resolution hooks, and URI
/// parsing. Navigation *operations* live in capability mixins:
///
/// - [CoordinatorLayoutCore] — layout-parent registration / activation
/// - [CoordinatorNavigatable] — [navigate]
/// - [CoordinatorMutatable] — [push], [pop], [replace], …
/// - [CoordinatorRecoverable] — [recover] / deep links
///
/// Compose only the mixins you need (see package docs). Flutter apps typically
/// use `Coordinator` which mixes all of them in.
abstract class CoordinatorCore<T extends RouteUri> extends Equatable
    with ListenableObject
    implements RouteModule<T>, RouteResolver<T> {
  CoordinatorCore({this.initialRoutePath}) {
    for (final path in paths) {
      path.addListener(notifyListeners);
    }
    init();
  }

  /// {@macro zenrouter.coordinator.modular.coordinator}
  @override
  CoordinatorModular<T> get coordinator => throw UnimplementedError(
    'This coordinator is standalone and does not belong to any [CoordinatorModular] \n'
    'If you want to make it a part of a [CoordinatorModular] you should override `coordinator` getter or passing it through constructor',
  );

  /// The [rootCoordinator] coordinator return a top level coordinator which used as [routeConfig].
  ///
  /// If this coordinator is a part of another [CoordinatorModular], it will return the [coordinator].
  /// Otherwise, it will return itself.
  late final CoordinatorCore<T> rootCoordinator = isRouteModule
      ? coordinator
      : this;

  @override
  @mustCallSuper
  void dispose() {
    for (final path in paths) {
      path.removeListener(notifyListeners);
      path.dispose();
    }
    super.dispose();
  }

  /// Whether this coordinator is a part of a [CoordinatorModular].
  ///
  /// If it is a part of a [CoordinatorModular], it will not have a root path.
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
  /// If this coordinator is a part of a [CoordinatorModular], the root path will point to the root path of the [CoordinatorModular].
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
  /// custom layouts using [Coordinator.defineRouteLayout].
  @override
  void defineLayout() {}

  /// Defines the restorable converters for this coordinator.
  ///
  /// Override this method to register custom restorable converters using
  /// [defineRestorableConverter].
  @override
  void defineConverter() {}

  @mustCallSuper
  void init() {
    defineLayout();
    defineConverter();
  }

  /// The initial route path for this coordinator.
  ///
  /// This path is used to set the initial route when the app is launched.
  final Uri? initialRoutePath;

  NavigationHistoryIntent _pendingHistoryIntent =
      NavigationHistoryIntent.automatic;
  final List<NavigationHistoryIntent> _historyIntentScopes = [];

  /// Records how the next committed URI should affect external history.
  ///
  void recordHistoryIntent(NavigationHistoryIntent intent) {
    final effectiveIntent = _historyIntentScopes.isEmpty
        ? intent
        : _historyIntentScopes.last;
    if (effectiveIntent == NavigationHistoryIntent.automatic) return;
    _pendingHistoryIntent = effectiveIntent;
  }

  /// Runs [operation] with a history intent that inner stack mutations cannot
  /// override.
  ///
  /// Browser back/forward handling uses this to keep traversal semantics while
  /// it applies the corresponding push/pop/replace mutations locally.
  Future<R> withHistoryIntent<R>(
    NavigationHistoryIntent intent,
    FutureOr<R> Function() operation,
  ) async {
    final previousIntent = _pendingHistoryIntent;
    _historyIntentScopes.add(intent);
    recordHistoryIntent(intent);
    try {
      return await operation();
    } catch (_) {
      _pendingHistoryIntent = previousIntent;
      rethrow;
    } finally {
      _historyIntentScopes.removeLast();
    }
  }

  /// Returns and clears the history intent for the next URI report.
  ///
  /// Intended for history adapters such as Flutter's
  /// `RouteInformationProvider`.
  NavigationHistoryIntent consumeHistoryIntent() {
    final intent = _pendingHistoryIntent;
    _pendingHistoryIntent = NavigationHistoryIntent.automatic;
    return intent;
  }

  /// Returns the current URI based on the active route.
  Uri get currentUri => activePath.activeRoute?.identifier ?? Uri.parse('/');

  /// Returns the deepest active [RouteLayout] in the navigation hierarchy.
  ///
  /// This traverses through nested layouts to find the most deeply nested
  /// layout that is currently active. Returns `null` if the root layout is active.
  @protected
  RouteLayoutParent? get activeLayoutParent {
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
  List<RouteLayoutParent> get activeLayoutParentList {
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
  /// Required override - this is how deep links and web URLs become routes.
  @override
  FutureOr<T?> parseRouteFromUri(Uri uri);

  /// Resolves a request into an adapter-neutral routing outcome.
  ///
  /// Existing coordinators remain compatible through [parseRouteFromUri].
  /// Override this method when routing needs request headers, HTTP redirects,
  /// loader data, or custom status codes.
  @override
  Future<RouteResolution<T>> resolveRoute(RouteRequest request) async {
    try {
      final route = await parseRouteFromUri(request.uri);
      if (route == null) {
        return NotFoundRouteResolution(request: request);
      }
      if (route is RouteNotFound) {
        return NotFoundRouteResolution(request: request, route: route);
      }
      return MatchedRouteResolution(request: request, route: route);
    } catch (error, stackTrace) {
      return ErrorRouteResolution(
        request: request,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Registers a constructor for a layout parent.
  ///
  /// Implemented by [CoordinatorLayoutCore].
  void defineLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  );

  /// Creates a layout parent instance from registered constructor.
  ///
  /// Implemented by [CoordinatorLayoutCore].
  RouteLayoutParent? createLayoutParent(Object layoutKey);

  /// Triggers a rebuild of the coordinator.
  void markNeedRebuild({
    NavigationHistoryIntent historyIntent = NavigationHistoryIntent.automatic,
  }) {
    recordHistoryIntent(historyIntent);
    notifyListeners();
  }
}
