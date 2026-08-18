import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class _NamedRoute extends RouteTarget with RouteIdentity<String> {
  _NamedRoute(this.identifier);

  @override
  final String identifier;
}

void main() {
  group('RouteIdentity', () {
    test('exposes a typed identifier used for URI and stack lookups', () {
      final route = _NamedRoute('settings');
      expect(route.identifier, 'settings');
      expect(AppRouteIdentity(route).identifier, 'settings');
    });
  });
}

class AppRouteIdentity {
  AppRouteIdentity(this.route);

  final RouteIdentity<String> route;

  String get identifier => route.identifier;
}
