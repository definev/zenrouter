import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Test Routes
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: Text(toString()));
  }

  @override
  List<Object?> get props => [];
}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  @override
  String toString() => 'HomeRoute';
}

class ShopHomeRoute extends AppRoute {
  @override
  Type get layout => ShopLayout;
  @override
  Uri toUri() => Uri.parse('/shop');
  @override
  String toString() => 'ShopHomeRoute';
}

class ShopProductRoute extends AppRoute {
  ShopProductRoute({required this.id});
  final String id;

  @override
  Type get layout => ShopLayout;
  @override
  Uri toUri() => Uri.parse('/shop/products/$id');
  @override
  String toString() => 'ShopProductRoute(id: $id)';
  @override
  List<Object?> get props => [id];
}

class SettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings');
  @override
  String toString() => 'SettingsRoute';
}

class SettingsDetailRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings/detail');
  @override
  String toString() => 'SettingsDetailRoute';
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});
  final Uri uri;

  @override
  Uri toUri() => Uri.parse('/not-found');
  @override
  String toString() => 'NotFoundRoute(uri: $uri)';
  @override
  List<Object?> get props => [uri];
}

/// A simple route with no layout dependency — safe for standalone coordinators.
class StandalonePageRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/standalone-page');
  @override
  String toString() => 'StandalonePageRoute';
}

// --- Nested CoordinatorModular routes ---

class BlogHomeRoute extends AppRoute {
  @override
  Type get layout => BlogLayout;
  @override
  Uri toUri() => Uri.parse('/blog');
  @override
  String toString() => 'BlogHomeRoute';
}

class BlogPostRoute extends AppRoute {
  BlogPostRoute({required this.slug});
  final String slug;

  @override
  Type get layout => BlogLayout;
  @override
  Uri toUri() => Uri.parse('/blog/posts/$slug');
  @override
  String toString() => 'BlogPostRoute(slug: $slug)';
  @override
  List<Object?> get props => [slug];
}

class BlogCommentRoute extends AppRoute {
  BlogCommentRoute({required this.postSlug});
  final String postSlug;

  @override
  Type get layout => BlogLayout;
  @override
  Uri toUri() => Uri.parse('/blog/posts/$postSlug/comments');
  @override
  String toString() => 'BlogCommentRoute(postSlug: $postSlug)';
  @override
  List<Object?> get props => [postSlug];
}

// ============================================================================
// Test Layouts
// ============================================================================

class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(
    covariant CoordinatorModular<AppRoute> coordinator,
  ) {
    final module = coordinator.getModule<ShopCoordinator>();
    return module.shopStack;
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: buildPath(coordinator));
  }
}

class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(
    covariant CoordinatorModular<AppRoute> coordinator,
  ) {
    final module = coordinator.getModule<SettingsCoordinator>();
    return module.settingsStack;
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: buildPath(coordinator));
  }
}

class BlogLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(
    covariant CoordinatorModular<AppRoute> coordinator,
  ) {
    final module = coordinator.getModule<BlogCoordinator>();
    return module.blogStack;
  }

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(body: buildPath(coordinator));
  }
}

// ============================================================================
// Child Coordinators used as RouteModules
// ============================================================================

/// A Coordinator that is used as a RouteModule inside a parent
/// CoordinatorModular. It overrides `coordinator` to point to the parent.
class ShopCoordinator extends Coordinator<AppRoute> {
  ShopCoordinator(this._parent);
  final CoordinatorModular<AppRoute> _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopStack = NavigationPath.createWith(
    label: 'shop',
    coordinator: _parent,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ShopProductRoute(id: id),
      _ => null,
    };
  }
}

class SettingsCoordinator extends Coordinator<AppRoute> {
  SettingsCoordinator(this._parent);
  final TestParentCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> settingsStack = NavigationPath.createWith(
    label: 'settings',
    coordinator: _parent,
  );

  @override
  List<StackPath> get paths => [...super.paths, settingsStack];

  @override
  void defineLayout() {
    defineRouteLayout(SettingsLayout, SettingsLayout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['settings'] => SettingsRoute(),
      ['settings', 'detail'] => SettingsDetailRoute(),
      _ => null,
    };
  }
}

// ============================================================================
// Parent Coordinator — composes child coordinators as modules
// ============================================================================

class TestParentCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    TestMainRouteModule(this),
    ShopCoordinator(this),
    SettingsCoordinator(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

// ============================================================================
// Nested CoordinatorModular — a CoordinatorModular used as RouteModule
// ============================================================================

/// A Coordinator that is itself a CoordinatorModular AND acts as a RouteModule
/// of a grandparent CoordinatorModular. It has its own child modules.
class BlogCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  BlogCoordinator(this._grandParent);
  final NestedGrandParentCoordinator _grandParent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _grandParent;

  late final NavigationPath<AppRoute> blogStack = NavigationPath.createWith(
    label: 'blog',
    coordinator: _grandParent,
  );

  @override
  List<StackPath> get paths => [...super.paths, blogStack];

  @override
  void defineLayout() {
    super.defineLayout();
    defineRouteLayout(BlogLayout, BlogLayout.new);
  }

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    BlogPostsModule(this),
    BlogCommentsModule(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class BlogPostsModule extends RouteModule<AppRoute> {
  BlogPostsModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['blog'] => BlogHomeRoute(),
      ['blog', 'posts', final slug] => BlogPostRoute(slug: slug),
      _ => null,
    };
  }
}

class BlogCommentsModule extends RouteModule<AppRoute> {
  BlogCommentsModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['blog', 'posts', final slug, 'comments'] => BlogCommentRoute(
        postSlug: slug,
      ),
      _ => null,
    };
  }
}

/// The top-level grandparent that contains both regular modules
/// and a nested CoordinatorModular (BlogCoordinator).
class NestedGrandParentCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    TestMainRouteModule(this),
    ShopCoordinator(this),
    BlogCoordinator(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class TestMainRouteModule extends RouteModule<AppRoute> {
  TestMainRouteModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      _ => null,
    };
  }
}

// ============================================================================
// Standalone Coordinator — does NOT override `coordinator` getter
// ============================================================================

/// A standalone coordinator that always returns a route from parseRouteFromUri.
/// The assert in setNewRoutePath should pass because route is non-null.
class StandaloneCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['standalone-page'] => StandalonePageRoute(),
      _ => HomeRoute(),
    };
  }
}

