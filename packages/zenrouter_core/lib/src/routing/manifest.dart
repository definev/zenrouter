import 'dart:collection';
import 'dart:convert';

import 'package:zenrouter_core/src/mixin/deeplink.dart';

/// The navigation behavior of a layout declared in a [RouteManifest].
enum RouteManifestLayoutKind { stack, indexed }

/// The kind of a segment in a declarative route pattern.
enum RoutePatternSegmentKind { literal, parameter, rest }

/// Converts typed in-memory route IDs to and from their stable wire names.
///
/// Matching and reverse routing never require a codec. A manifest only needs
/// one when it crosses the JSON serialization seam.
final class RouteIdCodec<I extends Object> {
  const RouteIdCodec({required this.encode, required this.decode});

  final String Function(I id) encode;
  final I Function(String wireId) decode;

  static String _identity(String value) => value;

  /// Codec used by generated manifests and other string-ID graphs.
  static const string = RouteIdCodec<String>(
    encode: _identity,
    decode: _identity,
  );

  /// Creates a name-based codec for an enum ID type.
  static RouteIdCodec<E> enumValues<E extends Enum>(Iterable<E> values) {
    final byName = {for (final value in values) value.name: value};
    return RouteIdCodec<E>(
      encode: (id) => id.name,
      decode: (wireId) {
        final id = byName[wireId];
        if (id == null) {
          throw FormatException('Unknown route manifest ID: $wireId');
        }
        return id;
      },
    );
  }
}

/// One immutable segment in a [RoutePattern].
final class RoutePatternSegment {
  const RoutePatternSegment._(this.kind, this.value);

  const RoutePatternSegment.literal(String value)
    : this._(RoutePatternSegmentKind.literal, value);

  const RoutePatternSegment.parameter(String name)
    : this._(RoutePatternSegmentKind.parameter, name);

  const RoutePatternSegment.rest(String name)
    : this._(RoutePatternSegmentKind.rest, name);

  final RoutePatternSegmentKind kind;

  /// Literal value or parameter name, depending on [kind].
  final String value;

  bool get isParameter => kind != RoutePatternSegmentKind.literal;
  bool get isRest => kind == RoutePatternSegmentKind.rest;

  @override
  String toString() => switch (kind) {
    RoutePatternSegmentKind.literal => value,
    RoutePatternSegmentKind.parameter => ':$value',
    RoutePatternSegmentKind.rest => '...:$value',
  };
}

/// A parsed, validated URI path pattern.
///
/// Patterns use `:name` for one segment and `...:name` for zero or more
/// segments. A pattern never contains a query or fragment.
final class RoutePattern {
  factory RoutePattern(String source) {
    if (!source.startsWith('/')) {
      throw ArgumentError.value(source, 'source', 'must start with /');
    }
    if (source.contains('?') || source.contains('#')) {
      throw ArgumentError.value(
        source,
        'source',
        'must not contain a query or fragment',
      );
    }
    if (source == '/') return RoutePattern._('/', const []);
    if (source.endsWith('/') || source.contains('//')) {
      throw ArgumentError.value(
        source,
        'source',
        'must not contain empty path segments',
      );
    }

    final parameterNames = <String>{};
    var restCount = 0;
    final segments = <RoutePatternSegment>[];
    for (final segment in source.substring(1).split('/')) {
      final RoutePatternSegment parsed;
      if (segment.startsWith('...:')) {
        final name = segment.substring(4);
        _validateParameterName(source, name);
        restCount += 1;
        if (restCount > 1) {
          throw ArgumentError.value(
            source,
            'source',
            'may contain at most one rest parameter',
          );
        }
        parsed = RoutePatternSegment.rest(name);
      } else if (segment.startsWith(':')) {
        final name = segment.substring(1);
        _validateParameterName(source, name);
        parsed = RoutePatternSegment.parameter(name);
      } else {
        if (segment.isEmpty) {
          throw ArgumentError.value(
            source,
            'source',
            'must not contain empty path segments',
          );
        }
        parsed = RoutePatternSegment.literal(segment);
      }

      if (parsed.isParameter && !parameterNames.add(parsed.value)) {
        throw ArgumentError.value(
          source,
          'source',
          'contains duplicate parameter ${parsed.value}',
        );
      }
      segments.add(parsed);
    }

    return RoutePattern._(source, List.unmodifiable(segments));
  }

