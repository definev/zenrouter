import 'dart:collection';
import 'dart:convert';

/// The navigation behavior of a layout declared in a [RouteManifest].
enum RouteManifestLayoutKind { stack, indexed, branched }

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

/// Static topology for one routable destination.
final class RouteManifestRoute<I extends Object> extends RouteManifestNode<I> {
  RouteManifestRoute({required super.id, required super.path, super.parentId});

  @override
  Map<String, Object?> toJson(RouteIdCodec<I> idCodec) => {
    'id': _encodeId(idCodec, id),
    'path': path,
    if (parentId != null) 'parentId': _encodeId(idCodec, parentId as I),
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
    Iterable<I> branchChildIds = const [],
  }) : indexedChildIds = List.unmodifiable(indexedChildIds),
       branchChildIds = List.unmodifiable(branchChildIds) {
    if (kind != RouteManifestLayoutKind.indexed &&
        this.indexedChildIds.isNotEmpty) {
      throw ArgumentError(
        '${kind.name} layout $id cannot declare indexed child routes',
      );
    }
    if (kind != RouteManifestLayoutKind.branched &&
        this.branchChildIds.isNotEmpty) {
      throw ArgumentError(
        '${kind.name} layout $id cannot declare branch child layouts',
      );
    }
    if (kind == RouteManifestLayoutKind.branched &&
        this.branchChildIds.isEmpty) {
      throw ArgumentError(
        'Branched layout $id must declare at least one branch child layout',
      );
    }
    final duplicateIndexedChildren = _duplicates(this.indexedChildIds);
    if (duplicateIndexedChildren.isNotEmpty) {
      throw ArgumentError(
        'Layout $id contains duplicate indexed children: '
        '${duplicateIndexedChildren.join(', ')}',
      );
    }
    final duplicateBranchChildren = _duplicates(this.branchChildIds);
    if (duplicateBranchChildren.isNotEmpty) {
      throw ArgumentError(
        'Layout $id contains duplicate branch children: '
        '${duplicateBranchChildren.join(', ')}',
      );
    }
  }

  final RouteManifestLayoutKind kind;
  final List<I> indexedChildIds;
  final List<I> branchChildIds;

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
    if (branchChildIds.isNotEmpty)
      'branchChildIds': branchChildIds
          .map((id) => _encodeId(idCodec, id))
          .toList(growable: false),
  };
}

/// An immutable contribution to a larger [RouteManifest].
///
/// A fragment validates its own shape and ID uniqueness, but deliberately
/// leaves parent, fixed-child, and route-conflict validation to the composed
/// manifest. This allows one route module to reference a layout declared by
/// another module without weakening validation of the final application graph.
final class RouteManifestFragment<I extends Object> {
  factory RouteManifestFragment({
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
    final nodes = _indexManifestNodes(routeList, layoutList);
    return RouteManifestFragment._(
      name,
      routeList,
      layoutList,
      UnmodifiableMapView(nodes),
      _resolveIdCodec(idCodec),
    );
  }

  RouteManifestFragment._(
    this.name,
    this.routes,
    this.layouts,
    this.nodes,
    this.idCodec,
  ) : _encodeObjectId = idCodec == null ? null : _eraseIdEncoder(idCodec),
      _decodeObjectId = idCodec == null ? null : _eraseIdDecoder(idCodec);

  final String name;
  final List<RouteManifestRoute<I>> routes;
  final List<RouteManifestLayout<I>> layouts;
  final Map<I, RouteManifestNode<I>> nodes;

  /// Codec for this fragment's local IDs when it crosses the JSON seam.
  final RouteIdCodec<I>? idCodec;
  final String Function(Object id)? _encodeObjectId;
  final Object Function(String wireId)? _decodeObjectId;

  bool get isEmpty => nodes.isEmpty;
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
    final fragment = RouteManifestFragment<I>(
      name: name,
      routes: routes,
      layouts: layouts,
      idCodec: idCodec,
    );
    final routeList = fragment.routes;
    final layoutList = fragment.layouts;
    final nodes = fragment.nodes;

    _validateRelationships(nodes, layoutList);
    _validateRouteConflicts(routeList);

    final matchOrder = List<RouteManifestRoute<I>>.of(routeList)
      ..sort(_compareRouteSpecificity);
    return RouteManifest._(
      name,
      routeList,
      layoutList,
      nodes,
      List.unmodifiable(matchOrder),
      fragment.idCodec,
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
  }) => RouteManifest<I>.fromFragments(
    name: name,
    fragments: manifests.map((manifest) => manifest.fragment),
    idCodec: idCodec,
  );

