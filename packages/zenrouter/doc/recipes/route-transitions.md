# Recipe: Custom Route Transitions

## Problem

You want to customize the animation when navigating between pages—whether it's a slide, fade, scale, or even a custom shared-element transition. The default platform transitions (Material/Cupertino) don't fit your app's design language.

## Solution Overview

ZenRouter provides full control over page transitions through the **StackTransition** API. You can:

- Use built-in transitions (material, cupertino, sheet, dialog, none)
- Create custom transitions with `pageBuilder`
- Apply transitions per-route or globally
- Combine multiple animations for complex effects

## Complete Code Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// Define your routes
abstract class AppRoute extends RouteTarget {}

class HomeRoute extends AppRoute {}
class ProfileRoute extends AppRoute {}
class SettingsRoute extends AppRoute {}

final appPath = NavigationPath<AppRoute>.create();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationStack(
        path: appPath,
        defaultRoute: HomeRoute(),
        // Resolver controls which transition each route uses
        resolver: (route) {
          return switch (route) {
            HomeRoute() => StackTransition.material(
                const HomePage(),
              ),
            ProfileRoute() => StackTransition.cupertino(
                const ProfilePage(),
              ),
            SettingsRoute() => StackTransition.sheet(
                const SettingsPage(),
              ),
            _ => StackTransition.material(
                const Scaffold(body: Center(child: Text('Unknown'))),
              ),
          };
        },
      ),
    );
  }
}
```

## Built-in Transitions

### Material Transition
```dart
StackTransition.material(const HomePage())
```
Platform-native Material Design transition (slide from right on Android).

### Cupertino Transition
```dart
StackTransition.cupertino(const ProfilePage())
```
iOS-style transition (slide from right with parallax).

### Sheet Transition
```dart
StackTransition.sheet(
  const SettingsPage(),
)
```
iOS bottom sheet transition.

### Dialog Transition
```dart
StackTransition.dialog(const AlertPage())
```
Dialog overlay presentation.

### No Transition
```dart
StackTransition.none(const DialogPage())
```
Instant switch with no animation (useful for testing).

## Custom Transitions

### Scale Transition

```dart
// First, create a custom Page class for the scale animation
class ScalePage<T> extends Page<T> {
  const ScalePage({super.key, required this.child});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;
        
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return ScaleTransition(
          scale: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// Then use it with StackTransition.custom
StackTransition.custom<MyRoute>(
  builder: (context) => const ProfilePage(),
  pageBuilder: (context, routeKey, child) => ScalePage(
    key: routeKey,
    child: child,
  ),
)
```

### Rotation Transition

```dart
class RotationPage<T> extends Page<T> {
  const RotationPage({super.key, required this.child});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeInOut;
        
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return RotationTransition(
          turns: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

StackTransition.custom<MyRoute>(
  builder: (context) => const SettingsPage(),
  pageBuilder: (context, routeKey, child) => RotationPage(
    key: routeKey,
    child: child,
  ),
)
```

### Combined Fade + Slide

```dart
class FadeSlidePage<T> extends Page<T> {
  const FadeSlidePage({super.key, required this.child});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) {
        const offsetBegin = Offset(0.0, 0.1);
        const offsetEnd = Offset.zero;
        const curve = Curves.easeOutCubic;
        
        final offsetTween = Tween(begin: offsetBegin, end: offsetEnd).chain(
          CurveTween(curve: curve),
        );
        
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(offsetTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

StackTransition.custom<MyRoute>(
  builder: (context) => const DetailPage(),
  pageBuilder: (context, routeKey, child) => FadeSlidePage(
    key: routeKey,
    child: child,
  ),
)
```

### Shared Element Transition (Hero)

```dart
// On source page
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => appPath.push(ProductDetailRoute('product-$index')),
          child: Hero(
            tag: 'product-$index',
            child: Image.network('https://example.com/product-$index.jpg'),
          ),
        );
      },
    );
  }
}

// On destination page
class ProductDetailPage extends StatelessWidget {
  final String productId;
  
  const ProductDetailPage({required this.productId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Hero(
            tag: productId,
            child: Image.network('https://example.com/$productId.jpg'),
          ),
          // ... product details
        ],
      ),
    );
  }
}

// Use Material transition to enable Hero animations
StackTransition.material(ProductDetailPage(productId: route.productId))
```

## Advanced Patterns

### Global Transition Strategy (Coordinator)

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  TransitionStrategy get transitionStrategy => TransitionStrategy.cupertino;
}
```

### Platform-Specific Transitions

```dart
StackTransition _platformTransition(Widget child) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return StackTransition.cupertino(child);
  }
  return StackTransition.material(child);
}

// In resolver
resolver: (route) {
  return _platformTransition(route.build(context));
}
```

### Secondary Animation (for leaving page)

```dart
class SlideBackPage<T> extends Page<T> {
  const SlideBackPage({super.key, required this.child});
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) {
        // Use secondaryAnimation to animate the page being covered
        const begin = Offset.zero;
        const end = Offset(-0.3, 0.0);
        
        final slideTween = Tween(begin: begin, end: end);
        
        return SlideTransition(
          position: secondaryAnimation.drive(slideTween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
}

StackTransition.custom<MyRoute>(
  builder: (context) => const DetailPage(),
  pageBuilder: (context, routeKey, child) => SlideBackPage(
    key: routeKey,
    child: child,
  ),
)
```

## Common Gotchas

> [!TIP]
> **Use appropriate durations**
> Keep transitions fast (200-400ms). Anything longer feels sluggish.

> [!WARNING]
> **Avoid complex animations on low-end devices**
> Heavy animations can cause jank. Consider using simpler transitions or detecting device performance.

> [!CAUTION]
> **secondaryAnimation is for the leaving page**
> When creating custom Page classes, `animation` animates the entering page, while `secondaryAnimation` animates the page being covered. Both are available in the `pageBuilder` callback of `PageRouteBuilder`.

## Transition Curves Reference

Common curves for natural motion:

```dart
Curves.easeInOut    // Balanced acceleration/deceleration
Curves.easeOut      // Starts fast, ends slow (most natural)
Curves.easeIn       // Starts slow, ends fast
Curves.easeOutCubic // Smooth, modern feel
Curves.easeInOutCubic // Very smooth
Curves.fastOutSlowIn // Material Design standard
Curves.elasticOut   // Bouncy overshoot
Curves.bounceOut    // Exaggerated bounce
```

## Performance Tips

1. **Avoid rebuilding child widgets**: Pass the child widget to the builder, which is then passed to your Page class—don't rebuild it in the `PageRouteBuilder.pageBuilder`
2. **Use `const` constructors**: Make child pages `const` where possible
3. **Limit simultaneous animations**: Don't animate too many properties at once
4. **Test on real devices**: Emulators don't accurately reflect animation performance

## Related Recipes

- [Modal Routing](modal-routing.md) - Full-screen modals with custom transitions
- [Nested Navigation](nested-navigation.md) - Transitions in nested contexts
- [Bottom Navigation](bottom-navigation.md) - Tab switching animations

## See Also

- [StackTransition API](../api/navigation-paths.md#stacktransition)
- [RouteTransition Mixin](../api/mixins.md#routetransition)
- [Flutter Animation Documentation](https://docs.flutter.dev/development/ui/animations)
