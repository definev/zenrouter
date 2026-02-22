import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_nocterm/zenrouter_nocterm.dart';

// ============================================================================
// Main App Entry Point
// ============================================================================
//
// This example demonstrates Coordinator-as-RouteModule with ROUTE VERSIONING
// and NESTED CoordinatorModular — ported to nocterm (terminal UI).
//
// Architecture:
//
//   MainCoordinator (CoordinatorModular)
//   ├── MainRouteModule          ← handles / (redirects to V2 shop)
//   ├── ShopCoordinatorV1        ← deprecated shop (/v1/shop/...)
//   │   └── ShopV1Layout (sidebar + deprecation banner)
//   │       ├── /v1/shop          → ShopHomeV1
//   │       ├── /v1/shop/products → ProductListV1
//   │       └── /v1/shop/cart     → CartV1
//   ├── ShopCoordinatorV2        ← current shop (/v2/shop/...)
//   │   └── ShopV2Layout (sidebar, richer UI)
//   │       ├── /v2/shop              → ShopHomeV2
//   │       ├── /v2/shop/products     → ProductListV2
//   │       ├── /v2/shop/products/:id → ProductDetailV2
//   │       └── /v2/shop/cart         → CartV2
//   ├── BlogCoordinator          ← NESTED CoordinatorModular (/blog/...)
//   │   └── BlogLayout (sidebar)
//   │       ├── BlogPostsModule
//   │       │   ├── /blog               → BlogHomeRoute
//   │       │   └── /blog/posts/:slug   → BlogPostRoute
//   │       └── BlogCommentsModule
//   │           └── /blog/posts/:slug/comments → BlogCommentRoute
//   └── SettingsCoordinator      ← settings (/settings/...)
//       └── SettingsLayout (sidebar)
//           ├── /settings          → GeneralSettingsRoute
//           ├── /settings/account  → AccountSettingsRoute
//           └── /settings/privacy  → PrivacySettingsRoute
//
// ============================================================================

void main() {
  runApp(const CoordinatorModuleApp());
}

class CoordinatorModuleApp extends StatefulComponent {
  const CoordinatorModuleApp({super.key});

  @override
  State<CoordinatorModuleApp> createState() => _CoordinatorModuleAppState();
}

class _CoordinatorModuleAppState extends State<CoordinatorModuleApp> {
  final coordinator = MainCoordinator();

  @override
  Component build(BuildContext context) {
    return NoctermApp(child: CoordinatorComponent(coordinator: coordinator));
  }
}

// ============================================================================
// Shared Route Base Class
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Shop Coordinator V1 — DEPRECATED version
// ============================================================================

class ShopCoordinatorV1Module extends ShopCoordinatorV1 {
  ShopCoordinatorV1Module(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', ...final pathSegments] => super.parseRouteFromUri(
        uri.replace(pathSegments: pathSegments),
      ),
      _ => null,
    };
  }
}

class ShopCoordinatorV1 extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> shopV1Stack = NavigationPath.createWith(
    label: 'shop-v1',
    coordinator: this,
  )..bindLayout(ShopV1Layout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopV1Stack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeV1(),
      ['shop', 'products'] => ProductListV1(),
      ['shop', 'cart'] => CartV1(),
      _ => null,
    };
  }
}

// V1 Layout — sidebar with a deprecation banner
class ShopV1Layout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<ShopCoordinatorV1Module>().shopV1Stack;

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        // Deprecation banner
        DecoratedBox(
          decoration: BoxDecoration(color: Colors.yellow),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(
                  '⚠ Shop V1 is deprecated. ',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Press "v" to switch to V2.',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Title bar
        DecoratedBox(
          decoration: BoxDecoration(border: BoxBorder(bottom: BorderSide())),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(
                  'Shop (V1 — Deprecated)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: Row(
            children: [
              // Sidebar navigation
              _V1Sidebar(coordinator: coordinator, layout: this),
              // Main content
              Expanded(child: buildPath(coordinator)),
            ],
          ),
        ),
      ],
    );
  }
}