  /// Builds and validates one application graph from independently declared
  /// fragments.
  ///
  /// Empty fragments are ignored. When every non-empty fragment has a codec,
  /// the resulting manifest receives a composite codec. Non-String graphs
  /// scope wire IDs by fragment name from the first fragment onward;
  /// homogeneous String graphs preserve their existing wire IDs. Callers can
  /// provide [idCodec] to use an application-specific wire format instead.
  factory RouteManifest.fromFragments({
    required String name,
    required Iterable<RouteManifestFragment<I>> fragments,
    RouteIdCodec<I>? idCodec,
  }) {
    final fragmentList = fragments
        .where((fragment) => !fragment.isEmpty)
        .toList(growable: false);
    return RouteManifest<I>(
      name: name,
      routes: [
        for (final fragment in fragmentList)
          for (final route in fragment.routes) _copyManifestRoute<I>(route),
      ],
      layouts: [
        for (final fragment in fragmentList)
          for (final layout in fragment.layouts) _copyManifestLayout<I>(layout),
      ],
      idCodec: idCodec ?? _composeFragmentCodecs(fragmentList),
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

  /// Codec used by this graph at the JSON serialization seam, when available.
  RouteIdCodec<I>? get idCodec => _idCodec;

  /// A contribution view that can be composed into a larger application graph.
  RouteManifestFragment<I> get fragment =>
      RouteManifestFragment._(name, routes, layouts, nodes, _idCodec);

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

Map<I, RouteManifestNode<I>> _indexManifestNodes<I extends Object>(
  List<RouteManifestRoute<I>> routes,
  List<RouteManifestLayout<I>> layouts,
) {
  final nodes = <I, RouteManifestNode<I>>{};
  for (final node in <RouteManifestNode<I>>[...layouts, ...routes]) {
    final previous = nodes[node.id];
    if (previous != null) {
      throw RouteManifestValidationException(
        'Duplicate route manifest ID ${node.id}',
        nodeIds: [node.id],
      );
    }
    nodes[node.id] = node;
  }
  return nodes;
}

RouteManifestRoute<I> _copyManifestRoute<I extends Object>(
  RouteManifestRoute<I> route,
) => RouteManifestRoute<I>(
  id: route.id,
  path: route.path,
  parentId: route.parentId,
);

RouteManifestLayout<I> _copyManifestLayout<I extends Object>(
  RouteManifestLayout<I> layout,
) => RouteManifestLayout<I>(
  id: layout.id,
  path: layout.path,
  parentId: layout.parentId,
  kind: layout.kind,
  indexedChildIds: layout.indexedChildIds,
  branchChildIds: layout.branchChildIds,
);

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
      final child = nodes[childId];
      if (child == null) {
        throw RouteManifestValidationException(
          'Indexed child $childId of ${layout.id} is unknown',
          nodeIds: [layout.id, childId],
        );
      }
      if (child.parentId != layout.id) {
        throw RouteManifestValidationException(
          'Indexed child $childId must be a direct child of ${layout.id}',
          nodeIds: [layout.id, childId],
        );
      }
    }
  }

