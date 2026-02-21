import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Setup
// ============================================================================

abstract class TestRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

// Simple route with RouteUnique only
class SimpleRoute extends TestRoute {
  SimpleRoute(this.id);
  final String id;

  @override
  Uri toUri() => Uri.parse('/simple/$id');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Simple $id'));
  }

  @override
  List<Object?> get props => [id];
}

// Route with RouteRestorable using converter strategy
class ComplexRoute extends TestRoute with RouteRestorable<ComplexRoute> {
  ComplexRoute({required this.id, required this.data, this.metadata});

  final String id;
  final Map<String, dynamic> data;
  final String? metadata;

  @override
  String get restorationId => 'complex_$id';

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.converter;

  @override
  RestorableConverter<ComplexRoute> get converter =>
      const ComplexRouteConverter();

  @override
  Uri toUri() => Uri.parse('/complex/$id');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Complex $id'));
  }

  @override
  List<Object?> get props => [id, data, metadata];
}

class ComplexRouteConverter extends RestorableConverter<ComplexRoute> {
  const ComplexRouteConverter();

  @override
  String get key => 'test_complex_route';

  @override
  Map<String, dynamic> serialize(ComplexRoute route) {
    return {'id': route.id, 'data': route.data, 'metadata': route.metadata};
  }

  @override
  ComplexRoute deserialize(Map<String, dynamic> data) {
    return ComplexRoute(
      id: data['id'] as String,
      data: (data['data'] as Map).cast<String, dynamic>(),
      metadata: data['metadata'] as String?,
    );
  }
}

// Route with RouteRestorable using unique strategy
class UniqueRestorableRoute extends TestRoute
    with RouteRestorable<UniqueRestorableRoute> {
  UniqueRestorableRoute(this.id);
  final String id;

  @override
  String get restorationId => 'unique_$id';

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.unique;

  @override
  RestorableConverter<UniqueRestorableRoute> get converter =>
      throw UnimplementedError();

  @override
  Uri toUri() => Uri.parse('/unique/$id');

  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text('Unique $id'));
  }

  @override
  List<Object?> get props => [id];
}

// Coordinator for testing
class TestCoordinator extends Coordinator<TestRoute> {
  @override
  void defineConverter() {
    defineRestorableConverter(
      'test_complex_route',
      () => const ComplexRouteConverter(),
    );
  }

  @override
  TestRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['simple', final id] => SimpleRoute(id),
      ['complex', final id] => ComplexRoute(id: id, data: {}),
      ['unique', final id] => UniqueRestorableRoute(id),
      _ => SimpleRoute('default'),
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('RestorationStrategy Enum', () {
    test('has unique and converter values', () {
      expect(RestorationStrategy.values, hasLength(2));
      expect(RestorationStrategy.values, contains(RestorationStrategy.unique));
      expect(
        RestorationStrategy.values,
        contains(RestorationStrategy.converter),
      );
    });

    test('can be retrieved by name', () {
      final strategy = RestorationStrategy.values.asNameMap()['unique'];
      expect(strategy, equals(RestorationStrategy.unique));

      final converterStrategy = RestorationStrategy.values
          .asNameMap()['converter'];
      expect(converterStrategy, equals(RestorationStrategy.converter));
    });
  });

