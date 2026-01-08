import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/src/path/transition.dart';

void main() {
  group('CustomTransitionPage', () {
    test('creates with required parameters', () {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      );

      expect(page.child, isA<Text>());
      expect(page.transitionDuration, const Duration(milliseconds: 300));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 300));
      expect(page.maintainState, true);
      expect(page.fullscreenDialog, false);
      expect(page.opaque, true);
      expect(page.barrierDismissible, false);
      expect(page.barrierColor, isNull);
      expect(page.barrierLabel, isNull);
    });

    test('creates with custom durations', () {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      );

      expect(page.transitionDuration, const Duration(milliseconds: 500));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 200));
    });

    test('creates with all optional parameters', () {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        maintainState: false,
        fullscreenDialog: true,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        barrierLabel: 'Dismiss',
        key: const ValueKey('custom-page'),
        name: '/custom',
        arguments: {'id': 123},
        restorationId: 'custom-restoration',
      );

      expect(page.transitionDuration, const Duration(milliseconds: 400));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 150));
      expect(page.maintainState, false);
      expect(page.fullscreenDialog, true);
      expect(page.opaque, false);
      expect(page.barrierDismissible, true);
      expect(page.barrierColor, Colors.black54);
      expect(page.barrierLabel, 'Dismiss');
      expect(page.key, const ValueKey('custom-page'));
      expect(page.name, '/custom');
      expect(page.arguments, {'id': 123});
      expect(page.restorationId, 'custom-restoration');
    });

    testWidgets('createRoute returns a valid PageRoute', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Custom Page Content'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

      late Route route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route, isA<PageRoute>());
      expect(route.settings, page);
    });

    testWidgets('route has correct transition duration', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 250),
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.transitionDuration, const Duration(milliseconds: 500));
      expect(route.reverseTransitionDuration, const Duration(milliseconds: 250));
    });

    testWidgets('route has correct barrier properties', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        barrierDismissible: true,
        barrierColor: Colors.red,
        barrierLabel: 'Close',
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.barrierDismissible, true);
      expect(route.barrierColor, Colors.red);
      expect(route.barrierLabel, 'Close');
    });

    testWidgets('route has correct maintainState and opaque', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        maintainState: false,
        opaque: false,
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.maintainState, false);
      expect(route.opaque, false);
    });

    testWidgets('route has correct fullscreenDialog flag', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        fullscreenDialog: true,
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.fullscreenDialog, true);
    });

    testWidgets('transitionsBuilder is called during navigation',
        (tester) async {
      var transitionsBuilderCalled = false;

      final page = CustomTransitionPage(
        child: const Text('Target Page', key: ValueKey('target')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          transitionsBuilderCalled = true;
          return FadeTransition(opacity: animation, child: child);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      // Tap the button to navigate
      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(transitionsBuilderCalled, true);
      expect(find.byKey(const ValueKey('target')), findsOneWidget);
    });

    testWidgets('fade transition animates correctly', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Fading Content', key: ValueKey('fading')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();

      // At the start of animation
      await tester.pump(const Duration(milliseconds: 0));
      var fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, closeTo(0.0, 0.1));

      // Midway through animation
      await tester.pump(const Duration(milliseconds: 150));
      fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, closeTo(0.5, 0.1));

      // At end of animation
      await tester.pump(const Duration(milliseconds: 150));
      fadeTransition = tester.widget<FadeTransition>(
        find.byType(FadeTransition),
      );
      expect(fadeTransition.opacity.value, closeTo(1.0, 0.1));
    });

    testWidgets('slide transition animates correctly', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Sliding Content', key: ValueKey('sliding')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideTween = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          );
          return SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();

      // At the start of animation - should be off screen
      await tester.pump(const Duration(milliseconds: 0));
      var slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value.dx, closeTo(1.0, 0.1));

      // At end of animation - should be in place
      await tester.pumpAndSettle();
      slideTransition = tester.widget<SlideTransition>(
        find.byType(SlideTransition),
      );
      expect(slideTransition.position.value.dx, closeTo(0.0, 0.01));
    });

    testWidgets('scale transition animates correctly', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Scaling Content', key: ValueKey('scaling')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(scale: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();

      // At the start of animation
      await tester.pump(const Duration(milliseconds: 0));
      var scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scaleTransition.scale.value, closeTo(0.0, 0.1));

      // At end of animation
      await tester.pumpAndSettle();
      scaleTransition = tester.widget<ScaleTransition>(
        find.byType(ScaleTransition),
      );
      expect(scaleTransition.scale.value, closeTo(1.0, 0.01));
    });

    testWidgets('child widget is wrapped in Semantics', (tester) async {
      final page = CustomTransitionPage(
        child: const Text('Semantic Content', key: ValueKey('semantic')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      // Find the Semantics widget wrapping our content
      final semanticsFinder = find.ancestor(
        of: find.byKey(const ValueKey('semantic')),
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsWidgets);

      // Verify the Semantics widget exists as an ancestor
      final semanticsElements = semanticsFinder.evaluate();
      expect(semanticsElements.isNotEmpty, true);
    });

    testWidgets('page can be used in Navigator.pages', (tester) async {
      final pages = [
        const MaterialPage(
          key: ValueKey('home'),
          child: Text('Home'),
        ),
        CustomTransitionPage(
          key: const ValueKey('custom'),
          child: const Text('Custom Page', key: ValueKey('custom-content')),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            pages: pages,
            onDidRemovePage: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('custom-content')), findsOneWidget);
    });

    testWidgets('secondaryAnimation is passed to transitionsBuilder',
        (tester) async {
      Animation<double>? capturedSecondaryAnimation;

      final firstPage = CustomTransitionPage(
        key: const ValueKey('first'),
        child: const Text('First', key: ValueKey('first-content')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          capturedSecondaryAnimation = secondaryAnimation;
          return FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.5).animate(
              secondaryAnimation,
            ),
            child: child,
          );
        },
      );

      final secondPage = CustomTransitionPage(
        key: const ValueKey('second'),
        child: const Text('Second', key: ValueKey('second-content')),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const ValueKey('nav-button'),
                onPressed: () {
                  Navigator.of(context).push(firstPage.createRoute(context));
                },
                child: const Text('First'),
              );
            },
          ),
        ),
      );

      // Navigate to first page
      await tester.tap(find.byKey(const ValueKey('nav-button')));
      await tester.pumpAndSettle();

      expect(capturedSecondaryAnimation, isNotNull);
      expect(capturedSecondaryAnimation!.value, 0.0);

      // Navigate to second page - secondary animation should activate
      await tester.tap(
        find.byKey(const ValueKey('first-content')),
        warnIfMissed: false,
      );
      Navigator.of(tester.element(find.byKey(const ValueKey('first-content'))))
          .push(secondPage.createRoute(
              tester.element(find.byKey(const ValueKey('first-content')))));
      await tester.pumpAndSettle();

      // Secondary animation should have completed
      expect(capturedSecondaryAnimation!.value, 1.0);
    });

    test('default values match documentation', () {
      final page = CustomTransitionPage(
        child: const Text('Test'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      );

      // Verify defaults as documented in the class
      expect(page.transitionDuration, const Duration(milliseconds: 300));
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 300));
      expect(page.maintainState, true);
      expect(page.fullscreenDialog, false);
      expect(page.opaque, true);
      expect(page.barrierDismissible, false);
    });
  });

  group('NoTransitionPage', () {
    test('creates with required parameters', () {
      final page = NoTransitionPage(
        child: const Text('Test'),
      );

      expect(page.child, isA<Text>());
    });

    test('creates with optional restorationId', () {
      final page = NoTransitionPage(
        key: const ValueKey('no-transition'),
        child: const Text('Test'),
        restorationId: 'no-transition-restoration',
      );

      expect(page.key, const ValueKey('no-transition'));
      expect(page.restorationId, 'no-transition-restoration');
    });

    testWidgets('route has zero transition duration', (tester) async {
      final page = NoTransitionPage(
        child: const Text('Instant Content'),
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
    });

    testWidgets('route has transparent barrier', (tester) async {
      final page = NoTransitionPage(
        child: const Text('Test'),
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.barrierColor, Colors.transparent);
      expect(route.barrierLabel, 'No transition');
    });

    testWidgets('route maintains state', (tester) async {
      final page = NoTransitionPage(
        child: const Text('Test'),
      );

      late PageRoute route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context) as PageRoute;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route.maintainState, true);
    });

    testWidgets('content appears instantly without animation', (tester) async {
      final page = NoTransitionPage(
        child: const Text('Instant', key: ValueKey('instant')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Navigate'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      // Just one pump - content should be visible immediately
      await tester.pump();

      expect(find.byKey(const ValueKey('instant')), findsOneWidget);
    });
  });

  group('CupertinoSheetPage', () {
    test('creates with required parameters', () {
      final page = CupertinoSheetPage(
        builder: (context) => const Text('Sheet Content'),
      );

      expect(page.builder, isA<WidgetBuilder>());
    });

    test('creates with optional parameters', () {
      final page = CupertinoSheetPage(
        key: const ValueKey('sheet'),
        builder: (context) => const Text('Sheet Content'),
        restorationId: 'sheet-restoration',
      );

      expect(page.key, const ValueKey('sheet'));
      expect(page.restorationId, 'sheet-restoration');
    });

    testWidgets('createRoute returns CupertinoSheetRoute', (tester) async {
      final page = CupertinoSheetPage(
        builder: (context) => const Text('Sheet'),
      );

      late Route route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route, isA<CupertinoSheetRoute>());
      expect(route.settings, page);
    });
  });

  group('DialogPage', () {
    test('creates with required parameters', () {
      final page = DialogPage(
        child: const Text('Dialog Content'),
      );

      expect(page.child, isA<Text>());
    });

    test('creates with optional parameters', () {
      final page = DialogPage(
        key: const ValueKey('dialog'),
        child: const Text('Dialog Content'),
        restorationId: 'dialog-restoration',
      );

      expect(page.key, const ValueKey('dialog'));
      expect(page.restorationId, 'dialog-restoration');
    });

    testWidgets('createRoute returns DialogRoute', (tester) async {
      final page = DialogPage(
        child: const Text('Dialog'),
      );

      late Route route;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              route = page.createRoute(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(route, isA<DialogRoute>());
      expect(route.settings, page);
    });

    testWidgets('dialog content is displayed', (tester) async {
      final page = DialogPage(
        child: const AlertDialog(
          content: Text('Dialog Message', key: ValueKey('dialog-content')),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(page.createRoute(context));
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dialog-content')), findsOneWidget);
    });
  });
}
