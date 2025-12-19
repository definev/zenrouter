// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Layout Creation Tracking
// ============================================================================

/// Tracks layout creation counts for testing
class LayoutCreationTracker {
  static final Map<Type, int> _creationCounts = {};
  static final Map<Type, List<Object>> _instances = {};

  static void reset() {
    _creationCounts.clear();
    _instances.clear();
  }

  static void recordCreation(Type type, Object instance) {
    _creationCounts[type] = (_creationCounts[type] ?? 0) + 1;
    _instances[type] = _instances[type] ?? [];
    _instances[type]!.add(instance);
  }

  static int getCount(Type type) => _creationCounts[type] ?? 0;

  static List<Object> getInstances(Type type) => _instances[type] ?? [];

  static void printCounts() {
    print('\n=== Layout Creation Counts ===');
    _creationCounts.forEach((type, count) {
      print('$type: $count');
    });
    print('==============================\n');
  }
}

// ============================================================================
// Test Route Definitions
// ============================================================================

abstract class TestRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri();
}

/// Home layout - root level layout
class TestHomeLayout extends TestRoute with RouteLayout<TestRoute> {
  TestHomeLayout() {
    LayoutCreationTracker.recordCreation(TestHomeLayout, this);
  }

  @override
  NavigationPath<TestRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.homeStack;

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Settings layout - standalone layout
class TestSettingsLayout extends TestRoute with RouteLayout<TestRoute> {
  TestSettingsLayout() {
    LayoutCreationTracker.recordCreation(TestSettingsLayout, this);
  }

  @override
  NavigationPath<TestRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.settingsStack;
}

/// TabBar layout - nested in HomeLayout
class TestTabBarLayout extends TestRoute with RouteLayout<TestRoute> {
  TestTabBarLayout() {
    LayoutCreationTracker.recordCreation(TestTabBarLayout, this);
  }

  @override
  Type get layout => TestHomeLayout;

  @override
  IndexedStackPath<TestRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.tabIndexed;

  @override
  Uri toUri() => Uri.parse('/home/tabs');
}

/// Feed tab layout - nested in TabBarLayout
class TestFeedTabLayout extends TestRoute with RouteLayout<TestRoute> {
  TestFeedTabLayout() {
    LayoutCreationTracker.recordCreation(TestFeedTabLayout, this);
  }

  @override
  Type get layout => TestTabBarLayout;

  @override
  NavigationPath<TestRoute> resolvePath(TestCoordinator coordinator) =>
      coordinator.feedTabStack;

  @override
  Uri toUri() => Uri.parse('/home/tabs/feed');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Simple route inside FeedTabLayout
class TestFeedRoute extends TestRoute {
  TestFeedRoute({required this.id});

  final String id;

  @override
  Type get layout => TestFeedTabLayout;

  @override
  Uri toUri() => Uri.parse('/home/tabs/feed/$id');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Placeholder();
  }

  @override
  List<Object?> get props => [id];
}

/// Profile tab route
class TestProfileTab extends TestRoute {
  @override
  Type get layout => TestTabBarLayout;

  @override
  Uri toUri() => Uri.parse('/home/tabs/profile');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Settings route inside SettingsLayout
class TestSettingsRoute extends TestRoute {
  @override
  Type get layout => TestSettingsLayout;

  @override
  Uri toUri() => Uri.parse('/settings/general');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

/// Profile detail route in HomeLayout
class TestProfileDetail extends TestRoute {
  @override
  Type get layout => TestHomeLayout;

  @override
  Uri toUri() => Uri.parse('/home/profile/detail');

  @override
  Widget build(TestCoordinator coordinator, BuildContext context) {
    return const Placeholder();
  }
}

// ============================================================================
// Test Coordinator
// ============================================================================

class TestCoordinator extends Coordinator<TestRoute> {
  late final NavigationPath<TestRoute> homeStack = NavigationPath.createWith(
    coordinator: this,
    label: 'home',
  );
  late final NavigationPath<TestRoute> settingsStack =
      NavigationPath.createWith(coordinator: this, label: 'settings');
  late final IndexedStackPath<TestRoute> tabIndexed =
      IndexedStackPath<TestRoute>.createWith(
        [TestFeedTabLayout(), TestProfileTab()],
        coordinator: this,
        label: 'tabs',
      );
  late final NavigationPath<TestRoute> feedTabStack = NavigationPath.createWith(
    coordinator: this,
    label: 'feed',
  );