  const RoutePattern._(this.source, this.segments);

  static final _parameterName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  static void _validateParameterName(String source, String name) {
    if (!_parameterName.hasMatch(name)) {
      throw ArgumentError.value(
        source,
        'source',
        'contains invalid parameter name "$name"',
      );
    }
  }

  final String source;
  final List<RoutePatternSegment> segments;

  int get staticSegmentCount => segments
      .where((segment) => segment.kind == RoutePatternSegmentKind.literal)
      .length;
  int get dynamicSegmentCount => segments
      .where((segment) => segment.kind == RoutePatternSegmentKind.parameter)
      .length;
  bool get hasRestParameter => segments.any((segment) => segment.isRest);
  int get minimumSegmentCount => segments.length - (hasRestParameter ? 1 : 0);

  _RoutePatternMatch? _match(List<String> pathSegments) {
    final restIndex = segments.indexWhere((segment) => segment.isRest);
    if (restIndex == -1) {
      if (pathSegments.length != segments.length) return null;
    } else if (pathSegments.length < minimumSegmentCount) {
      return null;
    }

    final parameters = <String, String>{};
    final restParameters = <String, List<String>>{};
    final prefixLength = restIndex == -1 ? segments.length : restIndex;

    for (var index = 0; index < prefixLength; index += 1) {
      if (!_matchSegment(segments[index], pathSegments[index], parameters)) {
        return null;
      }
    }

    if (restIndex == -1) {
      return _RoutePatternMatch(parameters, restParameters);
    }

    final suffixLength = segments.length - restIndex - 1;
    for (var offset = 0; offset < suffixLength; offset += 1) {
      final patternIndex = segments.length - suffixLength + offset;
      final pathIndex = pathSegments.length - suffixLength + offset;
      if (!_matchSegment(
        segments[patternIndex],
        pathSegments[pathIndex],
        parameters,
      )) {
        return null;
      }
    }

    restParameters[segments[restIndex].value] = List.unmodifiable(
      pathSegments.sublist(restIndex, pathSegments.length - suffixLength),
    );
    return _RoutePatternMatch(parameters, restParameters);
  }

  bool _matchSegment(
    RoutePatternSegment pattern,
    String actual,
    Map<String, String> parameters,
  ) {
    switch (pattern.kind) {
      case RoutePatternSegmentKind.literal:
        return pattern.value == actual;
      case RoutePatternSegmentKind.parameter:
        parameters[pattern.value] = actual;
        return true;
      case RoutePatternSegmentKind.rest:
        throw StateError('Rest segments are matched separately');
    }
  }

  List<String> buildSegments({
    Map<String, String> pathParameters = const {},
    Map<String, List<String>> restParameters = const {},
  }) {
    final expectedPath = <String>{};
    final expectedRest = <String>{};
    final result = <String>[];

    for (final segment in segments) {
      switch (segment.kind) {
        case RoutePatternSegmentKind.literal:
          result.add(segment.value);
        case RoutePatternSegmentKind.parameter:
          expectedPath.add(segment.value);
          final value = pathParameters[segment.value];
          if (value == null || value.isEmpty) {
            throw ArgumentError(
              'Missing non-empty path parameter ${segment.value} for $source',
            );
          }
          result.add(value);
        case RoutePatternSegmentKind.rest:
          expectedRest.add(segment.value);
          final values = restParameters[segment.value];
          if (values == null) {
            throw ArgumentError(
              'Missing rest parameter ${segment.value} for $source',
            );
          }
          if (values.any((value) => value.isEmpty)) {
            throw ArgumentError(
              'Rest parameter ${segment.value} contains an empty segment',
            );
          }
          result.addAll(values);
      }
    }

    final unexpectedPath = pathParameters.keys.toSet()..removeAll(expectedPath);
    final unexpectedRest = restParameters.keys.toSet()..removeAll(expectedRest);
    if (unexpectedPath.isNotEmpty || unexpectedRest.isNotEmpty) {
      throw ArgumentError(
        'Unexpected parameters for $source: '
        '${[...unexpectedPath, ...unexpectedRest].join(', ')}',
      );
    }
    return result;
  }