/// A standalone coordinator that returns null from parseRouteFromUri for
/// unknown URIs. This should trigger the assert in setNewRoutePath.
class StandaloneNullReturningCoordinator extends Coordinator<AppRoute> {
  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      _ => null, // Returns null for unknown routes
    };
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('Coordinator as RouteModule', () {
    group('coordinator getter', () {
      test(
        'standalone coordinator throws UnimplementedError when accessing coordinator getter',
        () {
          final coordinator = StandaloneCoordinator();

          expect(
            () => coordinator.coordinator,
            throwsA(
              isA<UnimplementedError>().having(
                (e) => e.message,
                'message',
                contains('This coordinator is standalone'),
              ),
            ),
          );
        },
      );

      test(
        'child coordinator returns parent when coordinator getter is overridden',
        () {
          final parent = TestParentCoordinator();
          final shopCoordinator = parent.getModule<ShopCoordinator>();

          expect(shopCoordinator.coordinator, equals(parent));
        },
      );

      test('all child coordinators point to the same parent', () {
        final parent = TestParentCoordinator();
        final shopCoordinator = parent.getModule<ShopCoordinator>();
        final settingsCoordinator = parent.getModule<SettingsCoordinator>();

        expect(shopCoordinator.coordinator, same(parent));
        expect(settingsCoordinator.coordinator, same(parent));
      });
    });

    group('isRouteModule', () {
      test('standalone coordinator returns false', () {
        final coordinator = StandaloneCoordinator();

        expect(coordinator.isRouteModule, isFalse);
      });

      test('child coordinator returns true', () {
        final parent = TestParentCoordinator();
        final shopCoordinator = parent.getModule<ShopCoordinator>();

        expect(shopCoordinator.isRouteModule, isTrue);
      });
    });

    group('root', () {
      test('standalone coordinator creates its own root NavigationPath', () {
        final coordinator = StandaloneCoordinator();

        expect(coordinator.root, isA<NavigationPath<AppRoute>>());
        expect(coordinator.root.debugLabel, equals('root'));
      });

      test('child coordinator root points to parent root (same instance)', () {
        final parent = TestParentCoordinator();
        final shopCoordinator = parent.getModule<ShopCoordinator>();
        final settingsCoordinator = parent.getModule<SettingsCoordinator>();

        expect(shopCoordinator.root, same(parent.root));
        expect(settingsCoordinator.root, same(parent.root));
      });

      test('child coordinator paths does not include root', () {
        final parent = TestParentCoordinator();
        final shopCoordinator = parent.getModule<ShopCoordinator>();

        // When isRouteModule is true, paths returns [] (no root)
        // Only the custom shopStack is added by the child's override
        expect(shopCoordinator.paths, isNot(contains(parent.root)));
      });

      test('standalone coordinator paths includes its own root', () {
        final coordinator = StandaloneCoordinator();

        expect(coordinator.paths, contains(coordinator.root));
      });
    });

    group('Module Registration', () {
      test('child coordinators are registered as modules', () {
        final parent = TestParentCoordinator();

        expect(parent.getModule<ShopCoordinator>(), isA<ShopCoordinator>());
        expect(
          parent.getModule<SettingsCoordinator>(),
          isA<SettingsCoordinator>(),
        );
      });

      test('child coordinator modules are singletons within parent', () {
        final parent = TestParentCoordinator();

        final shop1 = parent.getModule<ShopCoordinator>();
        final shop2 = parent.getModule<ShopCoordinator>();

        expect(identical(shop1, shop2), isTrue);
      });

      test('child coordinators are also Coordinator instances', () {
        final parent = TestParentCoordinator();

        final shopModule = parent.getModule<ShopCoordinator>();
        expect(shopModule, isA<Coordinator<AppRoute>>());
        expect(shopModule, isA<RouteModule<AppRoute>>());
      });
    });

    group('Route Parsing delegation', () {
      test('parent delegates to child coordinator for route parsing', () async {
        final parent = TestParentCoordinator();

        final route = await parent.parseRouteFromUri(Uri.parse('/shop'));
        expect(route, isA<ShopHomeRoute>());
      });

      test('parent delegates to correct child for each route', () async {
        final parent = TestParentCoordinator();

        final shopRoute = await parent.parseRouteFromUri(Uri.parse('/shop'));
        expect(shopRoute, isA<ShopHomeRoute>());

        final settingsRoute = await parent.parseRouteFromUri(
          Uri.parse('/settings'),
        );
        expect(settingsRoute, isA<SettingsRoute>());

        final homeRoute = await parent.parseRouteFromUri(Uri.parse('/'));
        expect(homeRoute, isA<HomeRoute>());
      });

      test('child coordinator parses routes with parameters', () async {
        final parent = TestParentCoordinator();

        final route = await parent.parseRouteFromUri(
          Uri.parse('/shop/products/42'),
        );
        expect(route, isA<ShopProductRoute>());
        expect((route as ShopProductRoute).id, equals('42'));
      });

      test('notFoundRoute is returned when no child handles the URI', () async {
        final parent = TestParentCoordinator();

        final route = await parent.parseRouteFromUri(
          Uri.parse('/unknown/path'),
        );
        expect(route, isA<NotFoundRoute>());
      });
    });

    group('Path Aggregation', () {
      test('parent aggregates paths from child coordinators', () {
        final parent = TestParentCoordinator();
        final shopCoordinator = parent.getModule<ShopCoordinator>();
        final settingsCoordinator = parent.getModule<SettingsCoordinator>();

        final paths = parent.paths;
        expect(paths, contains(parent.root));
        expect(paths, contains(shopCoordinator.shopStack));
        expect(paths, contains(settingsCoordinator.settingsStack));
      });

      test('child coordinator paths are independently addressable', () {
        final parent = TestParentCoordinator();
        final shopCoordinator = parent.getModule<ShopCoordinator>();
        final settingsCoordinator = parent.getModule<SettingsCoordinator>();

        expect(
          shopCoordinator.shopStack,
          isNot(same(settingsCoordinator.settingsStack)),
        );
        expect(shopCoordinator.shopStack.debugLabel, equals('shop'));
        expect(
          settingsCoordinator.settingsStack.debugLabel,
          equals('settings'),
        );
      });
    });

    group('Layout Definition delegation', () {
      test('child coordinator layouts are registered via parent', () {
        var shopLayoutCalled = false;
        var settingsLayoutCalled = false;

        _LayoutTrackingParent(
          onShopLayout: () => shopLayoutCalled = true,
          onSettingsLayout: () => settingsLayoutCalled = true,
        );

        expect(shopLayoutCalled, isTrue);
        expect(settingsLayoutCalled, isTrue);
      });
    });

    group('Converter Definition delegation', () {
      test('child coordinator converters are registered via parent', () {
        var shopConverterCalled = false;
        var settingsConverterCalled = false;

        _ConverterTrackingParent(
          onShopConverter: () => shopConverterCalled = true,
          onSettingsConverter: () => settingsConverterCalled = true,
        );

        expect(shopConverterCalled, isTrue);
        expect(settingsConverterCalled, isTrue);
      });
    });

    group('Navigation via parent', () {
      test('push route into child coordinator path', () async {
        final parent = TestParentCoordinator();

        parent.push(ShopHomeRoute());
        await Future.delayed(Duration.zero);

        final shopCoordinator = parent.getModule<ShopCoordinator>();
        expect(shopCoordinator.shopStack.stack, contains(isA<ShopHomeRoute>()));
      });

      test('push routes into different child coordinator paths', () async {
        final parent = TestParentCoordinator();

        await parent.replace(ShopHomeRoute());
        final shopCoordinator = parent.getModule<ShopCoordinator>();
        expect(shopCoordinator.shopStack.stack.last, isA<ShopHomeRoute>());

        await parent.replace(SettingsRoute());
        final settingsCoordinator = parent.getModule<SettingsCoordinator>();
        expect(
          settingsCoordinator.settingsStack.stack.last,
          isA<SettingsRoute>(),
        );
      });

      test('cross-coordinator navigation works', () async {
        final parent = TestParentCoordinator();

        // Start in shop
        parent.replace(ShopHomeRoute());
        await Future.delayed(Duration.zero);
        final shopCoordinator = parent.getModule<ShopCoordinator>();
        expect(shopCoordinator.shopStack.stack.last, isA<ShopHomeRoute>());

        // Navigate to settings (different child coordinator)
        parent.push(SettingsRoute());
        await Future.delayed(Duration.zero);
        final settingsCoordinator = parent.getModule<SettingsCoordinator>();
        expect(
          settingsCoordinator.settingsStack.stack.last,
          isA<SettingsRoute>(),
        );
      });
    });
  });

  group('Router assert — standalone coordinator', () {
    test(
      'standalone coordinator that always returns non-null passes assert',
      () async {
        final coordinator = StandaloneCoordinator();

        // Should not throw — route is non-null for a standalone coordinator
        await expectLater(
          coordinator.routerDelegate.setNewRoutePath(Uri.parse('/')),
          completes,
        );
      },
    );

    test(
      'standalone coordinator returning null for unknown URI triggers assert',
      () async {
        final coordinator = StandaloneNullReturningCoordinator();

        // The assert checks: if coordinator is standalone (throws
        // UnimplementedError with 'This coordinator is standalone') AND
        // route is null, the assert fails.
        expect(
          () => coordinator.routerDelegate.setNewRoutePath(
            Uri.parse('/unknown/path'),
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    testWidgets(
      'standalone coordinator navigation works when route is non-null',
      (tester) async {
        final coordinator = StandaloneCoordinator();

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: coordinator.routerDelegate,
            routeInformationParser: coordinator.routeInformationParser,
          ),
        );

        coordinator.replace(HomeRoute());
        await tester.pumpAndSettle();

        expect(find.text('HomeRoute'), findsOneWidget);

        // Navigate via setNewRoutePath — assert should pass
        await coordinator.routerDelegate.setNewRoutePath(
          Uri.parse('/standalone-page'),
        );
        await tester.pumpAndSettle();

        expect(coordinator.root.stack.last, isA<StandalonePageRoute>());
      },
    );
  });

  group('Router assert — Coordinator as RouteModule (child coordinator)', () {
    test(
      'child coordinator does not trigger standalone assert (has parent)',
      () async {
        final parent = TestParentCoordinator();

        // The coordinator.coordinator getter does NOT throw
        // UnimplementedError, so the assert always passes regardless of
        // whether route is null.
        await expectLater(
          parent.routerDelegate.setNewRoutePath(Uri.parse('/shop')),
          completes,
        );
      },
    );

    test(
      'child coordinator with unknown route falls through to notFoundRoute',
      () async {
        final parent = TestParentCoordinator();

        // Parent has notFoundRoute so it always returns non-null.
        // The assert passes because coordinator.coordinator does NOT throw.
        await expectLater(
          parent.routerDelegate.setNewRoutePath(Uri.parse('/unknown')),
          completes,
        );
      },
    );

    testWidgets('full router flow with child coordinator modules', (
      tester,
    ) async {
      final parent = TestParentCoordinator();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: parent.routerDelegate,
          routeInformationParser: parent.routeInformationParser,
        ),
      );

      parent.replace(HomeRoute());
      await tester.pumpAndSettle();
      expect(find.text('HomeRoute'), findsOneWidget);

      // Navigate to shop (handled by ShopCoordinator module)
      await parent.routerDelegate.setNewRoutePath(Uri.parse('/shop'));
      await tester.pumpAndSettle();

      final shopCoordinator = parent.getModule<ShopCoordinator>();
      expect(shopCoordinator.shopStack.stack.last, isA<ShopHomeRoute>());

      // Navigate to settings (handled by SettingsCoordinator module)
      await parent.routerDelegate.setNewRoutePath(Uri.parse('/settings'));
      await tester.pumpAndSettle();

      final settingsCoordinator = parent.getModule<SettingsCoordinator>();
      expect(
        settingsCoordinator.settingsStack.stack.last,
        isA<SettingsRoute>(),
      );
    });
  });

  group('Nested CoordinatorModular (CoordinatorModular as RouteModule)', () {
    group('isRouteModule and root', () {
      test('nested CoordinatorModular has isRouteModule == true', () {
        final grandParent = NestedGrandParentCoordinator();
        final blogCoordinator = grandParent.getModule<BlogCoordinator>();

        expect(blogCoordinator.isRouteModule, isTrue);
      });

      test('nested CoordinatorModular root points to grandparent root', () {
        final grandParent = NestedGrandParentCoordinator();
        final blogCoordinator = grandParent.getModule<BlogCoordinator>();

        expect(blogCoordinator.root, same(grandParent.root));
      });

      test('grandparent isRouteModule is false (it is standalone)', () {
        final grandParent = NestedGrandParentCoordinator();

        expect(grandParent.isRouteModule, isFalse);
      });
    });

    group('Route Parsing cascading', () {
      test(
        'grandparent delegates to nested CoordinatorModular for route parsing',
        () async {
          final grandParent = NestedGrandParentCoordinator();

          final blogHome = await grandParent.parseRouteFromUri(
            Uri.parse('/blog'),
          );
          expect(blogHome, isA<BlogHomeRoute>());
        },
      );

      test(
        'grandparent cascades through nested CoordinatorModular to its child modules',
        () async {
          final grandParent = NestedGrandParentCoordinator();

          final blogPost = await grandParent.parseRouteFromUri(
            Uri.parse('/blog/posts/hello-world'),
          );
          expect(blogPost, isA<BlogPostRoute>());
          expect((blogPost as BlogPostRoute).slug, equals('hello-world'));

          final blogComment = await grandParent.parseRouteFromUri(
            Uri.parse('/blog/posts/hello-world/comments'),
          );
          expect(blogComment, isA<BlogCommentRoute>());
          expect(
            (blogComment as BlogCommentRoute).postSlug,
            equals('hello-world'),
          );
        },
      );

      test(
        'routes from sibling modules of the grandparent still work',
        () async {
          final grandParent = NestedGrandParentCoordinator();

          final homeRoute = await grandParent.parseRouteFromUri(Uri.parse('/'));
          expect(homeRoute, isA<HomeRoute>());

          final shopRoute = await grandParent.parseRouteFromUri(
            Uri.parse('/shop'),
          );
          expect(shopRoute, isA<ShopHomeRoute>());
        },
      );

      test(
        'unknown URI falls through all levels to grandparent notFoundRoute',
        () async {
          final grandParent = NestedGrandParentCoordinator();

          final route = await grandParent.parseRouteFromUri(
            Uri.parse('/completely/unknown'),
          );
          expect(route, isA<NotFoundRoute>());
        },
      );
    });

    group('Path Aggregation across levels', () {
      test('grandparent aggregates paths from all levels', () {
        final grandParent = NestedGrandParentCoordinator();
        final shopCoordinator = grandParent.getModule<ShopCoordinator>();
        final blogCoordinator = grandParent.getModule<BlogCoordinator>();

        final paths = grandParent.paths;
        expect(paths, contains(grandParent.root));
        expect(paths, contains(shopCoordinator.shopStack));
        expect(paths, contains(blogCoordinator.blogStack));
      });
    });

    group('Navigation via grandparent to nested module', () {
      test(
        'push route handled by nested CoordinatorModular child module',
        () async {
          final grandParent = NestedGrandParentCoordinator();

          await grandParent.replace(BlogHomeRoute());

          final blogCoordinator = grandParent.getModule<BlogCoordinator>();
          expect(blogCoordinator.blogStack.stack.last, isA<BlogHomeRoute>());
        },
      );

      test('push route with parameters through nested modules', () async {
        final grandParent = NestedGrandParentCoordinator();

        await grandParent.replace(BlogPostRoute(slug: 'my-post'));

        final blogCoordinator = grandParent.getModule<BlogCoordinator>();
        expect(blogCoordinator.blogStack.stack.last, isA<BlogPostRoute>());
      });

      test(
        'cross-module navigation between sibling and nested CoordinatorModular',
        () async {
          final grandParent = NestedGrandParentCoordinator();

          // Navigate to shop (sibling module)
          await grandParent.replace(ShopHomeRoute());
          final shopCoordinator = grandParent.getModule<ShopCoordinator>();
          expect(shopCoordinator.shopStack.stack.last, isA<ShopHomeRoute>());

          // Navigate to blog (nested CoordinatorModular module)
          await grandParent.replace(BlogHomeRoute());
          final blogCoordinator = grandParent.getModule<BlogCoordinator>();
          expect(blogCoordinator.blogStack.stack.last, isA<BlogHomeRoute>());
        },
      );
    });

    group('Layout Definition in nested CoordinatorModular', () {
      test(
        'nested CoordinatorModular layouts are registered via grandparent',
        () {
          var blogLayoutCalled = false;

          _NestedLayoutTrackingGrandParent(
            onBlogLayout: () => blogLayoutCalled = true,
          );

          expect(blogLayoutCalled, isTrue);
        },
      );
    });
  });
}

