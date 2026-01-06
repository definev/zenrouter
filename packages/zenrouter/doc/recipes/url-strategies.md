# Recipe: URL Strategies for Web

## Problem

When deploying your Flutter web app, you need to configure how URLs are handled:
- **Hash-based routing** (`example.com/#/page`) - works without server configuration
- **Path-based routing** (`example.com/page`) - cleaner URLs but requires server setup
- Supporting both development and production environments
- Handling deep links and browser navigation

## Solution Overview

ZenRouter leverages Flutter's built-in `UrlStrategy` to configure URL handling. You can:

- Use hash URLs for simple deployments (GitHub Pages, S3)
- Use path URLs for production apps with proper server configuration
- Switch strategies based on environment
- Configure custom URL transformations

## Complete Code Example

### Path-Based URLs (Recommended for Production)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  // Use path-based URLs (no hash)
  usePathUrlStrategy();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final coordinator = AppCoordinator();
  
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// URLs will be:
// example.com/
// example.com/profile
// example.com/products/123
```

**Server Configuration Required:**

For path-based URLs, configure your server to serve `index.html` for all routes:

**Nginx:**
```nginx
server {
  listen 80;
  server_name example.com;
  root /var/www/app;
  
  location / {
    try_files $uri $uri/ /index.html;
  }
}
```

**Apache (`.htaccess`):**
```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

**Firebase Hosting (`firebase.json`):**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Hash-Based URLs (No Server Config Needed)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  // No need to call anything - hash URLs are the default
  // Or explicitly:
  // setHashUrlStrategy();
  
  runApp(const MyApp());
}

// URLs will be:
// example.com/#/
// example.com/#/profile
// example.com/#/products/123
```

**Advantages:**
- ✅ Works on any static file server
- ✅ No server configuration needed
- ✅ Perfect for GitHub Pages, S3, Netlify

**Disadvantages:**
- ❌ Ugly URLs with `#`
- ❌ Less SEO-friendly
- ❌ May confuse users

### Environment-Based Strategy

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  // Use path URLs in production, hash URLs in development
  if (kReleaseMode) {
    usePathUrlStrategy();
  } else {
    // Hash strategy is default, but you can be explicit:
    // setHashUrlStrategy();
  }
  
  runApp(const MyApp());
}
```

### Custom Base Path (Subdirectory Hosting)

If your app is hosted at `example.com/app/` instead of the root:

```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  
  runApp(const MyApp());
}

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // Remove base path if it exists
    var segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first == 'app') {
      segments = segments.skip(1).toList();
    }
    
    return switch (segments) {
      [] => HomeRoute(),
      ['profile'] => ProfileRoute(),
      _ => NotFoundRoute(),
    };
  }
  
  // Ensure all generated URIs include the base path
  Uri _addBasePath(Uri uri) {
    return uri.replace(
      pathSegments: ['app', ...uri.pathSegments],
    );
  }
}

// Configure in index.html
// <base href="/app/">
```

Update your `web/index.html`:
```html
<!DOCTYPE html>
<html>
<head>
  <base href="/app/">
  <!-- ... -->
</head>
<body>
  <!-- ... -->
</body>
</html>
```

## Advanced Patterns

### Custom URL Transformation

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    // Custom URL transformations
    var path = uri.path;
    
    // Map legacy URLs to new routes
    if (path.startsWith('/old-products/')) {
      final id = path.replaceFirst('/old-products/', '');
      return ProductRoute(id);
    }
    
    // Handle query parameters as paths
    if (path == '/search' && uri.queryParameters.containsKey('q')) {
      return SearchRoute(uri.queryParameters['q']!);
    }
    
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['products', String id] => ProductRoute(id),
      ['search'] => SearchRoute(),
      _ => NotFoundRoute(),
    };
  }
}
```

### Tracking Page Views

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AppCoordinator extends Coordinator<AppRoute> {
  final analytics = FirebaseAnalytics.instance;
  
  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    
    // Track page views on route changes
    _trackCurrentPage();
  }
  
  void _trackCurrentPage() {
    if (routes.isEmpty) return;
    
    final currentRoute = routes.last;
    final uri = currentRoute.toUri();
    
    analytics.logEvent(
      name: 'page_view',
      parameters: {
        'page_path': uri.path,
        'page_title': _getPageTitle(currentRoute),
      },
    );
  }
  
  String _getPageTitle(AppRoute route) {
    return switch (route) {
      HomeRoute() => 'Home',
      ProfileRoute() => 'Profile',
      ProductRoute(id: var id) => 'Product: $id',
      _ => 'Unknown',
    };
  }
}
```

### SEO Meta Tags

```dart
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:meta_seo/meta_seo.dart';

