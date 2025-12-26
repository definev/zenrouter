import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

mixin RestorablePath<T extends RouteTarget, S, D> on StackPath<T> {
  S serialize();

  D deserialize(S data);

  void restore(D data);
}

class NavigationPathRestorable<T extends RouteTarget>
    extends RestorableValue<List<T>> {
  NavigationPathRestorable(this.parseRouteFromUri);

  final T Function(Uri uri) parseRouteFromUri;

  @override
  List<T> createDefaultValue() => [];

  @override
  void didUpdateValue(List<T>? oldValue) => notifyListeners();

  @override
  List<T> fromPrimitives(Object? data) {
    final result = <T>[];

    final list = data as List;
    for (final route in list) {
      switch (route) {
        // RouteUnique restoration
        case String route:
          final uri = Uri.parse(route);
          result.add(parseRouteFromUri(uri));
        // RouteRestorable restoration
        case Map route:
          final rawMap = route.cast<String, dynamic>();
          final recoveredRoute = RouteRestorable.deserialize(
            rawMap,
            parseRouteFromUri: parseRouteFromUri,
          );
          result.add(recoveredRoute);
      }
    }

    return result;
  }

  @override
  Object? toPrimitives() {
    final result = <Object?>[];
    for (final route in value) {
      result.add(switch (route) {
        RouteRestorable route => RouteRestorable.serialize(route),
        RouteUnique route => route.toUri().toString(),
        _ => throw UnimplementedError(
          'Type of [${route.runtimeType}] is not supported please mixin with [RouteUnique] or [RouteRestorable]',
        ),
      });
    }

    return result;
  }
}