// ============================================================================
// Test Helper Coordinators
// ============================================================================

class _LayoutTrackingShopCoordinator extends Coordinator<AppRoute> {
  _LayoutTrackingShopCoordinator(this._parent, {required this.onLayout});
  final _LayoutTrackingParent _parent;
  final VoidCallback onLayout;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() => onLayout();
}

class _LayoutTrackingSettingsCoordinator extends Coordinator<AppRoute> {
  _LayoutTrackingSettingsCoordinator(this._parent, {required this.onLayout});
  final _LayoutTrackingParent _parent;
  final VoidCallback onLayout;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() => onLayout();
}

class _LayoutTrackingParent extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  _LayoutTrackingParent({
    required this.onShopLayout,
    required this.onSettingsLayout,
  });

  final VoidCallback onShopLayout;
  final VoidCallback onSettingsLayout;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    _LayoutTrackingShopCoordinator(this, onLayout: onShopLayout),
    _LayoutTrackingSettingsCoordinator(this, onLayout: onSettingsLayout),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class _ConverterTrackingShopCoordinator extends Coordinator<AppRoute> {
  _ConverterTrackingShopCoordinator(this._parent, {required this.onConverter});
  final _ConverterTrackingParent _parent;
  final VoidCallback onConverter;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineConverter() => onConverter();
}

