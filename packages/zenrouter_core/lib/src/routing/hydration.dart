import 'dart:convert';

Object? _freezeJsonValue(Object? value, [String path = r'$']) {
  return switch (value) {
    null || bool() || int() || String() => value,
    final double number when number.isFinite => number,
    double() => throw ArgumentError.value(
      value,
      path,
      'Hydration numbers must be finite',
    ),
    final List values => List<Object?>.unmodifiable([
      for (var index = 0; index < values.length; index++)
        _freezeJsonValue(values[index], '$path[$index]'),
    ]),
    final Map values => _freezeJsonMap(values, path),
    _ => throw ArgumentError.value(
      value,
      path,
      'Hydration data must contain only JSON-compatible values',
    ),
  };
}

Map<String, Object?> _freezeJsonMap(Map values, String path) {
  final frozen = <String, Object?>{};
  for (final entry in values.entries) {
    final key = entry.key;
    if (key is! String) {
      throw ArgumentError.value(
        key,
        path,
        'Hydration map keys must be strings',
      );
    }
    frozen[key] = _freezeJsonValue(entry.value, '$path.$key');
  }
  return Map<String, Object?>.unmodifiable(frozen);
}

/// Versioned, immutable payload transferred from route resolution to hydration.
final class RouteHydrationPayload {
  RouteHydrationPayload({
    required this.routeUri,
    this.version = currentVersion,
    Object? data,
  }) : data = _freezeJsonValue(data) {
    if (version <= 0) {
      throw ArgumentError.value(version, 'version', 'Must be positive');
    }
  }

  static const schema = 'zenrouter.hydration';
  static const currentVersion = 1;

  final int version;
  final Uri routeUri;
  final Object? data;

  Map<String, Object?> toJson() => Map<String, Object?>.unmodifiable({
    'schema': schema,
    'version': version,
    'route': routeUri.toString(),
    'data': data,
  });

  String encode() => jsonEncode(toJson());

  factory RouteHydrationPayload.fromJson(Map<String, Object?> json) {
    if (json['schema'] != schema) {
      throw const FormatException('Invalid ZenRouter hydration schema');
    }

    final version = json['version'];
    if (version is! int) {
      throw const FormatException('Hydration version must be an integer');
    }
    if (version != currentVersion) {
      throw UnsupportedHydrationVersion(
        version: version,
        supportedVersion: currentVersion,
      );
    }

    final route = json['route'];
    if (route is! String || route.isEmpty) {
      throw const FormatException('Hydration route must be a URI string');
    }

    return RouteHydrationPayload(
      routeUri: Uri.parse(route),
      version: version,
      data: json['data'],
    );
  }

  factory RouteHydrationPayload.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Hydration payload must be a JSON object');
    }
    return RouteHydrationPayload.fromJson(decoded.cast<String, Object?>());
  }
}

/// Raised when a payload uses a schema version this runtime cannot decode.
final class UnsupportedHydrationVersion implements Exception {
  const UnsupportedHydrationVersion({
    required this.version,
    required this.supportedVersion,
  });

  final int version;
  final int supportedVersion;

  @override
  String toString() =>
      'Unsupported hydration version $version; supported version is '
      '$supportedVersion';
}