  String get canonicalShape => segments
      .map(
        (segment) => switch (segment.kind) {
          RoutePatternSegmentKind.literal => '=${segment.value}',
          RoutePatternSegmentKind.parameter => ':',
          RoutePatternSegmentKind.rest => '...',
        },
      )
      .join('/');

  @override
  String toString() => source;
}

sealed class RouteManifestNode<I extends Object> {
  RouteManifestNode({required this.id, required String path, this.parentId})
    : pattern = RoutePattern(path) {
    if (id is String && (id as String).trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (parentId case final String parentId when parentId.trim().isEmpty) {
      throw ArgumentError.value(parentId, 'parentId', 'must not be empty');
    }
  }

  final I id;
  final RoutePattern pattern;
  final I? parentId;

  String get path => pattern.source;

  Map<String, Object?> toJson(RouteIdCodec<I> idCodec);
}

/// Static topology and routing metadata for one routable destination.
final class RouteManifestRoute<I extends Object> extends RouteManifestNode<I> {
  RouteManifestRoute({
    required super.id,
    required super.path,
    super.parentId,
    Iterable<String> queryParameters = const [],
    this.hasGuard = false,
    this.hasRedirect = false,
    this.isDeferred = false,
    this.deepLinkStrategy,
  }) : queryParameters = List.unmodifiable(queryParameters) {
    final duplicates = _duplicates(this.queryParameters);
    if (duplicates.isNotEmpty) {
      throw ArgumentError(
        'Duplicate query parameters: ${duplicates.join(', ')}',
      );
    }
  }

  final List<String> queryParameters;
  final bool hasGuard;
  final bool hasRedirect;
  final bool isDeferred;
  final DeeplinkStrategy? deepLinkStrategy;

  @override
  Map<String, Object?> toJson(RouteIdCodec<I> idCodec) => {
    'id': _encodeId(idCodec, id),
    'path': path,
    if (parentId != null) 'parentId': _encodeId(idCodec, parentId as I),
    if (queryParameters.isNotEmpty) 'queryParameters': queryParameters,
    if (hasGuard) 'hasGuard': true,
    if (hasRedirect) 'hasRedirect': true,
    if (isDeferred) 'isDeferred': true,
    if (deepLinkStrategy != null) 'deepLinkStrategy': deepLinkStrategy!.name,
  };
}

/// Static topology for one layout destination.
final class RouteManifestLayout<I extends Object> extends RouteManifestNode<I> {
  RouteManifestLayout({
    required super.id,
    required super.path,
    super.parentId,
    required this.kind,
    Iterable<I> indexedChildIds = const [],
  }) : indexedChildIds = List.unmodifiable(indexedChildIds) {
    if (kind == RouteManifestLayoutKind.stack &&
        this.indexedChildIds.isNotEmpty) {
      throw ArgumentError(
        'Stack layout $id cannot declare indexed child routes',
      );
    }
    final duplicates = _duplicates(this.indexedChildIds);
    if (duplicates.isNotEmpty) {
      throw ArgumentError(
        'Layout $id contains duplicate indexed children: '
        '${duplicates.join(', ')}',
      );
    }
  }

  final RouteManifestLayoutKind kind;
  final List<I> indexedChildIds;