class _V1Sidebar extends StatelessComponent {
  const _V1Sidebar({required this.coordinator, required this.layout});
  final MainCoordinator coordinator;
  final ShopV1Layout layout;

  @override
  Component build(BuildContext context) {
    return ListenableBuilder(
      listenable: layout.resolvePath(coordinator),
      builder: (context, _) {
        final active = coordinator.activePath.stack.lastOrNull;
        return DecoratedBox(
          decoration: BoxDecoration(border: BoxBorder(right: BorderSide())),
          child: SizedBox(
            width: 20,
            child: Column(
              children: [
                _NavItem(
                  label: 'Home',
                  isActive: active is ShopHomeV1,
                  onTap: () => coordinator.navigate(ShopHomeV1()),
                ),
                _NavItem(
                  label: 'Products',
                  isActive: active is ProductListV1,
                  onTap: () => coordinator.navigate(ProductListV1()),
                ),
                _NavItem(
                  label: 'Cart',
                  isActive: active is CartV1,
                  onTap: () => coordinator.navigate(CartV1()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// V1 Routes
class ShopHomeV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyV) {
          coordinator.replace(ShopHomeV2());
          return true;
        }
        if (event.logicalKey == LogicalKey.keyP) {
          coordinator.push(ProductListV1());
          return true;
        }
        if (event.logicalKey == LogicalKey.keyC) {
          coordinator.push(CartV1());
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Home (V1)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1),
            Text(
              'Managed by ShopCoordinatorV1. This is the legacy version.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 1),
            Text('[p] View Products    [c] View Cart    [v] Switch to V2'),
          ],
        ),
      ),
    );
  }
}

class ProductListV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop/products');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Products (V1)', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 1),
          for (var i = 1; i <= 3; i++)
            Text(
              '  $i. Legacy Product $i — \$${(i * 9.99).toStringAsFixed(2)}',
            ),
        ],
      ),
    );
  }
}

class CartV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop/cart');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Cart (V1)', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 1),
          Text(
            'Legacy cart — use V2 for a better experience',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shop Coordinator V2 — CURRENT version
// ============================================================================

class ShopCoordinatorV2Module extends ShopCoordinatorV2 {
  ShopCoordinatorV2Module(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v2', ...final pathSegments] => super.parseRouteFromUri(
        uri.replace(pathSegments: pathSegments),
      ),
      _ => null,
    };
  }
}

class ShopCoordinatorV2 extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> shopV2Stack = NavigationPath.createWith(
    label: 'shop-v2',
    coordinator: this,
  )..bindLayout(ShopV2Layout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopV2Stack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeV2(),
      ['shop', 'products'] => ProductListV2(),
      ['shop', 'products', final id] => ProductDetailV2(id: id),
      ['shop', 'cart'] => CartV2(),
      _ => null,
    };
  }
}

// V2 Layout — sidebar (modern)
class ShopV2Layout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<ShopCoordinatorV2Module>().shopV2Stack;

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        // Title bar
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.green,
            border: BoxBorder(bottom: BorderSide()),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(
                  'Shop (V2)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Expanded(child: SizedBox()),
                Text(
                  '[S]ettings  [V1]Legacy',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: Row(
            children: [
              // Sidebar
              _V2Sidebar(coordinator: coordinator, layout: this),
              // Main content
              Expanded(child: buildPath(coordinator)),
            ],
          ),
        ),
      ],
    );
  }
}

class _V2Sidebar extends StatelessComponent {
  const _V2Sidebar({required this.coordinator, required this.layout});
  final MainCoordinator coordinator;
  final ShopV2Layout layout;