mixin RouteSeo on RouteUnique {
  String get title;
  String get description;
  String get keywords;
  // Optional meta tags with defaults
  String get author => 'Dai Duong';
  String? get ogImage => null; // URL to social media preview image
  String get ogType => 'website';
  TwitterCard? get twitterCard => TwitterCard.summaryLargeImage;
  String? get twitterSite => null; // e.g., '@yourusername'
  String? get canonicalUrl => null; // Canonical URL for this page
  String get language => 'en';
  String? get robots => null; // e.g., 'index, follow'

  final meta = MetaSEO();

  @override
  void onUpdate(covariant RouteTarget newRoute) {
    super.onUpdate(newRoute);
    buildSeo();
  }

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    buildSeo();
    return const SizedBox.shrink();
  }

  void buildSeo() {
    // Add MetaSEO just into Web platform condition
    if (kIsWeb) {
      // Basic meta tags
      meta.author(author: author);
      meta.description(description: description);
      meta.keywords(keywords: keywords);
      // Open Graph meta tags (for Facebook, LinkedIn, etc.)
      setWebTitle(title);
      meta.ogTitle(ogTitle: title);
      meta.ogDescription(ogDescription: description);
      if (ogImage != null) {
        meta.ogImage(ogImage: ogImage!);
      }
      // Twitter Card meta tags
      if (twitterCard != null) {
        meta.twitterCard(twitterCard: twitterCard!);
      }
      meta.twitterTitle(twitterTitle: title);
      meta.twitterDescription(twitterDescription: description);
      if (ogImage != null) {
        meta.twitterImage(twitterImage: ogImage!);
      }
      if (twitterSite != null) {
        // Note: You may need to add this manually if MetaSEO doesn't support it
        // or use meta.config() for custom tags
      }
      // Additional SEO tags
      if (robots != null) {
        // Use meta.config() for custom tags
        meta.robots(robotsName: RobotsName.robots, content: robots!);
      }
    }
  }
}

class ProductRoute extends AppRoute with RouteSeo {
  @override
  String get title => 'Products List';

  @override
  String get description => 'Products List description';

  @override
  String get keywords => 'product, description';

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    super.build(coordinator, context);
    return ProductListRoute();
  }
}

```

## Common Gotchas

> [!TIP]
> **Set URL strategy before runApp**
> Call `usePathUrlStrategy()` or `setHashUrlStrategy()` before calling `runApp()`.

> [!CAUTION]
> **Base href in index.html**
> Ensure your `web/index.html` has the correct `<base href="/">`. For subdirectories, use `<base href="/subdirectory/">`.

> [!WARNING]
> **Path URLs require server configuration**
> Path-based URLs will 404 on refresh unless your server is configured to always serve `index.html`.

> [!NOTE]
> **Hash URLs work everywhere**
> Hash-based URLs work on any static file server without configuration, making them safer for simple deployments.

## Testing URL Strategies

```dart
// Test path URL parsing
void testPathUrl() {
  final coordinator = AppCoordinator();
  
  final route = coordinator.parseRouteFromUri(
    Uri.parse('https://example.com/products/123'),
  );
  
  expect(route, isA<ProductRoute>());
  expect((route as ProductRoute).productId, '123');
}

// Test hash URL parsing (same logic)
void testHashUrl() {
  final coordinator = AppCoordinator();
  
  // The hash is stripped by Flutter before reaching your parser
  final route = coordinator.parseRouteFromUri(
    Uri.parse('https://example.com/products/123'),
  );
  
  expect(route, isA<ProductRoute>());
}
```

## Related Recipes

- [404 Handling](404-handling.md) - Handle invalid URLs gracefully
- [Nested Navigation](nested-navigation.md) - URLs for nested routes
- [Authentication Flow](authentication-flow.md) - Protected URLs

## See Also

- [Flutter URL Strategy Documentation](https://docs.flutter.dev/development/ui/navigation/url-strategies)
- [Coordinator Pattern Guide](../paradigms/coordinator/coordinator.md)
- [RouteUnique Mixin](../api/mixins.md#routeunique)