  @override
  Map<String, Object?> toJson(RouteIdCodec<I> idCodec) => {
    'id': _encodeId(idCodec, id),
    'path': path,
    if (parentId != null) 'parentId': _encodeId(idCodec, parentId as I),
    'kind': kind.name,
    if (indexedChildIds.isNotEmpty)
      'indexedChildIds': indexedChildIds
          .map((id) => _encodeId(idCodec, id))
          .toList(growable: false),
  };
}

/// Immutable declarative graph of every route and layout known to a router.
///
/// The manifest owns matching precedence, graph validation and reverse routing.
/// Presentation adapters bind route IDs to concrete route/page constructors.
final class RouteManifest<I extends Object> {
  factory RouteManifest({
    required String name,
    Iterable<RouteManifestRoute<I>> routes = const [],
    Iterable<RouteManifestLayout<I>> layouts = const [],
    RouteIdCodec<I>? idCodec,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }

    final routeList = List<RouteManifestRoute<I>>.unmodifiable(routes);
    final layoutList = List<RouteManifestLayout<I>>.unmodifiable(layouts);
    final nodes = <I, RouteManifestNode<I>>{};
    for (final node in <RouteManifestNode<I>>[...layoutList, ...routeList]) {
      final previous = nodes[node.id];
      if (previous != null) {
        throw RouteManifestValidationException(
          'Duplicate route manifest ID ${node.id}',
          nodeIds: [node.id],
        );
      }
      nodes[node.id] = node;
    }

    _validateRelationships(nodes, layoutList);
    _validateRouteConflicts(routeList);

    final matchOrder = List<RouteManifestRoute<I>>.of(routeList)
      ..sort(_compareRouteSpecificity);
    return RouteManifest._(
      name,
      routeList,
      layoutList,
      UnmodifiableMapView(nodes),
      List.unmodifiable(matchOrder),
      _resolveIdCodec(idCodec),
    );
  }

  const RouteManifest._(
    this.name,
    this.routes,
    this.layouts,
    this.nodes,
    this._matchOrder,
    this._idCodec,
  );

  factory RouteManifest.compose({
    required String name,
    required Iterable<RouteManifest<I>> manifests,
    RouteIdCodec<I>? idCodec,
  }) {
    final manifestList = manifests.toList(growable: false);
    RouteIdCodec<I>? inheritedIdCodec;
    for (final manifest in manifestList) {
      inheritedIdCodec ??= manifest._idCodec;
    }
    return RouteManifest<I>(
      name: name,
      routes: [for (final manifest in manifestList) ...manifest.routes],
      layouts: [for (final manifest in manifestList) ...manifest.layouts],
      idCodec: idCodec ?? inheritedIdCodec,
    );
  }

  factory RouteManifest.fromJson(
    Map<String, Object?> json, {
    RouteIdCodec<I>? idCodec,
  }) {
    final resolvedIdCodec = _resolveIdCodec(idCodec);
    if (resolvedIdCodec == null) {
      throw StateError(
        'A RouteIdCodec<$I> is required to decode a typed route manifest',
      );
    }
    final schema = _requiredString(json, 'schema');
    if (schema != schemaName) {
      throw FormatException('Unknown route manifest schema: $schema');
    }
    final version = json['version'];
    if (version is! int) {
      throw const FormatException('Route manifest version must be an integer');
    }
    if (version != currentVersion) {
      throw UnsupportedRouteManifestVersion(version);
    }

    final routesJson = _objectList(json, 'routes');
    final layoutsJson = _objectList(json, 'layouts');
    return RouteManifest<I>(
      name: _requiredString(json, 'name'),
      routes: routesJson.map(
        (route) => _routeFromJson<I>(route, resolvedIdCodec),
      ),
      layouts: layoutsJson.map(
        (layout) => _layoutFromJson<I>(layout, resolvedIdCodec),
      ),
      idCodec: resolvedIdCodec,
    );
  }

  factory RouteManifest.decode(String source, {RouteIdCodec<I>? idCodec}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Route manifest must be a JSON object');
    }
    return RouteManifest<I>.fromJson(
      decoded.cast<String, Object?>(),
      idCodec: idCodec,
    );
  }

  static const schemaName = 'zenrouter.route-manifest';
  static const currentVersion = 1;

  /// Shared manifest for hand-written route modules without static topology.
  static final RouteManifest<Object> empty = RouteManifest<Object>(
    name: 'empty',
  );

  final String name;
  final List<RouteManifestRoute<I>> routes;
  final List<RouteManifestLayout<I>> layouts;
  final Map<I, RouteManifestNode<I>> nodes;
  final List<RouteManifestRoute<I>> _matchOrder;
  final RouteIdCodec<I>? _idCodec;

  RouteManifestNode<I>? operator [](I id) => nodes[id];

