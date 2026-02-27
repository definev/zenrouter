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
    if (defaultUri?.pathSegments.isEmpty == true && initialUri != null) {
      return initialUri;
    }

    if (defaultUri != null && defaultUri.hasEmptyPath) {
      return defaultUri.replace(path: '/');
    }

    return defaultUri ?? Uri.parse('/');
  }
}
