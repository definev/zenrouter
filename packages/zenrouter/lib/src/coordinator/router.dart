import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// {@template zenrouter.CoordinatorRouteParser}
/// Parses [RouteInformation] to and from [Uri].
///
/// This is used by Flutter's Router widget to handle URL changes.
///
/// ## Role in Navigation Flow
///
/// [CoordinatorRouteParser] bridges URL changes and the navigation system:
/// 1. Flutter's Router calls [parseRouteInformation] when URL changes
/// 2. The parsed URI is passed to [CoordinatorRouterDelegate.setNewRoutePath]
/// 3. The coordinator navigates to the appropriate route
///
/// This class is used internally by [MaterialApp.router] configuration.
/// {@endtemplate}
class CoordinatorRouteParser extends RouteInformationParser<Uri> {
  const CoordinatorRouteParser({required this.coordinator});

  final Coordinator<RouteUnique> coordinator;

  /// Converts [RouteInformation] to a [Uri] configuration.
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri;
  }

  /// Converts a [Uri] configuration back to [RouteInformation].
  @override
  RouteInformation? restoreRouteInformation(Uri configuration) {
    return RouteInformation(uri: configuration);
  }
}

/// {@template zenrouter.CoordinatorRouterDelegate}
/// Router delegate that connects the [Coordinator] to Flutter's Router.
///
/// Manages the navigator stack and handles system navigation events.
///
/// ## Role in Navigation Flow
///
/// [CoordinatorRouterDelegate] acts as the bridge between Flutter and ZenRouter:
/// 1. Receives route changes via [setNewRoutePath] from Flutter's Router
/// 2. Delegates navigation to the [Coordinator] for processing
/// 3. Builds the navigation widget tree via [coordinator.layoutBuilder]
/// 4. Handles system back button via [popRoute]
///
/// This delegate is automatically created by [Coordinator] and used in
/// [MaterialApp.router] configuration.
/// {@endtemplate}
class CoordinatorRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  CoordinatorRouterDelegate({required this.coordinator}) {
    coordinator.addListener(notifyListeners);
  }

  final Coordinator<RouteUnique> coordinator;

  Future<void> _commitQueue = Future<void>.value();
  RouteCancellationToken? _pendingResolution;
  int _routeGeneration = 0;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri? get currentConfiguration => coordinator.currentUri;

  String get coordinatorRestorationId =>
      '_${coordinator.rootRestorationId}_coordinator_restorable';

  @override
  Widget build(BuildContext context) {
    return CoordinatorRestorable(
      coordinator: coordinator,
      restorationId: coordinatorRestorationId,
      child: coordinator.layoutBuilder(context),
    );
  }

  /// Handles browser navigation events (back/forward buttons, URL changes).
  ///
  /// This method is called by Flutter's Router when the browser URL changes,
  /// either from user action (back/forward buttons) or programmatic navigation.
  ///
  /// **Subsequent Navigation:**
  /// For browser back/forward buttons:
  ///
  /// - **NavigationPath**: If the route exists in the stack, pops until
  ///   reaching that route. If not found, pushes it as a new route.
  ///   - Guards are consulted during popping
  ///   - If any guard blocks navigation, the URL is restored via [notifyListeners]
  ///   - Uses a while loop to handle dynamic stack changes during iteration
  ///
  /// - **IndexedStackPath**: Activates the route (switches tab) after ensuring
  ///   parent layouts are properly resolved.
  ///
  /// **URL Synchronization:**
  /// When navigation fails (guard blocks or layout resolution fails),
  /// [notifyListeners] is called to restore the browser URL to match
  /// the current app state, keeping URL and navigation state in sync.
  ///
  /// **Invariants:**
  /// - Routes cannot exist in multiple paths (each route has one path)
  /// - Route layouts are determined at creation and don't change
  /// - Path types (NavigationPath vs IndexedStackPath) are static
  @override
  Future<void> setNewRoutePath(Uri configuration) async {
    final generation = ++_routeGeneration;
    final cancellationToken = RouteCancellationToken();
    _pendingResolution?.cancel(
      'Superseded by route generation $generation ($configuration)',
    );
    _pendingResolution = cancellationToken;

    try {
      final resolved = await _resolveConfiguration(
        configuration,
        cancellationToken,
      );
      cancellationToken.throwIfCancelled();

      final operation = _commitQueue.then((_) async {
        cancellationToken.throwIfCancelled();
        if (identical(_pendingResolution, cancellationToken)) {
          _pendingResolution = null;
        }
        await _applyResolvedRoutePath(configuration, resolved);
      });
      _commitQueue = operation.then<void>((_) {}, onError: (_, _) {});
      await operation;
    } on RouteResolutionCancelled {
      // Superseded route information is expected control flow, not a Router
      // failure. The newest generation owns the next commit.
    } finally {
      if (identical(_pendingResolution, cancellationToken)) {
        _pendingResolution = null;
      }
    }
  }

  Future<void> _applyResolvedRoutePath(
    Uri configuration,
    ({RouteUnique? route, bool redirected}) resolved,
  ) async {
    final route = resolved.route;

    await coordinator.runNavigationTransaction(
      () async {
        assert(
          () {
            try {
              final _ = coordinator.coordinator;
              return true;
            } on UnimplementedError catch (err) {
              if (err.message?.contains('This coordinator is standalone') ==
                  true) {
                return route != null;
              }
              return true;
            }
          }(),
          'If you want to use coordinator as [RouterConfig], you must return route from [parseRouteFromUri]',
        );

        if (route case RouteDeepLink()) {
          await coordinator.recover(route!);
          return;
        }

        assert(
          route != null,
          'You must to provide a parse route for $configuration in [parseRouteFromUri] to use deeplink to it',
        );
        await coordinator.navigate(route!);
      },
      historyIntent: resolved.redirected
          ? NavigationHistoryIntent.replace
          : NavigationHistoryIntent.traverse,
    );
  }

  Future<({RouteUnique? route, bool redirected})> _resolveConfiguration(
    Uri configuration,
    RouteCancellationToken cancellationToken,
  ) async {
    var request = RouteRequest.navigation(
      configuration,
      cancellationToken: cancellationToken,
    );
    var redirected = false;
    final visited = <Uri>{};

    while (visited.add(request.uri)) {
      cancellationToken.throwIfCancelled();
      final resolution = await Future.any<RouteResolution<RouteUnique>>([
        coordinator.resolveRoute(request),
        cancellationToken.whenCancelled.then(
          (reason) => throw RouteResolutionCancelled(reason),
        ),
      ]);
      cancellationToken.throwIfCancelled();
      switch (resolution) {
        case MatchedRouteResolution(:final route):
          return (route: route, redirected: redirected);
        case NotFoundRouteResolution(:final route):
          return (route: route, redirected: redirected);
        case final RedirectRouteResolution resolution:
          redirected = true;
          request = resolution.createRedirectRequest();
        case ErrorRouteResolution(:final error, :final stackTrace):
          Error.throwWithStackTrace(error, stackTrace);
      }
    }

    throw StateError('Redirect loop detected while resolving $configuration');
  }

  /// Dont need to handle restored route since it handled in [CoordinatorRestorable]
  @override
  Future<void> setRestoredRoutePath(Uri configuration) async {}

  @override
  Future<bool> popRoute() async {
    final result = await coordinator.tryPop();
    return result ?? false;
  }

  @override
  void dispose() {
    _pendingResolution?.cancel('Router delegate disposed');
    _pendingResolution = null;
    coordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