  /// Matches [uri] using deterministic route specificity.
  RouteManifestMatch<I>? match(Uri uri) {
    for (final route in _matchOrder) {
      final match = route.pattern._match(uri.pathSegments);
      if (match != null) {
        return RouteManifestMatch<I>._(
          uri,
          route,
          UnmodifiableMapView(match.parameters),
          UnmodifiableMapView(match.restParameters),
        );
      }
    }
    return null;
  }

  /// Builds a URI without requiring a presentation route instance.
  Uri location(
    I routeId, {
    Map<String, String> pathParameters = const {},
    Map<String, List<String>> restParameters = const {},
    Map<String, String> queryParameters = const {},
    String? fragment,
  }) {
    final node = nodes[routeId];
    if (node is! RouteManifestRoute<I>) {
      throw ArgumentError.value(routeId, 'routeId', 'is not a route ID');
    }
    final segments = node.pattern.buildSegments(
      pathParameters: pathParameters,
      restParameters: restParameters,
    );
    if (segments.isEmpty) {
      return Uri(
        path: '/',
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
        fragment: fragment,
      );
    }
    return Uri(
      pathSegments: ['', ...segments],
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      fragment: fragment,
    );
  }

  Map<String, Object?> toJson({RouteIdCodec<I>? idCodec}) {
    final resolvedIdCodec = idCodec ?? _idCodec;
    if (resolvedIdCodec == null) {
      throw StateError(
        'A RouteIdCodec<$I> is required to encode a typed route manifest',
      );
    }
    _validateEncodedIds(nodes.keys, resolvedIdCodec);
    return {
      'schema': schemaName,
      'version': currentVersion,
      'name': name,
      'routes': routes
          .map((route) => route.toJson(resolvedIdCodec))
          .toList(growable: false),
      'layouts': layouts
          .map((layout) => layout.toJson(resolvedIdCodec))
          .toList(growable: false),
    };
  }

  String encode({RouteIdCodec<I>? idCodec}) =>
      jsonEncode(toJson(idCodec: idCodec));
}

/// Result of matching a URI against a [RouteManifest].
final class RouteManifestMatch<I extends Object> {
  const RouteManifestMatch._(
    this.uri,
    this.route,
    this.pathParameters,
    this.restParameters,
  );

  final Uri uri;
  final RouteManifestRoute<I> route;
  final Map<String, String> pathParameters;
  final Map<String, List<String>> restParameters;

  /// Typed route ID exposed directly for ergonomic object-pattern matching.
  I get id => route.id;
}

final class RouteManifestValidationException<I extends Object>
    implements Exception {
  RouteManifestValidationException(
    this.message, {
    Iterable<I> nodeIds = const [],
  }) : nodeIds = List.unmodifiable(nodeIds);

  final String message;
  final List<I> nodeIds;

  @override
  String toString() => 'RouteManifestValidationException: $message';
}

final class UnsupportedRouteManifestVersion implements Exception {
  const UnsupportedRouteManifestVersion(this.version);

  final int version;

  @override
  String toString() => 'Unsupported route manifest version: $version';
}

final class _RoutePatternMatch {
  const _RoutePatternMatch(this.parameters, this.restParameters);

  final Map<String, String> parameters;
  final Map<String, List<String>> restParameters;
}

void _validateRelationships<I extends Object>(
  Map<I, RouteManifestNode<I>> nodes,
  List<RouteManifestLayout<I>> layouts,
) {
  for (final node in nodes.values) {
    final parentId = node.parentId;
    if (parentId == null) continue;
    if (nodes[parentId] is! RouteManifestLayout<I>) {
      throw RouteManifestValidationException(
        'Parent $parentId of ${node.id} is not a known layout',
        nodeIds: [node.id, parentId],
      );
    }
  }

  for (final layout in layouts) {
    for (final childId in layout.indexedChildIds) {
      if (!nodes.containsKey(childId)) {
        throw RouteManifestValidationException(
          'Indexed child $childId of ${layout.id} is unknown',
          nodeIds: [layout.id, childId],
        );
      }
    }
  }

  for (final layout in layouts) {
    final visited = <I>{layout.id};
    RouteManifestNode<I> current = layout;
    while (current.parentId != null) {
      final parentId = current.parentId!;
      if (!visited.add(parentId)) {
        throw RouteManifestValidationException(
          'Layout parent cycle contains ${visited.join(' -> ')}',
          nodeIds: visited,
        );
      }
      current = nodes[parentId]!;
    }
  }
}