class _ConverterTrackingSettingsCoordinator extends Coordinator<AppRoute> {
  _ConverterTrackingSettingsCoordinator(
    this._parent, {
    required this.onConverter,
  });
  final _ConverterTrackingParent _parent;
  final VoidCallback onConverter;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineConverter() => onConverter();
}

class _ConverterTrackingParent extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  _ConverterTrackingParent({
    required this.onShopConverter,
    required this.onSettingsConverter,
  });

  final VoidCallback onShopConverter;
  final VoidCallback onSettingsConverter;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    _ConverterTrackingShopCoordinator(this, onConverter: onShopConverter),
    _ConverterTrackingSettingsCoordinator(
      this,
      onConverter: onSettingsConverter,
    ),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

// --- Nested layout tracking helpers ---

class _NestedLayoutTrackingBlogCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  _NestedLayoutTrackingBlogCoordinator(this._parent, {required this.onLayout});
  final _NestedLayoutTrackingGrandParent _parent;
  final VoidCallback onLayout;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  void defineLayout() => onLayout();

  @override
  Set<RouteModule<AppRoute>> defineModules() => {};

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class _NestedLayoutTrackingGrandParent extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  _NestedLayoutTrackingGrandParent({required this.onBlogLayout});

  final VoidCallback onBlogLayout;

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    _NestedLayoutTrackingBlogCoordinator(this, onLayout: onBlogLayout),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
