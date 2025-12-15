import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// Test route implementation
class TestRoute extends RouteTarget {
  TestRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

// Track widget builds for verification
class BuildTracker {
  static final Map<String, int> _buildCounts = {};
  static final Set<String> _activeWidgets = {};

  static void reset() {
    _buildCounts.clear();
    _activeWidgets.clear();
  }

  static void recordBuild(String id) {
    _buildCounts[id] = (_buildCounts[id] ?? 0) + 1;
    _activeWidgets.add(id);
  }

  static void recordDispose(String id) {
    _activeWidgets.remove(id);
  }

  static int getBuildCount(String id) => _buildCounts[id] ?? 0;
  static bool isActive(String id) => _activeWidgets.contains(id);
  static int get totalBuilds =>
      _buildCounts.values.fold(0, (sum, count) => sum + count);
}

// Stateful widget that tracks builds
class TrackedWidget extends StatefulWidget {
  const TrackedWidget({super.key, required this.routeId});

  final String routeId;

  @override
  State<TrackedWidget> createState() => _TrackedWidgetState();
}

class _TrackedWidgetState extends State<TrackedWidget> {
  @override
  void initState() {
    super.initState();
    BuildTracker.recordBuild(widget.routeId);
  }

  @override
  void dispose() {
    BuildTracker.recordDispose(widget.routeId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Route: ${widget.routeId}');
  }
}

// Simple destination resolver
StackTransition<TestRoute> testResolver(TestRoute route) {
  return StackTransition.material(TrackedWidget(routeId: route.id));
}

void main() {
  setUp(() {
    BuildTracker.reset();
  });

  group('NavigationStack - Diff-based page updates', () {
    testWidgets('creates pages for initial routes', (tester) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      // Push initial route using push (not pushOrMoveToTop)
      path.push(TestRoute('home'));
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('home'), 1);
      expect(find.text('Route: home'), findsOneWidget);
    });

    testWidgets('reuses pages when routes are unchanged', (tester) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      path.push(TestRoute('home'));
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('home'), 1);

      // Push and pop a route to trigger _updatePages without changing the stack
      // Don't await push - it returns a Future that completes on pop
      path.push(TestRoute('temp'));
      await tester.pumpAndSettle();
      path.pop();
      await tester.pumpAndSettle();

      // Home page should still only have been built once (reused via Keep)
      expect(BuildTracker.getBuildCount('home'), 1);
    });

    testWidgets('creates new page on push', (tester) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      path.push(TestRoute('home'));
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('home'), 1);
      expect(BuildTracker.getBuildCount('profile'), 0);

      // Push a new route (don't await - completes on pop)
      path.push(TestRoute('profile'));
      await tester.pumpAndSettle();