void _validateRouteConflicts<I extends Object>(
  List<RouteManifestRoute<I>> routes,
) {
  for (var leftIndex = 0; leftIndex < routes.length; leftIndex += 1) {
    final left = routes[leftIndex];
    for (
      var rightIndex = leftIndex + 1;
      rightIndex < routes.length;
      rightIndex += 1
    ) {
      final right = routes[rightIndex];
      if (_comparePatternSpecificity(left.pattern, right.pattern) == 0 &&
          _patternsOverlap(left.pattern, right.pattern)) {
        throw RouteManifestValidationException(
          'Ambiguous route patterns ${left.path} and ${right.path}',
          nodeIds: [left.id, right.id],
        );
      }
    }
  }
}

int _compareRouteSpecificity<I extends Object>(
  RouteManifestRoute<I> left,
  RouteManifestRoute<I> right,
) {
  final leftPattern = left.pattern;
  final rightPattern = right.pattern;
  final specificity = _comparePatternSpecificity(leftPattern, rightPattern);
  if (specificity != 0) return specificity;
  return left.path.compareTo(right.path);
}

int _comparePatternSpecificity(
  RoutePattern leftPattern,
  RoutePattern rightPattern,
) {
  if (leftPattern.hasRestParameter != rightPattern.hasRestParameter) {
    return leftPattern.hasRestParameter ? 1 : -1;
  }
  if (leftPattern.staticSegmentCount != rightPattern.staticSegmentCount) {
    return rightPattern.staticSegmentCount - leftPattern.staticSegmentCount;
  }
  if (leftPattern.segments.length != rightPattern.segments.length) {
    return rightPattern.segments.length - leftPattern.segments.length;
  }
  if (leftPattern.dynamicSegmentCount != rightPattern.dynamicSegmentCount) {
    return leftPattern.dynamicSegmentCount - rightPattern.dynamicSegmentCount;
  }
  return 0;
}

bool _patternsOverlap(RoutePattern left, RoutePattern right) {
  if (!left.hasRestParameter && !right.hasRestParameter) {
    if (left.segments.length != right.segments.length) return false;
    return _patternsOverlapAtLength(left, right, left.segments.length);
  }

  if (!left.hasRestParameter) {
    return _patternsOverlapAtLength(left, right, left.segments.length);
  }
  if (!right.hasRestParameter) {
    return _patternsOverlapAtLength(left, right, right.segments.length);
  }

  final minimum = left.minimumSegmentCount > right.minimumSegmentCount
      ? left.minimumSegmentCount
      : right.minimumSegmentCount;
  final upperBound = left.minimumSegmentCount + right.minimumSegmentCount + 1;
  for (var length = minimum; length <= upperBound; length += 1) {
    if (_patternsOverlapAtLength(left, right, length)) return true;
  }
  return false;
}

bool _patternsOverlapAtLength(
  RoutePattern left,
  RoutePattern right,
  int length,
) {
  final leftConstraints = _literalConstraints(left, length);
  final rightConstraints = _literalConstraints(right, length);
  if (leftConstraints == null || rightConstraints == null) return false;
  for (final entry in leftConstraints.entries) {
    final other = rightConstraints[entry.key];
    if (other != null && other != entry.value) return false;
  }
  return true;
}

Map<int, String>? _literalConstraints(RoutePattern pattern, int length) {
  if (length < pattern.minimumSegmentCount) return null;
  if (!pattern.hasRestParameter && length != pattern.segments.length) {
    return null;
  }

  final constraints = <int, String>{};
  final restIndex = pattern.segments.indexWhere((segment) => segment.isRest);
  final prefixLength = restIndex == -1 ? pattern.segments.length : restIndex;
  for (var index = 0; index < prefixLength; index += 1) {
    final segment = pattern.segments[index];
    if (segment.kind == RoutePatternSegmentKind.literal) {
      constraints[index] = segment.value;
    }
  }
  if (restIndex != -1) {
    final suffixLength = pattern.segments.length - restIndex - 1;
    for (var offset = 0; offset < suffixLength; offset += 1) {
      final segment = pattern.segments[restIndex + 1 + offset];
      if (segment.kind == RoutePatternSegmentKind.literal) {
        constraints[length - suffixLength + offset] = segment.value;
      }
    }
  }
  return constraints;
}

