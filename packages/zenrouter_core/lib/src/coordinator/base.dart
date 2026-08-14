import 'dart:async';

import 'package:meta/meta.dart';
import 'package:zenrouter_core/src/contracts/mutatable.dart';
import 'package:zenrouter_core/src/contracts/navigatable.dart';
import 'package:zenrouter_core/src/coordinator/modular.dart';
import 'package:zenrouter_core/src/history/commit.dart';
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
import 'package:zenrouter_core/src/routing/cancellation.dart';
import 'package:zenrouter_core/src/routing/manifest.dart';

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
    if (!isRouteModule) {
      for (final path in paths) {
        path.addListener(_handlePathChanged);
      }
    }
    _publishedUri = currentUri;
    init();
    _publishedUri = currentUri;
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
    if (!isRouteModule) {
      for (final path in paths) {
        path.removeListener(_handlePathChanged);
        path.dispose();
      }
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

  /// Static route topology exposed to tooling and routing adapters.
  ///
  /// Hand-written coordinators remain parser-compatible without a manifest.
  @override
  RouteManifest<Object> get routeManifest => RouteManifest.empty;

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

  late Uri _publishedUri;
  int _transactionDepth = 0;
  bool _transactionChanged = false;
  int _navigationRevision = 0;
  final Object _transactionZoneKey = Object();
  Future<void> _transactionQueue = Future<void>.value();
  bool _transactionQueueIdle = true;

  /// The most recently published atomic navigation commit.
  NavigationCommit? get lastNavigationCommit => isRouteModule
      ? rootCoordinator.lastNavigationCommit
      : _lastNavigationCommit;
  NavigationCommit? _lastNavigationCommit;

  void _handlePathChanged() {
    if (_transactionDepth > 0) {
      _transactionChanged = true;
      return;
    }

    _publishNavigationCommit(_publishedUri);
  }

  void _publishNavigationCommit(Uri previousUri) {
    final current = currentUri;
    _publishedUri = current;
    _lastNavigationCommit = NavigationCommit(
      revision: ++_navigationRevision,
      previousUri: previousUri,
      currentUri: current,
      historyIntent: _pendingHistoryIntent,
    );
    notifyListeners();
  }

  /// Runs path mutations as one coordinator-level navigation commit.
  ///
  /// Nested transactions join the outer transaction. Path listeners may fire
  /// many times internally, but coordinator listeners observe one final state.
  /// If [operation] changes state and then throws, the changed state is still
  /// published before the original error is rethrown.
  ///
  /// [operation] must finish at the commit boundary. Do not await a route's
  /// later pop-result future inside a transaction; use `pushSilently` for
  /// commit-only work. A long-running outer transaction intentionally blocks
  /// later top-level mutations to preserve ordering.
  Future<R> runNavigationTransaction<R>(
    FutureOr<R> Function() operation, {
    NavigationHistoryIntent historyIntent = NavigationHistoryIntent.automatic,
  }) {
    if (isRouteModule) {
      return rootCoordinator.runNavigationTransaction(
        operation,
        historyIntent: historyIntent,
      );
    }

    if (Zone.current[_transactionZoneKey] == true) {
      return _runNavigationTransaction(operation, historyIntent: historyIntent);
    }

    Future<R> startTransaction() => runZoned(
      () => _runNavigationTransaction(operation, historyIntent: historyIntent),
      zoneValues: {_transactionZoneKey: true},
    );

    final transaction = _transactionQueueIdle
        ? startTransaction()
        : _transactionQueue.then<R>((_) => startTransaction());
    _transactionQueueIdle = false;
    final tail = transaction.then<void>((_) {}, onError: (_, _) {});
    _transactionQueue = tail;
    tail.whenComplete(() {
      if (identical(_transactionQueue, tail)) {
        _transactionQueueIdle = true;
      }
    });
    return transaction;
  }

  Future<R> _runNavigationTransaction<R>(
    FutureOr<R> Function() operation, {
    required NavigationHistoryIntent historyIntent,
  }) async {
    final isOutermost = _transactionDepth == 0;
    final previousIntent = _pendingHistoryIntent;
    final previousUri = _publishedUri;
    final hasHistoryScope = historyIntent != NavigationHistoryIntent.automatic;

    if (isOutermost) _transactionChanged = false;
    _transactionDepth++;

    if (hasHistoryScope) {
      _historyIntentScopes.add(historyIntent);
      recordHistoryIntent(historyIntent);
    }

    try {
      return await operation();
    } finally {
      if (isOutermost) {
        // NavigationPath.reset publishes in a microtask so it remains safe
        // during Flutter builds and in headless use. Drain those callbacks
        // before deciding whether this transaction changed state.
        await Future<void>.microtask(() {});
      }

      if (hasHistoryScope) _historyIntentScopes.removeLast();
      _transactionDepth--;

      if (isOutermost) {
        if (_transactionChanged) {
          _publishNavigationCommit(previousUri);
        } else {
          _pendingHistoryIntent = previousIntent;
        }
        _transactionChanged = false;
      }
    }
  }

  /// Records how the next committed URI should affect external history.
  ///
  void recordHistoryIntent(NavigationHistoryIntent intent) {
    if (isRouteModule) {
      rootCoordinator.recordHistoryIntent(intent);
      return;
    }

    final effectiveIntent = _historyIntentScopes.isEmpty
        ? intent
        : _historyIntentScopes.first;
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
    if (isRouteModule) {
      return rootCoordinator.withHistoryIntent(intent, operation);
    }

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
    if (isRouteModule) return rootCoordinator.consumeHistoryIntent();

    final intent = _pendingHistoryIntent;
    _pendingHistoryIntent = NavigationHistoryIntent.automatic;
    return intent;
  }

  /// Returns the current URI based on the active route.
  Uri get currentUri => isRouteModule
      ? rootCoordinator.currentUri
      : activePath.activeRoute?.identifier ?? Uri.parse('/');

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
      request.cancellationToken.throwIfCancelled();
      final route = await parseRouteFromUri(request.uri);
      request.cancellationToken.throwIfCancelled();
      if (route == null) {
        return NotFoundRouteResolution(request: request);
      }
      if (route is RouteNotFound) {
        return NotFoundRouteResolution(request: request, route: route);
      }
      return MatchedRouteResolution(request: request, route: route);
    } on RouteResolutionCancelled {
      rethrow;
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
    if (isRouteModule) {
      rootCoordinator.markNeedRebuild(historyIntent: historyIntent);
      return;
    }

    recordHistoryIntent(historyIntent);
    _handlePathChanged();
  }
}
