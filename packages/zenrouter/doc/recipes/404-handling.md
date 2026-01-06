# Recipe: 404 Not Found Handling

## Problem

Your app needs to gracefully handle unknown routes and deep links that don't match any defined route, showing users a helpful 404 page instead of crashing or showing a blank screen.

## Solution Overview

ZenRouter makes 404 handling straightforward with the **Coordinator pattern**. When `parseRouteFromUri` encounters an unknown path, simply return a dedicated `NotFoundRoute`. This approach:

- Provides a consistent fallback for all invalid URLs
- Maintains type safety across your routing system
- Allows customization of the 404 experience
- Works seamlessly with deep linking and web URLs

## Complete Code Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// 1. Define your base route class
abstract class AppRoute extends RouteTarget with RouteUnique {}

// 2. Create a dedicated NotFoundRoute
class NotFoundRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/404');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const NotFoundPage();
  }
}

// 3. Define your 404 page UI
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon or illustration
            Icon(
              Icons.error_outline,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              '404',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            
            // Message
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            Text(
              'The page you are looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            
            // Action button
            ElevatedButton.icon(
              onPressed: () {
                // Navigate back to home
                context.coordinator<AppCoordinator>().replace(HomeRoute());
              },
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// 4. In your Coordinator, return NotFoundRoute for unknown paths
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['about'] => AboutRoute(),
      ['profile', String userId] => ProfileRoute(userId),
      
      // Catch-all for unknown routes
      _ => NotFoundRoute(),
    };
  }
}

// Example routes
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const HomePage();
  }
}

class AboutRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/about');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const AboutPage();
  }
}

class ProfileRoute extends AppRoute {
  final String userId;
  ProfileRoute(this.userId);
  
  @override
  List<Object?> get props => [userId];
  
  @override
  Uri toUri() => Uri.parse('/profile/$userId');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return ProfilePage(userId: userId);
  }
}
```

## Step-by-Step Explanation

### 1. Create a Dedicated NotFoundRoute

```dart
class NotFoundRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/404');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const NotFoundPage();
  }
}
```

- The `NotFoundRoute` is a regular route like any other in your app
- It has its own URI (`/404`) for consistency
- The `build` method returns your custom 404 UI

### 2. Use Switch Pattern Matching with Catch-All

```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),
    ['about'] => AboutRoute(),
    ['profile', String userId] => ProfileRoute(userId),
    
    // Catch-all pattern - matches anything not matched above
    _ => NotFoundRoute(),
  };
}
```

- The `_` pattern is Dart's catch-all wildcard
- Any path not matching the patterns above returns `NotFoundRoute`
- This includes malformed paths, typos, and invalid deep links

### 3. Design a User-Friendly 404 Page

A good 404 page should:
- Clearly communicate the error ("404 Page Not Found")
- Explain what happened in plain language
- Provide a clear action (e.g., "Go Home" button)
- Match your app's design language

## Advanced Variations

### Track 404s for Analytics

```dart
class NotFoundRoute extends AppRoute with RouteDeepLink {
  final String attemptedPath;
  
  NotFoundRoute([this.attemptedPath = '/404']);
  
  @override
  List<Object?> get props => [attemptedPath];
  
  @override
  Uri toUri() => Uri.parse('/404');
  
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(Coordinator coordinator, Uri uri) async {
    // Log to analytics
    analytics.logEvent(
      name: 'page_not_found',
      parameters: {'attempted_path': attemptedPath},
    );
  }
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return NotFoundPage(attemptedPath: attemptedPath);
  }
}

// In coordinator
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),
    _ => NotFoundRoute(uri.path), // Pass the attempted path
  };
}
```

### Show Search Suggestions

```dart
class NotFoundPage extends StatelessWidget {
  final String? attemptedPath;
  
  const NotFoundPage({super.key, this.attemptedPath});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ... 404 message ...
            
            if (attemptedPath != null) ...[
              const SizedBox(height: 24),
              Text(
                'You tried to access: $attemptedPath',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              // Show suggestions
              Text(
                'Did you mean:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _SuggestionsList(attemptedPath: attemptedPath!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  final String attemptedPath;
  
  const _SuggestionsList({required this.attemptedPath});
  
  @override
  Widget build(BuildContext context) {
    // Simple fuzzy matching (could use a package like string_similarity)
    final suggestions = [
      if (attemptedPath.contains('prof')) '/profile',
      if (attemptedPath.contains('about')) '/about',
      if (attemptedPath.contains('home')) '/',
    ];
    
    return Column(
      children: suggestions.map((suggestion) {
        return TextButton(
          onPressed: () {
            context.coordinator<AppCoordinator>()
                .navigate(Uri.parse(suggestion));
          },
          child: Text(suggestion),
        );
      }).toList(),
    );
  }
}
```

### Custom 404s Based on Section

```dart
@override
AppRoute parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),
    
    // Blog section
    ['blog', ...] when uri.pathSegments.length >= 2 => BlogPostRoute(uri.pathSegments[1]),
    ['blog'] => BlogListRoute(),
    
    // Shop section
    ['shop', ...] when uri.pathSegments.length >= 2 => ProductRoute(uri.pathSegments[1]),
    ['shop'] => ShopRoute(),
    
    // Section-specific 404s
    ['blog', ...] => NotFoundRoute.blog(),
    ['shop', ...] => NotFoundRoute.shop(),
    
    // Generic 404
    _ => NotFoundRoute(),
  };
}

// Enhanced NotFoundRoute
class NotFoundRoute extends AppRoute {
  final NotFoundSection section;
  
  NotFoundRoute([this.section = NotFoundSection.generic]);
  
  NotFoundRoute.blog() : section = NotFoundSection.blog;
  NotFoundRoute.shop() : section = NotFoundSection.shop;
  
  @override
  List<Object?> get props => [section];
  
  @override
  Uri toUri() => Uri.parse('/404');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return NotFoundPage(section: section);
  }
}

enum NotFoundSection { generic, blog, shop }
```

## Common Gotchas

> [!CAUTION]
> **Don't forget the catch-all pattern!**
> Without `_ => NotFoundRoute()` in your switch, an unknown path will throw an exception.

> [!TIP]
> **Test your 404 handling early**
> Try navigating to random URLs in development to ensure the fallback works correctly.

> [!NOTE]
> **404 pages work in all paradigms**
> While this recipe uses the Coordinator pattern (best for deep linking), you can create custom error screens in Imperative and Declarative paradigms too—just without the automatic URI-driven fallback.

## Related Recipes

- [Authentication Flow](authentication-flow.md) - Redirect to login before showing 404
- [Route Transitions](route-transitions.md) - Custom animations for error pages
- [Nested Navigation](nested-navigation.md) - 404s in nested navigation contexts

## See Also

- [Coordinator Pattern Guide](../paradigms/coordinator/coordinator.md)
- [RouteDeepLink Mixin](../api/mixins.md#routedeeplink)
