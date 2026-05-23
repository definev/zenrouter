import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test setup
// ============================================================================

abstract class ViewRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

class HomeRoute extends ViewRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant Coordinator<ViewRoute> coordinator, BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }

  @override
  List<Object?> get props => [];
}

class SettingsRoute extends ViewRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant Coordinator<ViewRoute> coordinator, BuildContext context) {
    return const Scaffold(body: Text('Settings'));
  }

  @override
  List<Object?> get props => [];
}

class ProfileRoute extends ViewRoute {
  ProfileRoute(this.id);

  final String id;

  @override
  Uri toUri() => Uri.parse('/profile/$id');

  @override
  Widget build(covariant Coordinator<ViewRoute> coordinator, BuildContext context) {
    return Scaffold(body: Text('Profile $id'));
  }

  @override
  List<Object?> get props => [id];
}

class ViewTestCoordinator extends Coordinator<ViewRoute> {
  ViewTestCoordinator({this.parser, this.asyncParse = false});

  final ViewRoute? Function(Uri uri)? parser;
  final bool asyncParse;
  int parseCalls = 0;

  @override
  FutureOr<ViewRoute?> parseRouteFromUri(Uri uri) async {
    if (asyncParse) {
      parseCalls++;
      await Future<void>.delayed(Duration.zero);
    }
    if (parser != null) return parser!(uri);
    return switch (uri.pathSegments) {
      [] || [''] => HomeRoute(),
      ['settings'] => SettingsRoute(),
      ['profile', final id] => ProfileRoute(id),
      _ => null,
    };
  }
}

Widget _host({
  required Coordinator<ViewRoute> coordinator,
  Uri? initialUri,
  Key? key,
}) {
  return MaterialApp(
    home: CoordinatorView<ViewRoute>(
      key: key,
      coordinator: coordinator,
      initialUri: initialUri,
    ),
  );
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('CoordinatorView', () {
    testWidgets('builds coordinator layout via layoutBuilder', (tester) async {
      final coordinator = ViewTestCoordinator();
      await coordinator.replace(HomeRoute());

      await tester.pumpWidget(_host(coordinator: coordinator));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('applies initialUri when root stack is empty', (tester) async {
      final coordinator = ViewTestCoordinator();

      await tester.pumpWidget(
        _host(
          coordinator: coordinator,
          initialUri: Uri.parse('/settings'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.single, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('supports async parseRouteFromUri for initialUri', (
      tester,
    ) async {
      final coordinator = ViewTestCoordinator(asyncParse: true);

      await tester.pumpWidget(
        _host(
          coordinator: coordinator,
          initialUri: Uri.parse('/settings'),
        ),
      );
      await tester.pump();
      expect(coordinator.parseCalls, 1);
      expect(find.text('Settings'), findsNothing);

      await tester.pumpAndSettle();

      expect(coordinator.root.stack.single, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('skips initialUri when root stack is not empty', (
      tester,
    ) async {
      final coordinator = ViewTestCoordinator();
      await coordinator.replace(HomeRoute());

      await tester.pumpWidget(
        _host(
          coordinator: coordinator,
          initialUri: Uri.parse('/settings'),
        ),
      );
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.single, isA<HomeRoute>());
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('does not navigate when initialUri is null', (tester) async {
      final coordinator = ViewTestCoordinator();

      await tester.pumpWidget(_host(coordinator: coordinator));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack, isEmpty);
    });

    testWidgets('does not navigate when parseRouteFromUri returns null', (
      tester,
    ) async {
      final coordinator = ViewTestCoordinator(parser: (_) => null);

      await tester.pumpWidget(
        _host(
          coordinator: coordinator,
          initialUri: Uri.parse('/unknown'),
        ),
      );
      await tester.pumpAndSettle();

      expect(coordinator.root.stack, isEmpty);
    });

    testWidgets('preserves stack when remounted with same coordinator', (
      tester,
    ) async {
      final coordinator = ViewTestCoordinator();

      await tester.pumpWidget(
        _host(
          key: const ValueKey('first'),
          coordinator: coordinator,
          initialUri: Uri.parse('/settings'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(
          key: const ValueKey('second'),
          coordinator: coordinator,
          initialUri: Uri.parse('/'),
        ),
      );
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.single, isA<SettingsRoute>());
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('applies initialUri after coordinator swap when root is empty', (
      tester,
    ) async {
      final first = ViewTestCoordinator();
      final second = ViewTestCoordinator();

      await tester.pumpWidget(
        _host(
          coordinator: first,
          initialUri: Uri.parse('/settings'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          coordinator: second,
          initialUri: Uri.parse('/profile/42'),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(second.root.stack.single, isA<ProfileRoute>());
      expect(find.text('Profile 42'), findsOneWidget);
      expect(first.root.stack.single, isA<SettingsRoute>());
    });

    testWidgets('applies initialUri when it is set while root is still empty', (
      tester,
    ) async {
      await tester.pumpWidget(const _InitialUriHost());
      await tester.pump();
      expect(find.text('Settings'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('set-uri')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('ignores initialUri update when root already has routes', (
      tester,
    ) async {
      final coordinator = ViewTestCoordinator();
      await coordinator.replace(HomeRoute());

      await tester.pumpWidget(
        _InitialUriHost(
          coordinator: coordinator,
          startUri: Uri.parse('/'),
          updatedUri: Uri.parse('/profile/7'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('switch-uri')));
      await tester.pumpAndSettle();

      expect(coordinator.root.stack.single, isA<HomeRoute>());
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile 7'), findsNothing);
    });
  });
}

class _InitialUriHost extends StatefulWidget {
  const _InitialUriHost({
    this.coordinator,
    this.startUri,
    this.updatedUri,
  });

  final ViewTestCoordinator? coordinator;
  final Uri? startUri;
  final Uri? updatedUri;

  @override
  State<_InitialUriHost> createState() => _InitialUriHostState();
}

class _InitialUriHostState extends State<_InitialUriHost> {
  late final ViewTestCoordinator _coordinator =
      widget.coordinator ?? ViewTestCoordinator();
  late Uri? _initialUri = widget.startUri;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Column(
        children: [
          GestureDetector(
            key: const ValueKey('set-uri'),
            onTap: () {
              setState(
                () => _initialUri = widget.updatedUri ?? Uri.parse('/settings'),
              );
            },
            child: const Text('set-uri'),
          ),
          GestureDetector(
            key: const ValueKey('switch-uri'),
            onTap: () {
              setState(() => _initialUri = Uri.parse('/profile/7'));
            },
            child: const Text('switch-uri'),
          ),
          Expanded(
            child: CoordinatorView<ViewRoute>(
              coordinator: _coordinator,
              initialUri: _initialUri,
            ),
          ),
        ],
      ),
    );
  }
}
