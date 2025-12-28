import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

part 'restoration.dart';

/// Parses [RouteInformation] to and from [Uri].
///
/// This is used by Flutter's Router widget to handle URL changes.
class CoordinatorRouteParser extends RouteInformationParser<Uri> {
  CoordinatorRouteParser({required this.coordinator});

  final Coordinator coordinator;

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

/// Router delegate that connects the [Coordinator] to Flutter's Router.
///
/// Manages the navigator stack and handles system navigation events.
class CoordinatorRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  CoordinatorRouterDelegate({required this.coordinator, this.initialRoute}) {
    coordinator.addListener(notifyListeners);
  }

  final Coordinator coordinator;
  final RouteUnique? initialRoute;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Uri? get currentConfiguration => coordinator.currentUri;

  String get coordinatorRestorationId =>
      '_${coordinator.rootRestorationId}_coordinator_restorable';

  final GlobalKey<_CoordinatorRestorableState> _coordinatorRestorableKey =
      GlobalKey();

  @override
  Widget build(BuildContext context) {
    return CoordinatorRestorable(
      key: _coordinatorRestorableKey,
      coordinator: coordinator,
      restorationId: coordinatorRestorationId,
      child: coordinator.layoutBuilder(context),
    );
  }

  /// Handles the initial route path.
  ///
  /// This method is called by Flutter's Router when the app is first loaded.
  ///
  /// If the initial route is not null, it will be recovered using [Coordinator.recover].
  /// Otherwise, the route will be parsed from the URI and recovered.
  @override
  Future<void> setInitialRoutePath(Uri configuration) async {
    if (initialRoute != null &&
        (configuration.path == '/' || configuration.path == '')) {
      setNewRoutePath(initialRoute!.toUri());
    } else {
      setNewRoutePath(configuration);
    }
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
    final route = await coordinator.parseRouteFromUri(configuration);

    if (route is RouteDeepLink &&
        route.deeplinkStrategy == DeeplinkStrategy.custom) {
      coordinator.recover(route);
    } else {
      coordinator.navigate(route);
    }
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
    coordinator.removeListener(notifyListeners);
    super.dispose();
  }
}
