import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/src/transition.dart';

void main() {
  group('CupertinoSheetPage', () {
    testWidgets('creates CupertinoSheetRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final page = CupertinoSheetPage(
                key: const ValueKey('sheet'),
                builder: (context) => const Text('Sheet Content'),
              );

              final route = page.createRoute(context);

              expect(route, isA<CupertinoSheetRoute>());
              expect(route.settings, equals(page));

              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('builder is called when route is created', (tester) async {
      var builderCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final page = CupertinoSheetPage(
                builder: (context) {
                  builderCalled = true;
                  return const Text('Sheet');
                },
              );

              final route = page.createRoute(context) as CupertinoSheetRoute;
              route.builder(context);

              expect(builderCalled, true);

              return Container();
            },
          ),
        ),
      );
    });
  });

  group('DialogPage', () {
    testWidgets('creates DialogRoute', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final page = DialogPage(
                key: const ValueKey('dialog'),
                child: const Text('Dialog Content'),
              );

              final route = page.createRoute(context);

              expect(route, isA<DialogRoute>());
              expect(route.settings, equals(page));

              return Container();
            },
          ),
        ),
      );
    });
  });
}