  for (final layout in layouts) {
    if (layout.kind != RouteManifestLayoutKind.branched) continue;
    final branchIds = layout.branchChildIds.toSet();

    for (final branchId in layout.branchChildIds) {
      final branch = nodes[branchId];
      if (branch is! RouteManifestLayout<I>) {
        throw RouteManifestValidationException(
          'Branch child $branchId of ${layout.id} is not a known layout',
          nodeIds: [layout.id, branchId],
        );
      }
      if (branch.parentId != layout.id) {
        throw RouteManifestValidationException(
          'Branch child $branchId must be a direct child of ${layout.id}',
          nodeIds: [layout.id, branchId],
        );
      }
    }

    for (final child in nodes.values.where(
      (node) => node.parentId == layout.id,
    )) {
      if (child is! RouteManifestLayout<I> || !branchIds.contains(child.id)) {
        throw RouteManifestValidationException(
          'Direct child ${child.id} of branched layout ${layout.id} must be '
          'declared as a branch layout',
          nodeIds: [layout.id, child.id],
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

RouteManifestRoute<I> _routeFromJson<I extends Object>(
  Map<String, Object?> json,
  RouteIdCodec<I> idCodec,
) {
  return RouteManifestRoute<I>(
    id: idCodec.decode(_requiredString(json, 'id')),
    path: _requiredString(json, 'path'),
    parentId: switch (_optionalString(json, 'parentId')) {
      final parentId? => idCodec.decode(parentId),
      null => null,
    },
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
    branchChildIds: _stringList(json, 'branchChildIds').map(idCodec.decode),
  );
}

RouteIdCodec<I>? _resolveIdCodec<I extends Object>(RouteIdCodec<I>? idCodec) {
  if (idCodec != null) return idCodec;
  if (I == String) return RouteIdCodec.string as RouteIdCodec<I>;
  return null;
}

String Function(Object id) _eraseIdEncoder<I extends Object>(
  RouteIdCodec<I> idCodec,
) =>
    (id) => _encodeId(idCodec, id as I);

Object Function(String wireId) _eraseIdDecoder<I extends Object>(
  RouteIdCodec<I> idCodec,
) => idCodec.decode;

RouteIdCodec<I>? _composeFragmentCodecs<I extends Object>(
  List<RouteManifestFragment<I>> fragments,
) {
  if (fragments.isEmpty) return _resolveIdCodec<I>(null);
  if (I == String) return RouteIdCodec.string as RouteIdCodec<I>;
  if (fragments.any((fragment) => fragment.idCodec == null)) return null;

  final fragmentsByScope = <String, RouteManifestFragment<I>>{};
  final fragmentById = <I, RouteManifestFragment<I>>{};
  for (final fragment in fragments) {
    final previousScope = fragmentsByScope[fragment.name];
    if (previousScope != null) {
      throw RouteManifestValidationException(
        'Duplicate route manifest fragment name ${fragment.name}',
        nodeIds: [...previousScope.nodes.keys, ...fragment.nodes.keys],
      );
    }
    fragmentsByScope[fragment.name] = fragment;
    for (final id in fragment.nodes.keys) {
      final previous = fragmentById[id];
      if (previous != null) {
        throw RouteManifestValidationException(
          'Duplicate route manifest ID $id',
          nodeIds: [id],
        );
      }
      fragmentById[id] = fragment;
    }
  }

  return RouteIdCodec<I>(
    encode: (id) {
      final fragment = fragmentById[id];
      if (fragment == null) {
        throw StateError('Unknown composed route manifest ID: $id');
      }
      final localWireId = fragment._encodeObjectId!(id);
      return '${Uri.encodeComponent(fragment.name)}/'
          '${Uri.encodeComponent(localWireId)}';
    },
    decode: (wireId) {
      final separator = wireId.indexOf('/');
      if (separator <= 0 || separator == wireId.length - 1) {
        throw FormatException('Invalid scoped route manifest ID: $wireId');
      }
      final scope = Uri.decodeComponent(wireId.substring(0, separator));
      final localWireId = Uri.decodeComponent(wireId.substring(separator + 1));
      final fragment = fragmentsByScope[scope];
      if (fragment == null) {
        throw FormatException('Unknown route manifest fragment: $scope');
      }
      final id = fragment._decodeObjectId!(localWireId) as I;
      if (!fragment.nodes.containsKey(id)) {
        throw FormatException(
          'Unknown route manifest ID $localWireId in fragment $scope',
        );
      }
      return id;
    },
  );
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