Set<I> _duplicates<I extends Object>(Iterable<I> values) {
  final seen = <I>{};
  final duplicates = <I>{};
  for (final value in values) {
    if (!seen.add(value)) duplicates.add(value);
  }
  return duplicates;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Route manifest $key must be a non-empty string');
  }
  return value;
}

List<Map<String, Object?>> _objectList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('Route manifest $key must be a list');
  }
  return value
      .map((entry) {
        if (entry is! Map) {
          throw FormatException('Route manifest $key entries must be objects');
        }
        return entry.cast<String, Object?>();
      })
      .toList(growable: false);
}

List<String> _stringList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return const [];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('Route manifest $key must be a string list');
  }
  return value.cast<String>();
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String || value.isEmpty) {
    throw FormatException('Route manifest $key must be a non-empty string');
  }
  return value;
}

bool _optionalBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return false;
  if (value is! bool) {
    throw FormatException('Route manifest $key must be a boolean');
  }
  return value;
}

RouteManifestRoute<I> _routeFromJson<I extends Object>(
  Map<String, Object?> json,
  RouteIdCodec<I> idCodec,
) {
  final strategyName = _optionalString(json, 'deepLinkStrategy');
  DeeplinkStrategy? strategy;
  if (strategyName != null) {
    try {
      strategy = DeeplinkStrategy.values.byName(strategyName);
    } on ArgumentError {
      throw FormatException('Unknown deep-link strategy: $strategyName');
    }
  }
  return RouteManifestRoute<I>(
    id: idCodec.decode(_requiredString(json, 'id')),
    path: _requiredString(json, 'path'),
    parentId: switch (_optionalString(json, 'parentId')) {
      final parentId? => idCodec.decode(parentId),
      null => null,
    },
    queryParameters: _stringList(json, 'queryParameters'),
    hasGuard: _optionalBool(json, 'hasGuard'),
    hasRedirect: _optionalBool(json, 'hasRedirect'),
    isDeferred: _optionalBool(json, 'isDeferred'),
    deepLinkStrategy: strategy,
  );
}

RouteManifestLayout<I> _layoutFromJson<I extends Object>(
  Map<String, Object?> json,
  RouteIdCodec<I> idCodec,
) {
  final kindName = _requiredString(json, 'kind');
  RouteManifestLayoutKind kind;
  try {
    kind = RouteManifestLayoutKind.values.byName(kindName);
  } on ArgumentError {
    throw FormatException('Unknown route manifest layout kind: $kindName');
  }
  return RouteManifestLayout<I>(
    id: idCodec.decode(_requiredString(json, 'id')),
    path: _requiredString(json, 'path'),
    parentId: switch (_optionalString(json, 'parentId')) {
      final parentId? => idCodec.decode(parentId),
      null => null,
    },
    kind: kind,
    indexedChildIds: _stringList(json, 'indexedChildIds').map(idCodec.decode),
  );
}

RouteIdCodec<I>? _resolveIdCodec<I extends Object>(RouteIdCodec<I>? idCodec) {
  if (idCodec != null) return idCodec;
  if (I == String) return RouteIdCodec.string as RouteIdCodec<I>;
  return null;
}

String _encodeId<I extends Object>(RouteIdCodec<I> idCodec, I id) {
  final wireId = idCodec.encode(id);
  if (wireId.trim().isEmpty) {
    throw StateError('Route ID codec encoded $id as an empty wire ID');
  }
  return wireId;
}

void _validateEncodedIds<I extends Object>(
  Iterable<I> ids,
  RouteIdCodec<I> idCodec,
) {
  final encodedIds = <String, I>{};
  for (final id in ids) {
    final wireId = _encodeId(idCodec, id);
    final previous = encodedIds[wireId];
    if (previous != null) {
      throw StateError(
        'Route ID codec maps both $previous and $id to "$wireId"',
      );
    }
    encodedIds[wireId] = id;
  }
}
