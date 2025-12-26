import 'package:zenrouter/zenrouter.dart';

extension type const RouteRestorableKey(String key) {}

enum RestorationStrategy { unique, converter }

mixin RouteRestorable<T extends RouteTarget> on RouteTarget {
  static Map<String, dynamic> serialize<T extends RouteRestorable>(T route) => {
    'strategy': route.strategy.name,
    if (route.strategy == RestorationStrategy.converter) ...{
      'converter': route.converter.key,
      'value': route.converter.serialize(route),
    } else if (route.strategy == RestorationStrategy.unique &&
        route is RouteUnique) ...{
      'value': (route as RouteUnique).toUri().toString(),
    },
  };

  static T deserialize<T>(
    Map<String, dynamic> data, {
    required T Function(Uri uri)? parseRouteFromUri,
  }) {
    final rawStrategy = data['strategy'];
    if (rawStrategy == null && rawStrategy is! String) {
      return throw UnimplementedError();
    }
    final strategy = RestorationStrategy.values.asNameMap()[rawStrategy];
    assert(
      strategy != null &&
          (strategy == RestorationStrategy.converter ||
              (strategy == RestorationStrategy.unique &&
                  parseRouteFromUri != null)),
      'Invalid strategy: $strategy or parseRouteFromUri is null when parsing .unique strategy',
    );
    switch (strategy) {
      case RestorationStrategy.unique:
        final value = parseRouteFromUri!(Uri.parse(data['value']! as String));
        if (value is Future) {
          throw UnimplementedError();
        }
        return value;
      case RestorationStrategy.converter:
        final converter = RestorableConverter.buildConverter(
          data['converter']! as String,
        );
        if (converter == null) throw UnimplementedError();
        final route = converter.deserialize((data['value']! as Map).cast());
        return route as T;
      case null:
        throw UnimplementedError();
    }
  }

  RestorationStrategy get strategy => RestorationStrategy.unique;

  RestorableConverter<T> get converter => throw UnimplementedError();

  @override
  String get restorationId;
}

abstract class RestorableConverter<T extends Object> {
  const RestorableConverter();

  static final Map<String, RestoratableConverterConstructor> _converterTable =
      {};

  static void defineConverter<T extends Object>(
    String key,
    RestoratableConverterConstructor<T> constructor,
  ) => _converterTable[key] = constructor;

  static RestorableConverter? buildConverter(String key) {
    if (!_converterTable.containsKey(key)) return null;
    return _converterTable[key]!();
  }

  String get key;
  Map<String, dynamic> serialize(T route);
  T deserialize(Map<String, dynamic> data);
}

class RouteUniqueConverter<T extends RouteUnique>
    extends RestorableConverter<T> {
  const RouteUniqueConverter({
    required this.key,
    required this.parseRouteFromUri,
  });

  final T Function(Uri uri) parseRouteFromUri;

  @override
  final String key;

  @override
  Map<String, dynamic> serialize(T route) {
    return {'value': route.toUri().toString()};
  }

  @override
  T deserialize(Map<String, dynamic> data) {
    return parseRouteFromUri(Uri.parse(data['value']! as String));
  }
}