      // Home should be reused, profile should be new
      expect(BuildTracker.getBuildCount('home'), 1);
      expect(BuildTracker.getBuildCount('profile'), 1);
      expect(find.text('Route: profile'), findsOneWidget);
    });

    testWidgets('removes page on pop', (tester) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      path.push(TestRoute('home'));
      await tester.pumpAndSettle();

      path.push(TestRoute('profile'));
      await tester.pumpAndSettle();

      expect(BuildTracker.isActive('profile'), isTrue);

      // Pop the route
      path.pop();
      await tester.pumpAndSettle();

      // Profile widget should be disposed
      expect(BuildTracker.isActive('profile'), isFalse);
      expect(find.text('Route: profile'), findsNothing);
      expect(find.text('Route: home'), findsOneWidget);
    });

    testWidgets('preserves existing pages when pushing multiple routes', (
      tester,
    ) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      path.push(TestRoute('home'));
      await tester.pumpAndSettle();

      // Push multiple routes (don't await)
      path.push(TestRoute('profile'));
      await tester.pumpAndSettle();
      path.push(TestRoute('settings'));
      await tester.pumpAndSettle();
      path.push(TestRoute('about'));
      await tester.pumpAndSettle();

      // Each page should only be built once
      expect(BuildTracker.getBuildCount('home'), 1);
      expect(BuildTracker.getBuildCount('profile'), 1);
      expect(BuildTracker.getBuildCount('settings'), 1);
      expect(BuildTracker.getBuildCount('about'), 1);
    });

    testWidgets('handles empty stack gracefully', (tester) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );
      await tester.pumpAndSettle();

      // Should render empty container for empty stack
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('handles push after empty stack', (tester) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );
      await tester.pumpAndSettle();

      // Push to empty stack (don't await)
      path.push(TestRoute('first'));
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('first'), 1);
      expect(find.text('Route: first'), findsOneWidget);
    });

    testWidgets('correctly applies diff for complex stack changes', (
      tester,
    ) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      // Build initial stack: [a, b, c, d]
      path.push(TestRoute('a'));
      await tester.pumpAndSettle();
      path.push(TestRoute('b'));
      await tester.pumpAndSettle();
      path.push(TestRoute('c'));
      await tester.pumpAndSettle();
      path.push(TestRoute('d'));
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('a'), 1);
      expect(BuildTracker.getBuildCount('b'), 1);
      expect(BuildTracker.getBuildCount('c'), 1);
      expect(BuildTracker.getBuildCount('d'), 1);

      // Pop 'd' and 'c'
      path.pop();
      await tester.pumpAndSettle();
      path.pop();
      await tester.pumpAndSettle();

      // Stack is now [a, b]
      expect(path.stack.length, 2);
      expect(path.stack[0].id, 'a');
      expect(path.stack[1].id, 'b');

      // 'a' and 'b' should still only have been built once
      expect(BuildTracker.getBuildCount('a'), 1);
      expect(BuildTracker.getBuildCount('b'), 1);
    });

    testWidgets('pages maintain correct order after diff operations', (
      tester,
    ) async {
      final path = NavigationPath<TestRoute>();

      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path, resolver: testResolver),
        ),
      );

      path.push(TestRoute('1'));
      await tester.pumpAndSettle();
      path.push(TestRoute('2'));
      await tester.pumpAndSettle();
      path.push(TestRoute('3'));
      await tester.pumpAndSettle();

      expect(path.stack.map((r) => r.id).toList(), ['1', '2', '3']);

      // Pop and push different route
      path.pop();
      await tester.pumpAndSettle();
      path.push(TestRoute('4'));
      await tester.pumpAndSettle();

      expect(path.stack.map((r) => r.id).toList(), ['1', '2', '4']);

      // '1' and '2' should be reused
      expect(BuildTracker.getBuildCount('1'), 1);
      expect(BuildTracker.getBuildCount('2'), 1);
      expect(BuildTracker.getBuildCount('3'), 1);
      expect(BuildTracker.getBuildCount('4'), 1);
    });

    testWidgets('works correctly when path is swapped', (tester) async {
      final path1 = NavigationPath<TestRoute>.create();
      final path2 = NavigationPath<TestRoute>.create();

      // Don't await push - it returns a Future that completes on pop
      path1.push(TestRoute('path1-home'));
      path2.push(TestRoute('path2-home'));

      // Start with path1
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path1, resolver: testResolver),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Route: path1-home'), findsOneWidget);
      expect(BuildTracker.getBuildCount('path1-home'), 1);

      // Swap to path2
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(path: path2, resolver: testResolver),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Route: path2-home'), findsOneWidget);
      expect(BuildTracker.getBuildCount('path2-home'), 1);
    });
  });

  group('NavigationStack - Page preservation', () {
    testWidgets('state is preserved when page is kept', (tester) async {
      final path = NavigationPath<TestRoute>();

      // Use a stateful counter widget
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationStack<TestRoute>(
            path: path,
            resolver: (route) => StackTransition.material(
              _CounterWidget(key: ValueKey(route.id)),
            ),
          ),
        ),
      );

      // Push initial route using push (not pushOrMoveToTop via defaultRoute)
      path.push(TestRoute('counter'));
      await tester.pumpAndSettle();

      // Increment counter
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Count: 1'), findsOneWidget);

      // Push new route (don't await)
      path.push(TestRoute('other'));
      await tester.pumpAndSettle();

      // Pop back
      path.pop();
      await tester.pumpAndSettle();

      // Counter state should be preserved (still 1)
      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('DeclarativeNavigationStack - Diff-based updates', () {
    testWidgets('updates pages using diff when routes change', (tester) async {
      var routes = [TestRoute('a'), TestRoute('b')];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        routes = [
                          TestRoute('a'),
                          TestRoute('c'),
                          TestRoute('b'),
                        ];
                      });
                    },
                    child: const Text('Update'),
                  ),
                  Expanded(
                    child: NavigationStack.declarative<TestRoute>(
                      routes: routes,
                      resolver: testResolver,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('a'), 1);
      expect(BuildTracker.getBuildCount('b'), 1);
      expect(BuildTracker.getBuildCount('c'), 0);

      // Update routes
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // 'a' and 'b' should be reused, 'c' is new
      expect(BuildTracker.getBuildCount('a'), 1);
      expect(BuildTracker.getBuildCount('b'), 1);
      expect(BuildTracker.getBuildCount('c'), 1);
    });

    testWidgets('handles complete route replacement', (tester) async {
      var routes = [TestRoute('old1'), TestRoute('old2')];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        routes = [TestRoute('new1'), TestRoute('new2')];
                      });
                    },
                    child: const Text('Replace'),
                  ),
                  Expanded(
                    child: NavigationStack.declarative<TestRoute>(
                      routes: routes,
                      resolver: testResolver,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('old1'), 1);
      expect(BuildTracker.getBuildCount('old2'), 1);

      // Replace all routes
      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();

      expect(BuildTracker.getBuildCount('new1'), 1);
      expect(BuildTracker.getBuildCount('new2'), 1);

      // Old routes should be disposed
      expect(BuildTracker.isActive('old1'), isFalse);
      expect(BuildTracker.isActive('old2'), isFalse);
    });
  });
}

// Helper widget for testing state preservation
class _CounterWidget extends StatefulWidget {
  const _CounterWidget({super.key});

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
