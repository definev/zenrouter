import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

class CoordinatorRouteInformationProvider
    extends PlatformRouteInformationProvider {
  CoordinatorRouteInformationProvider({required Coordinator coordinator})
    : _coordinator = coordinator,
      super(
        initialRouteInformation: RouteInformation(
          uri: resolveInitialUri(
            WidgetsBinding.instance.platformDispatcher.defaultRouteName,
            coordinator.initialRoutePath,
          ),
        ),
      );

  final Coordinator _coordinator;

  Coordinator get coordinator => _coordinator;

  @visibleForTesting
  static Uri resolveInitialUri(String? platformRouteName, Uri? initialUri) {
    final defaultUri = Uri.tryParse(platformRouteName ?? '');

    // If the platform route name can't be parsed, fall back to the provided
    // initialUri when available; otherwise, use the root route.
    if (defaultUri == null) {
      return initialUri ?? Uri.parse('/');
    }

    if (defaultUri.pathSegments.isEmpty && initialUri != null) {
      return initialUri;
    }

    if (defaultUri.hasEmptyPath) {
      return defaultUri.replace(path: '/');
    }

    return defaultUri;
  }
}