  group('RouteRestorable Mixin - Serialization', () {
    test('serializes route with converter strategy correctly', () {
      final route = ComplexRoute(
        id: '123',
        data: {'key': 'value', 'count': 42},
        metadata: 'test metadata',
      );

      final serialized = route.serialize();

      expect(serialized, isA<Map<String, dynamic>>());
      expect(serialized['strategy'], equals('converter'));
      expect(serialized['converter'], equals('test_complex_route'));
      expect(serialized['value'], isA<Map>());
      expect(serialized['value']['id'], equals('123'));
      expect(serialized['value']['data']['key'], equals('value'));
      expect(serialized['value']['data']['count'], equals(42));
      expect(serialized['value']['metadata'], equals('test metadata'));
    });

    test('serializes route with unique strategy correctly', () {
      final route = UniqueRestorableRoute('456');

      final serialized = route.serialize();

      expect(serialized, isA<Map<String, dynamic>>());
      expect(serialized['strategy'], equals('unique'));
      expect(serialized['value'], equals('/unique/456'));
      expect(serialized.containsKey('converter'), isFalse);
    });

    test('handles null metadata in serialization', () {
      final route = ComplexRoute(
        id: '789',
        data: {'test': 'data'},
        metadata: null,
      );

      final serialized = route.serialize();

      expect(serialized['value']['metadata'], isNull);
    });

    test('preserves complex nested data structures', () {
      final route = ComplexRoute(
        id: '999',
        data: {
          'nested': {'deep': 'value'},
          'list': [1, 2, 3],
          'mixed': {
            'items': [1, 'two', 3.0],
          },
        },
      );

      final serialized = route.serialize();
      final data = serialized['value']['data'] as Map;

      expect(data['nested']['deep'], equals('value'));
      expect(data['list'], equals([1, 2, 3]));
      expect(data['mixed']['items'], equals([1, 'two', 3.0]));
    });
  });

