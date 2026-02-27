import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant TestCoordinator coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }

  @override
  List<Object?> get props => [];
}

class TestCoordinator extends Coordinator<AppRoute> {
  TestCoordinator({super.initialRoutePath});

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return HomeRoute();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoordinatorRouteInformationProvider', () {
    test('creates with coordinator and default initial route', () {
      final coordinator = TestCoordinator();
      final provider = CoordinatorRouteInformationProvider(
        coordinator: coordinator,
      );

      expect(provider.coordinator, equals(coordinator));
      expect(provider.value.uri.toString(), equals('/'));
    });

    test('reports new route information', () {
      final coordinator = TestCoordinator();
      final provider = CoordinatorRouteInformationProvider(
        coordinator: coordinator,
      );

      provider.routerReportsNewRouteInformation(
        RouteInformation(uri: Uri.parse('/new-route')),
      );

      expect(provider.value.uri.toString(), equals('/new-route'));
    });

    test('inherits from PlatformRouteInformationProvider', () {
      final coordinator = TestCoordinator();
      final provider = CoordinatorRouteInformationProvider(
        coordinator: coordinator,
      );

      expect(provider, isA<PlatformRouteInformationProvider>());
      expect(provider, isA<RouteInformationProvider>());
    });
  });

  group('resolveInitialUri', () {
    test('returns "/" when platformRouteName and initialUri are null', () {
      final result = CoordinatorRouteInformationProvider.resolveInitialUri(
        null,
        null,
      );
      expect(result.toString(), equals('/'));
    });

    test(
      'returns "/" when platformRouteName is empty and initialUri is null',
      () {
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          '',
          null,
        );
        expect(result.toString(), equals('/'));
      },
    );

    test(
      'returns initialUri when platformRouteName is empty and initialUri is provided',
      () {
        final initialUri = Uri.parse('/initial');
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          '',
          initialUri,
        );
        expect(result, equals(initialUri));
      },
    );

    test(
      'returns defaultUri with "/" path when platformRouteName has empty path and initialUri is null',
      () {
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          'https://example.com',
          null,
        );
        expect(result.toString(), equals('https://example.com/'));
      },
    );

    test(
      'returns initialUri when platformRouteName has empty path and initialUri is provided',
      () {
        final initialUri = Uri.parse('/custom');
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          'https://example.com',
          initialUri,
        );
        expect(result, equals(initialUri));
      },
    );

    test(
      'returns platformRouteName when it has non-empty path and initialUri is null',
      () {
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          '/platform',
          null,
        );
        expect(result.toString(), equals('/platform'));
      },
    );

    test(
      'returns platformRouteName when it has non-empty path and initialUri is provided',
      () {
        final initialUri = Uri.parse('/initial');
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          '/platform',
          initialUri,
        );
        expect(result.toString(), equals('/platform'));
      },
    );

    test(
      'returns "/" when platformRouteName is invalid and initialUri is null',
      () {
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          '::invalid::',
          null,
        );
        expect(result.toString(), equals('/'));
      },
    );

    test(
      'returns "/" when platformRouteName is invalid and initialUri is provided',
      () {
        final initialUri = Uri.parse('/initial');
        final result = CoordinatorRouteInformationProvider.resolveInitialUri(
          '::invalid::',
          initialUri,
        );
        expect(result.toString(), equals('/initial'));
      },
    );
  });
}