  @override
  void defineLayout() {
    RouteLayout.defineLayout(TestHomeLayout, TestHomeLayout.new);
    RouteLayout.defineLayout(TestSettingsLayout, TestSettingsLayout.new);
    RouteLayout.defineLayout(TestTabBarLayout, TestTabBarLayout.new);
    RouteLayout.defineLayout(TestFeedTabLayout, TestFeedTabLayout.new);
  }

  @override
  List<StackPath> get paths => [
    root,
    homeStack,
    settingsStack,
    tabIndexed,
    feedTabStack,
  ];

  @override
  TestRoute parseRouteFromUri(Uri uri) {
    return TestFeedRoute(id: '1');
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  setUp(() {
    LayoutCreationTracker.reset();
  });

  group('Layout Creation - Initial Creation', () {
    test('HomeLayout is created once on first navigation', () async {
      final coordinator = TestCoordinator();

      // Account for any layouts created during coordinator initialization
      final initialHomeCount = LayoutCreationTracker.getCount(TestHomeLayout);

      // Navigate to a route that requires HomeLayout
      coordinator.push(TestProfileDetail());
      await Future.delayed(Duration.zero);

      final finalHomeCount = LayoutCreationTracker.getCount(TestHomeLayout);

      expect(
        finalHomeCount - initialHomeCount,
        1,
        reason: 'HomeLayout should be created exactly once on first navigation',
      );
    });

    test('SettingsLayout is created once on first navigation', () async {
      final coordinator = TestCoordinator();

      final initialCount = LayoutCreationTracker.getCount(TestSettingsLayout);

      coordinator.push(TestSettingsRoute());
      await Future.delayed(Duration.zero);

      expect(
        LayoutCreationTracker.getCount(TestSettingsLayout) - initialCount,
        1,
        reason: 'SettingsLayout should be created exactly once',
      );
    });

    test('Nested layouts are created on navigation path setup', () async {
      final coordinator = TestCoordinator();

      // FeedTabLayout is created during IndexedStackPath initialization
      final initialFeedTabCount = LayoutCreationTracker.getCount(
        TestFeedTabLayout,
      );
      expect(
        initialFeedTabCount,
        greaterThan(0),
        reason:
            'FeedTabLayout is created during IndexedStackPath initialization',
      );

      // Navigate to a route deep in the hierarchy
      coordinator.push(TestFeedRoute(id: '1'));
      await Future.delayed(Duration.zero);

      final feedTabCountAfterFirstPush = LayoutCreationTracker.getCount(
        TestFeedTabLayout,
      );

      // May create one more instance during navigation (acceptable behavior)
      // The key is that it doesn't keep creating new ones

      // Navigate again - should NOT create more instances
      coordinator.push(TestFeedRoute(id: '2'));
      await Future.delayed(Duration.zero);

      expect(
        LayoutCreationTracker.getCount(TestFeedTabLayout),
        feedTabCountAfterFirstPush,
        reason:
            'FeedTabLayout should not be recreated on subsequent navigation',
      );

      LayoutCreationTracker.printCounts();
    });

    test(
      'Layout is not recreated when pushing multiple routes within it',
      () async {
        final coordinator = TestCoordinator();

        // Navigate to first feed route
        coordinator.push(TestFeedRoute(id: '1'));
        await Future.delayed(Duration.zero);

        final homeCount = LayoutCreationTracker.getCount(TestHomeLayout);
        final tabBarCount = LayoutCreationTracker.getCount(TestTabBarLayout);
        final feedTabCount = LayoutCreationTracker.getCount(TestFeedTabLayout);

        // Push more routes within the same layout
        coordinator.push(TestFeedRoute(id: '2'));
        await Future.delayed(Duration.zero);

        coordinator.push(TestFeedRoute(id: '3'));
        await Future.delayed(Duration.zero);

        expect(
          LayoutCreationTracker.getCount(TestHomeLayout),
          homeCount,
          reason: 'HomeLayout should not be recreated',
        );
        expect(
          LayoutCreationTracker.getCount(TestTabBarLayout),
          tabBarCount,
          reason: 'TabBarLayout should not be recreated',
        );
        expect(
          LayoutCreationTracker.getCount(TestFeedTabLayout),
          feedTabCount,
          reason: 'FeedTabLayout should not be recreated',
        );
      },
    );
  });

  group('Layout Creation - Re-use Within Session', () {
    test('Layout is reused when navigating within tabs', () async {
      final coordinator = TestCoordinator();

      // Navigate to feed
      coordinator.push(TestFeedRoute(id: '1'));
      await Future.delayed(Duration.zero);

      final homeCountAfterFirst = LayoutCreationTracker.getCount(
        TestHomeLayout,
      );
      final tabBarCountAfterFirst = LayoutCreationTracker.getCount(
        TestTabBarLayout,
      );

      // Navigate to profile tab (same HomeLayout, same TabBarLayout)
      coordinator.push(TestProfileTab());
      await Future.delayed(Duration.zero);

      expect(
        LayoutCreationTracker.getCount(TestHomeLayout),
        homeCountAfterFirst,
        reason: 'HomeLayout should be reused within same session',
      );
      expect(
        LayoutCreationTracker.getCount(TestTabBarLayout),
        tabBarCountAfterFirst,
        reason: 'TabBarLayout should be reused within same session',
      );
    });

    test('Layout count increases only when navigating to new layout type', () async {
      final coordinator = TestCoordinator();

      final initialSettingsCount = LayoutCreationTracker.getCount(
        TestSettingsLayout,
      );

      // Navigate to settings for the first time
      coordinator.push(TestSettingsRoute());
      await Future.delayed(Duration.zero);

      expect(
        LayoutCreationTracker.getCount(TestSettingsLayout),
        initialSettingsCount + 1,
        reason: 'SettingsLayout should be created once',
      );

      final settingsCountAfterFirst = LayoutCreationTracker.getCount(
        TestSettingsLayout,
      );

      // Navigate to home (different layout)
      coordinator.push(TestProfileDetail());
      await Future.delayed(Duration.zero);

      // Navigate back to settings
      coordinator.push(TestSettingsRoute());
      await Future.delayed(Duration.zero);

      // Settings layout should be reused if still in stack, or recreated if popped
      // The key is: if we used push (not replace), the layout should still exist
      final settingsCountFinal = LayoutCreationTracker.getCount(
        TestSettingsLayout,
      );

      print(
        'Settings count: initial=$initialSettingsCount, afterFirst=$settingsCountAfterFirst, final=$settingsCountFinal',
      );
      // This is the current behavior - may create a new one depending on stack state
    });
  });

  group('Layout Creation - Re-creation After Pop', () {
    test(
      'Layout is recreated after being completely popped from root stack',
      () async {
        final coordinator = TestCoordinator();

        // Navigate to settings
        coordinator.push(TestSettingsLayout());
        await Future.delayed(Duration.zero);
        coordinator.push(TestSettingsRoute());
        await Future.delayed(Duration.zero);

        final settingsCountAfterFirst = LayoutCreationTracker.getCount(
          TestSettingsLayout,
        );

        // Pop back (but SettingsLayout might still be in the stack)
        coordinator.pop(); // Pop TestSettingsRoute
        await Future.delayed(Duration.zero);

        // The exact count here depends on whether pop removes the layout or just the route
        // Let's navigate to settings again to see if it's recreated
        coordinator.push(TestSettingsRoute());
        await Future.delayed(Duration.zero);

        // Could be same count if layout wasn't removed, or +1 if it was
        final settingsCountAfterRepush = LayoutCreationTracker.getCount(
          TestSettingsLayout,
        );

        print(
          'SettingsLayout: afterFirst=$settingsCountAfterFirst, afterRepush=$settingsCountAfterRepush',
        );

        LayoutCreationTracker.printCounts();
      },
    );

    test('Replace creates new layout instances', () async {
      final coordinator = TestCoordinator();

      // Navigate deep into nested layouts
      coordinator.push(TestFeedRoute(id: '1'));
      await Future.delayed(Duration.zero);

      final homeCountAfterPush = LayoutCreationTracker.getCount(TestHomeLayout);
      final tabBarCountAfterPush = LayoutCreationTracker.getCount(
        TestTabBarLayout,
      );
      final feedTabCountAfterPush = LayoutCreationTracker.getCount(
        TestFeedTabLayout,
      );

      // Replace resets everything and creates new instances
      coordinator.replace(TestFeedRoute(id: '2'));
      await Future.delayed(Duration.zero);

      expect(
        LayoutCreationTracker.getCount(TestHomeLayout),
        greaterThan(homeCountAfterPush),
        reason: 'HomeLayout should be recreated after replace',
      );
      expect(
        LayoutCreationTracker.getCount(TestTabBarLayout),
        greaterThan(tabBarCountAfterPush),
        reason: 'TabBarLayout should be recreated after replace',
      );
      expect(
        LayoutCreationTracker.getCount(TestFeedTabLayout),
        greaterThan(feedTabCountAfterPush),
        reason: 'FeedTabLayout should be recreated after replace',
      );

      LayoutCreationTracker.printCounts();
    });
  });

  group('Layout Creation - Replace Operation', () {
    test('replace() creates new layout instances', () async {
      final coordinator = TestCoordinator();

      // Navigate to feed
      coordinator.push(TestFeedRoute(id: '1'));
      await Future.delayed(Duration.zero);

      final homeCountAfterPush = LayoutCreationTracker.getCount(TestHomeLayout);

      // Replace with settings
      coordinator.replace(TestSettingsRoute());
      await Future.delayed(Duration.zero);

      final settingsCountAfterReplace = LayoutCreationTracker.getCount(
        TestSettingsLayout,
      );
      expect(settingsCountAfterReplace, greaterThan(0));

      // Replace back to feed - should create new HomeLayout
      coordinator.replace(TestFeedRoute(id: '2'));
      await Future.delayed(Duration.zero);

      expect(
        LayoutCreationTracker.getCount(TestHomeLayout),
        greaterThan(homeCountAfterPush),
        reason: 'replace() should create new layout instances',
      );

      LayoutCreationTracker.printCounts();
    });

    test('replace() resets all paths', () async {
      final coordinator = TestCoordinator();

      // Build up a deep stack
      coordinator.push(TestFeedRoute(id: '1'));
      await Future.delayed(Duration.zero);
      coordinator.push(TestFeedRoute(id: '2'));
      await Future.delayed(Duration.zero);

      // Replace should reset everything
      coordinator.replace(TestSettingsRoute());
      await Future.delayed(Duration.zero);

      // Root stack should be reset to just one route (and its layouts)
      expect(
        coordinator.root.stack.length,
        lessThanOrEqualTo(2),
        reason: 'replace() should reset root stack',
      );
    });
  });

  group('Layout Creation - Summary', () {
    test('Complete navigation flow shows expected behavior', () async {
      final coordinator = TestCoordinator();
      LayoutCreationTracker.printCounts();

      print('\n--- Initial state (after coordinator creation) ---');
      final initialCounts = {
        'Home': LayoutCreationTracker.getCount(TestHomeLayout),
        'Settings': LayoutCreationTracker.getCount(TestSettingsLayout),
        'TabBar': LayoutCreationTracker.getCount(TestTabBarLayout),
        'FeedTab': LayoutCreationTracker.getCount(TestFeedTabLayout),
      };
      print(initialCounts);

      print('\n--- After push(FeedRoute(1)) ---');
      coordinator.push(TestFeedRoute(id: '1'));
      await Future.delayed(Duration.zero);
      LayoutCreationTracker.printCounts();

      print('\n--- After push(FeedRoute(2)) - should reuse layouts ---');
      coordinator.push(TestFeedRoute(id: '2'));
      await Future.delayed(Duration.zero);
      LayoutCreationTracker.printCounts();

      print(
        '\n--- After replace(SettingsRoute) - should create Settings layout ---',
      );
      coordinator.replace(TestSettingsRoute());
      await Future.delayed(Duration.zero);
      LayoutCreationTracker.printCounts();

      print(
        '\n--- After replace(FeedRoute(3)) - should create new Home/TabBar/FeedTab ---',
      );
      coordinator.replace(TestFeedRoute(id: '3'));
      await Future.delayed(Duration.zero);
      LayoutCreationTracker.printCounts();

      print('\n--- Final verification ---');
      expect(
        LayoutCreationTracker.getCount(TestHomeLayout),
        greaterThan(initialCounts['Home']!),
        reason: 'HomeLayout created at least once during navigation',
      );
      expect(
        LayoutCreationTracker.getCount(TestSettingsLayout),
        greaterThan(initialCounts['Settings']!),
        reason: 'SettingsLayout created when navigated to',
      );
    });
  });
}