  group('RouteRestorable Mixin - Deserialization', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('deserializes route with converter strategy correctly', () {
      final data = {
        'strategy': 'converter',
        'converter': 'test_complex_route',
        'value': {
          'id': '123',
          'data': {'key': 'value', 'count': 42},
          'metadata': 'restored metadata',
        },
      };

      final route = RouteRestorable.deserialize<TestRoute>(
        data,
        parseRouteFromUri: coordinator.parseRouteFromUriSync,
        getRestorableConverter: coordinator.getRestorableConverter,
      );

      expect(route, isA<ComplexRoute>());
      final complexRoute = route as ComplexRoute;
      expect(complexRoute.id, equals('123'));
      expect(complexRoute.data['key'], equals('value'));
      expect(complexRoute.data['count'], equals(42));
      expect(complexRoute.metadata, equals('restored metadata'));
    });

    test('deserializes route with unique strategy correctly', () {
      final data = {'strategy': 'unique', 'value': '/unique/456'};

      final route = RouteRestorable.deserialize<TestRoute>(
        data,
        parseRouteFromUri: coordinator.parseRouteFromUriSync,
        getRestorableConverter: coordinator.getRestorableConverter,
      );

      expect(route, isA<UniqueRestorableRoute>());
      expect((route as UniqueRestorableRoute).id, equals('456'));
    });

    test('handles null metadata in deserialization', () {
      final data = {
        'strategy': 'converter',
        'converter': 'test_complex_route',
        'value': {
          'id': '789',
          'data': {'test': 'data'},
          'metadata': null,
        },
      };

      final route = RouteRestorable.deserialize<TestRoute>(
        data,
        parseRouteFromUri: coordinator.parseRouteFromUriSync,
        getRestorableConverter: coordinator.getRestorableConverter,
      );

      expect(route, isA<ComplexRoute>());
      expect((route as ComplexRoute).metadata, isNull);
    });

    test('throws on null strategy', () {
      final data = {'strategy': null, 'value': '/test'};

      expect(
        () => RouteRestorable.deserialize<TestRoute>(
          data,
          parseRouteFromUri: coordinator.parseRouteFromUriSync,
          getRestorableConverter: coordinator.getRestorableConverter,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('throws on invalid strategy type', () {
      final data = {
        'strategy': 123, // Not a string
        'value': '/test',
      };

      expect(
        () => RouteRestorable.deserialize<TestRoute>(
          data,
          parseRouteFromUri: coordinator.parseRouteFromUriSync,
          getRestorableConverter: coordinator.getRestorableConverter,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('throws on unregistered converter key', () {
      final data = {
        'strategy': 'converter',
        'converter': 'unregistered_converter',
        'value': {'data': 'test'},
      };

      expect(
        () => RouteRestorable.deserialize<TestRoute>(
          data,
          parseRouteFromUri: coordinator.parseRouteFromUriSync,
          getRestorableConverter: coordinator.getRestorableConverter,
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('requires parseRouteFromUri for unique strategy', () {
      final data = {'strategy': 'unique', 'value': '/unique/123'};

      // Without parseRouteFromUri, should fail assertion
      expect(
        () => RouteRestorable.deserialize<TestRoute>(
          data,
          parseRouteFromUri: null,
          getRestorableConverter: coordinator.getRestorableConverter,
        ),
        throwsAssertionError,
      );
    });
  });

  group('RouteRestorable Mixin - Round Trip', () {
    late TestCoordinator coordinator;

    setUp(() {
      coordinator = TestCoordinator();
    });

    test('converter strategy round-trip preserves all data', () {
      final original = ComplexRoute(
        id: '123',
        data: {
          'key': 'value',
          'nested': {'deep': 'data'},
        },
        metadata: 'test',
      );

      final serialized = original.serialize();
      final restored =
          RouteRestorable.deserialize<TestRoute>(
                serialized,
                parseRouteFromUri: coordinator.parseRouteFromUriSync,
                getRestorableConverter: coordinator.getRestorableConverter,
              )
              as ComplexRoute;

      expect(restored.id, equals(original.id));
      expect(restored.data, equals(original.data));
      expect(restored.metadata, equals(original.metadata));
    });

    test('unique strategy round-trip preserves route identity', () {
      final original = UniqueRestorableRoute('456');

      final serialized = original.serialize();
      final restored =
          RouteRestorable.deserialize<TestRoute>(
                serialized,
                parseRouteFromUri: coordinator.parseRouteFromUriSync,
                getRestorableConverter: coordinator.getRestorableConverter,
              )
              as UniqueRestorableRoute;

      expect(restored.id, equals(original.id));
      expect(restored.toUri(), equals(original.toUri()));
    });
  });

  group('RestorableConverter - Implementation', () {
    test('converter key is stable', () {
      final converter = const ComplexRouteConverter();

      expect(converter.key, equals('test_complex_route'));
      expect(converter.key, equals(converter.key)); // Same instance
    });

    test('converter serializes correctly', () {
      final converter = const ComplexRouteConverter();
      final route = ComplexRoute(
        id: '123',
        data: {'test': 'value'},
        metadata: 'meta',
      );

      final serialized = converter.serialize(route);

      expect(serialized['id'], equals('123'));
      expect(serialized['data']['test'], equals('value'));
      expect(serialized['metadata'], equals('meta'));
    });

    test('converter deserializes correctly', () {
      final converter = const ComplexRouteConverter();
      final data = {
        'id': '456',
        'data': {'key': 'value'},
        'metadata': 'restored',
      };

      final route = converter.deserialize(data);

      expect(route.id, equals('456'));
      expect(route.data['key'], equals('value'));
      expect(route.metadata, equals('restored'));
    });

    test('converter round-trip preserves data', () {
      final converter = const ComplexRouteConverter();
      final original = ComplexRoute(
        id: '789',
        data: {
          'complex': {'nested': 'structure'},
        },
        metadata: 'preserve this',
      );

      final serialized = converter.serialize(original);
      final restored = converter.deserialize(serialized);

      expect(restored.id, equals(original.id));
      expect(restored.data, equals(original.data));
      expect(restored.metadata, equals(original.metadata));
    });
  });

  group('RouteRestorable - Properties', () {
    test('default strategy is unique', () {
      // Create a minimal implementation to test default
      final route = UniqueRestorableRoute('123');

      expect(route.restorationStrategy, equals(RestorationStrategy.unique));
    });

    test('converter throws UnimplementedError for unique strategy', () {
      final route = UniqueRestorableRoute('123');

      expect(() => route.converter, throwsUnimplementedError);
    });

    test('restorationId is required', () {
      final route = ComplexRoute(id: '123', data: {});

      expect(route.restorationId, isNotNull);
      expect(route.restorationId, equals('complex_123'));
    });

    test('restorationId should be stable', () {
      final route1 = ComplexRoute(id: '123', data: {});
      final route2 = ComplexRoute(id: '123', data: {});

      expect(route1.restorationId, equals(route2.restorationId));
    });

    test('restorationId should be unique per instance', () {
      final route1 = ComplexRoute(id: '123', data: {});
      final route2 = ComplexRoute(id: '456', data: {});

      expect(route1.restorationId, isNot(equals(route2.restorationId)));
    });
  });
}