  @override
  Component build(BuildContext context) {
    return ListenableBuilder(
      listenable: layout.resolvePath(coordinator),
      builder: (context, _) {
        final active = coordinator.activePath.stack.lastOrNull;
        return DecoratedBox(
          decoration: BoxDecoration(border: BoxBorder(right: BorderSide())),
          child: SizedBox(
            width: 20,
            child: Column(
              children: [
                _NavItem(
                  label: 'Home',
                  isActive: active is ShopHomeV2,
                  onTap: () => coordinator.push(ShopHomeV2()),
                ),
                _NavItem(
                  label: 'Products',
                  isActive:
                      active is ProductListV2 || active is ProductDetailV2,
                  onTap: () => coordinator.push(ProductListV2()),
                ),
                _NavItem(
                  label: 'Cart',
                  isActive: active is CartV2,
                  onTap: () => coordinator.push(CartV2()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// V2 Routes
class ShopHomeV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyP) {
          coordinator.push(ProductListV2());
          return true;
        }
        if (event.logicalKey == LogicalKey.keyC) {
          coordinator.push(CartV2());
          return true;
        }
        if (event.logicalKey == LogicalKey.keyB) {
          coordinator.push(BlogHomeRoute());
          return true;
        }
        if (event.logicalKey == LogicalKey.keyS) {
          coordinator.push(GeneralSettingsRoute());
          return true;
        }
        if (event.logicalKey == LogicalKey.keyL) {
          coordinator.replace(ShopHomeV1());
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Home (V2)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Managed by ShopCoordinatorV2 — current version with sidebar.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 1),
            Text('[p] Browse Products    [c] View Cart'),
            SizedBox(height: 1),
            Text(
              'Cross-coordinator Navigation:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('[b] Go to Blog    [s] Go to Settings    [l] Open V1 Legacy'),
          ],
        ),
      ),
    );
  }
}

class ProductListV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/products');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        for (var i = 1; i <= 5; i++) {
          if (event.logicalKey == LogicalKey(0x30 + i, 'digit$i')) {
            coordinator.push(ProductDetailV2(id: '$i'));
            return true;
          }
        }
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products (V2)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1),
            for (var i = 1; i <= 5; i++)
              Text('  [$i] Product $i — \$${(i * 12.49).toStringAsFixed(2)}'),
            SizedBox(height: 1),
            Text(
              'Press 1-5 to view details, ESC to go back',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailV2 extends AppRoute {
  ProductDetailV2({required this.id});
  final String id;

  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/products/$id');
  @override
  List<Object?> get props => [id];

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BoxBorder.all(),
            title: BorderTitle(text: 'Product Detail'),
          ),
          child: Padding(
            padding: EdgeInsets.all(1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Product $id',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'V2 exclusive — product detail with :id parameter',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 1),
                Text('Press ESC to go back'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CartV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/cart');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cart (V2)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1),
            Text('  🛒 Widget Kit Pro       \$24.99'),
            Text('  🛒 State Manager Ultra  \$39.99'),
            SizedBox(height: 1),
            DecoratedBox(
              decoration: BoxDecoration(border: BoxBorder(top: BorderSide())),
              child: Text(
                '  Total: \$64.98',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            SizedBox(height: 1),
            Text('Press ESC to go back', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Blog Coordinator — NESTED CoordinatorModular
// ============================================================================

class BlogCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  BlogCoordinator(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  late final NavigationPath<AppRoute> blogStack = NavigationPath.createWith(
    label: 'blog',
    coordinator: this,
  )..bindLayout(BlogLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, blogStack];

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    BlogPostsModule(this),
    BlogCommentsModule(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

// Blog sub-modules
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

// Blog Layout — sidebar
class BlogLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<BlogCoordinator>().blogStack;

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        // Title bar
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.cyan,
            border: BoxBorder(bottom: BorderSide()),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(
                  'Blog',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Expanded(child: SizedBox()),
                Text(
                  '[S]hop  [G]Settings',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: Row(
            children: [
              // Sidebar
              _BlogSidebar(coordinator: coordinator, layout: this),
              // Main content
              Expanded(child: buildPath(coordinator)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlogSidebar extends StatelessComponent {
  const _BlogSidebar({required this.coordinator, required this.layout});
  final MainCoordinator coordinator;
  final BlogLayout layout;

  @override
  Component build(BuildContext context) {
    return ListenableBuilder(
      listenable: layout.resolvePath(coordinator),
      builder: (context, _) {
        final active = coordinator.activePath.stack.lastOrNull;
        return DecoratedBox(
          decoration: BoxDecoration(border: BoxBorder(right: BorderSide())),
          child: SizedBox(
            width: 20,
            child: Column(
              children: [
                _NavItem(
                  label: 'Home',
                  isActive: active is BlogHomeRoute,
                  onTap: () => coordinator.push(BlogHomeRoute()),
                ),
                _NavItem(
                  label: 'Posts',
                  isActive:
                      active is BlogPostRoute || active is BlogCommentRoute,
                  onTap: () => coordinator.push(BlogPostRoute(slug: 'latest')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Blog Routes
class BlogHomeRoute extends AppRoute {
  @override
  Type get layout => BlogLayout;
  @override
  Uri toUri() => Uri.parse('/blog');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.digit1) {
          coordinator.push(BlogPostRoute(slug: 'hello-world'));
          return true;
        }
        if (event.logicalKey == LogicalKey.digit2) {
          coordinator.push(BlogPostRoute(slug: 'getting-started'));
          return true;
        }
        if (event.logicalKey == LogicalKey.digit3) {
          coordinator.push(BlogPostRoute(slug: 'advanced-tips'));
          return true;
        }
        if (event.logicalKey == LogicalKey.keyS) {
          coordinator.push(ShopHomeV2());
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blog Home',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            SizedBox(height: 1),
            Text(
              'Managed by BlogCoordinator — a nested CoordinatorModular.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 1),
            Text('[1] HELLO WORLD         /blog/posts/hello-world'),
            Text('[2] GETTING STARTED     /blog/posts/getting-started'),
            Text('[3] ADVANCED TIPS       /blog/posts/advanced-tips'),
            SizedBox(height: 1),
            Text(
              'Cross-coordinator:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('[s] Go to Shop V2'),
          ],
        ),
      ),
    );
  }
}

class BlogPostRoute extends AppRoute {
  BlogPostRoute({required this.slug});
  final String slug;

  @override
  Type get layout => BlogLayout;
  @override
  Uri toUri() => Uri.parse('/blog/posts/$slug');
  @override
  List<Object?> get props => [slug];

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyC) {
          coordinator.push(BlogCommentRoute(postSlug: slug));
          return true;
        }
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slug.replaceAll('-', ' ').toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            SizedBox(height: 1),
            Text(
              'Parsed by BlogPostsModule (sub-module of BlogCoordinator)',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 1),
            Text('[c] View Comments    [ESC] Back'),
          ],
        ),
      ),
    );
  }
}

class BlogCommentRoute extends AppRoute {
  BlogCommentRoute({required this.postSlug});
  final String postSlug;

  @override
  Type get layout => BlogLayout;
  @override
  Uri toUri() => Uri.parse('/blog/posts/$postSlug/comments');
  @override
  List<Object?> get props => [postSlug];

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments for "$postSlug"',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            SizedBox(height: 1),
            Text(
              'Parsed by BlogCommentsModule (sub-module of BlogCoordinator)',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 1),
            for (var i = 1; i <= 3; i++)
              Text('  U$i: Great post about $postSlug!'),
            SizedBox(height: 1),
            Text('Press ESC to go back', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Settings Coordinator
// ============================================================================

class SettingsCoordinator extends Coordinator<AppRoute> {
  SettingsCoordinator(this.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  late final NavigationPath<AppRoute> settingsStack = NavigationPath.createWith(
    label: 'settings',
    coordinator: this,
  )..bindLayout(SettingsLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, settingsStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['settings'] => GeneralSettingsRoute(),
      ['settings', 'account'] => AccountSettingsRoute(),
      ['settings', 'privacy'] => PrivacySettingsRoute(),
      _ => null,
    };
  }
}

// Settings Layout — sidebar
class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<SettingsCoordinator>().settingsStack;

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        // Title bar
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.magenta,
            border: BoxBorder(bottom: BorderSide()),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Expanded(child: SizedBox()),
                Text('[ESC] Back', style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: Row(
            children: [
              // Sidebar
              _SettingsSidebar(coordinator: coordinator, layout: this),
              // Main content
              Expanded(child: buildPath(coordinator)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSidebar extends StatelessComponent {
  const _SettingsSidebar({required this.coordinator, required this.layout});
  final MainCoordinator coordinator;
  final SettingsLayout layout;

  @override
  Component build(BuildContext context) {
    return ListenableBuilder(
      listenable: layout.resolvePath(coordinator),
      builder: (context, _) {
        final active = coordinator.activePath.stack.lastOrNull;
        return DecoratedBox(
          decoration: BoxDecoration(border: BoxBorder(right: BorderSide())),
          child: SizedBox(
            width: 20,
            child: Column(
              children: [
                _NavItem(
                  label: 'General',
                  isActive: active is GeneralSettingsRoute,
                  onTap: () => coordinator.push(GeneralSettingsRoute()),
                ),
                _NavItem(
                  label: 'Account',
                  isActive: active is AccountSettingsRoute,
                  onTap: () => coordinator.push(AccountSettingsRoute()),
                ),
                _NavItem(
                  label: 'Privacy',
                  isActive: active is PrivacySettingsRoute,
                  onTap: () => coordinator.push(PrivacySettingsRoute()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Settings Routes
class GeneralSettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyS) {
          coordinator.push(ShopHomeV2());
          return true;
        }
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.tryPop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.magenta,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Managed by SettingsCoordinator — an independent Coordinator '
              'used as a RouteModule.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 1),
            Text('  Language:  English'),
            Text('  Theme:     System'),
            SizedBox(height: 1),
            Text('[s] Go to Shop V2    [ESC] Back'),
          ],
        ),
      ),
    );
  }
}

class AccountSettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings/account');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.tryPop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.magenta,
              ),
            ),
            SizedBox(height: 1),
            Text('  Email:     user@example.com'),
            Text('  Password:  ••••••••'),
            SizedBox(height: 1),
            Text('Press ESC to go back', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class PrivacySettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings/privacy');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.tryPop();
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.magenta,
              ),
            ),
            SizedBox(height: 1),
            Text('  Data Privacy:        Manage how your data is used'),
            Text('  Location Services:   Enabled'),
            SizedBox(height: 1),
            Text('Press ESC to go back', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Main Coordinator — composes versioned coordinators as modules
// ============================================================================

class MainCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    MainRouteModule(this),
    ShopCoordinatorV1Module(this),
    ShopCoordinatorV2Module(this),
    BlogCoordinator(this),
    SettingsCoordinator(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

// ============================================================================
// Root-level Routes
// ============================================================================

class MainRouteModule extends RouteModule<AppRoute> {
  MainRouteModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      _ => null,
    };
  }
}

class HomeRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');
  @override
  Component build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => SizedBox();

  /// Default redirect to V2 shop
  @override
  AppRoute redirect() => ShopHomeV2();
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});
  final Uri uri;

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  Component build(covariant MainCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.enter) {
          coordinator.replace(ShopHomeV2());
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '⚠ Route not found: ${uri.path}',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1),
            Text('Press ENTER to go to Shop V2'),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Components
// ============================================================================

class _NavItem extends StatelessComponent {
  const _NavItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: Text(
          isActive ? '▸ $label' : '  $label',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : null,
            color: isActive ? Colors.green : Colors.white,
          ),
        ),
      ),
    );
  }
}
