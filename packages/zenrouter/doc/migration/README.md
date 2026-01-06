# ZenRouter Migration Guides

Comprehensive guides to help you migrate from other Flutter routing solutions to ZenRouter.

---

## Available Guides

### [From go_router](from-go-router.md)
Migrate from the popular `go_router` package to ZenRouter.

**Best for**: Apps using declarative routing with go_router  
**Key topics**: GoRoute → RouteTarget, guards, ShellRoute → RouteLayout  
**Difficulty**: ⭐⭐ Moderate

---

### [From auto_route](from-auto-route.md)
Transition from `auto_route`'s code generation approach to ZenRouter.

**Best for**: Apps using auto_route with build_runner  
**Key topics**: Removing build_runner, @RoutePage → RouteTarget, AutoTabsRouter  
**Difficulty**: ⭐⭐ Moderate

---

### [From Navigator 1.0 / 2.0](from-navigator.md)
Upgrade from Flutter's built-in Navigator APIs to ZenRouter.

**Best for**: Apps using Navigator.pushNamed or Navigator 2.0 Router API  
**Key topics**: Named routes, arguments, custom transitions, deep linking  
**Difficulty**: ⭐ Easy (from 1.0) / ⭐⭐⭐ Moderate (from 2.0)

---

## Quick Comparison

| Feature | go_router | auto_route | Navigator 1.0 | Navigator 2.0 | **ZenRouter** |
|---------|-----------|------------|---------------|---------------|---------------|
| **Type Safety** | String paths | Generated | String names | Manual | ✅ Built-in |
| **Code Gen** | No | Yes (required) | No | No | Optional |
| **Paradigms** | Declarative | Mixed | Imperative | Declarative | All 3 |
| **Deep Linking** | ✅ Built-in | ✅ Built-in | Manual | ✅ Built-in | ✅ Built-in |
| **Boilerplate** | Low | Medium | Low | High | Low-Medium |
| **Learning Curve** | Medium | Medium | Low | High | Medium |

---

## Why Migrate to ZenRouter?

### 🎯 **Paradigm Flexibility**
Choose between Imperative, Declarative, or Coordinator patterns based on your needs. Not locked into one approach.

### 🛡️ **Better Type Safety**
Routes are classes with constructor parameters instead of string-based paths or runtime argument casting.

### ⚡ **Great Developer Experience**
- IDE autocomplete for routes
- Refactoring support
- Find all usages
- No build_runner delays (unless you want them)

### 🧘 **Calm and In Control**
Less magic, more explicitness. You understand what's happening because the code is right there.

### 🚀 **Production Ready**
- State restoration (automatic with Coordinator)
- Deep linking
- Web support with URL strategies
- DevTools integration
- Comprehensive test coverage

---

## General Migration Strategy

### 1. **Choose Your Paradigm**

Read [Getting Started](../guides/getting-started.md) to understand the three paradigms:

- **Imperative** - Like Navigator 1.0, simple push/pop for mobile apps
- **Declarative** - State-driven routing, rebuilds based on app state
- **Coordinator** - Like Navigator 2.0, best for web/deep linking

### 2. **Convert Route Definitions**

Transform your existing routes into `RouteTarget` classes:

```dart
abstract class AppRoute extends RouteTarget {
  Widget build(BuildContext context);
}

// Any router → ZenRouter
class ProductRoute extends AppRoute {
  final String id;
  ProductRoute(this.id);
  
  @override
  List<Object?> get props => [id];
  
  @override
  Widget build(/*...*/) => ProductPage(id: id);
}
```

### 3. **Update Navigation Calls**

Replace your current navigation API with ZenRouter's:

```dart
// Before (various routers)
context.go('/products/123');              // go_router
context.router.push(ProductRoute(...));   // auto_route
Navigator.pushNamed(context, '/product'); // Navigator 1.0

// After (ZenRouter)
coordinator.push(ProductRoute('123'));
// or
path.push(ProductRoute('123'));
```

### 4. **Test Thoroughly**

- Deep linking
- Back button behavior
- State restoration (if applicable)
- Guards/redirects
- Nested navigation

---

## Migration Support

### Documentation
- [Getting Started Guide](../guides/getting-started.md)
- [API Reference](../api/)
- [Recipes & Cookbook](../recipes/)

### Community
- [GitHub Issues](https://github.com/definev/zenrouter/issues)
- [Discussions](https://github.com/definev/zenrouter/discussions)

### Tips
- Migrate incrementally - routes can coexist during transition
- Start with simple routes, then tackle complex nested navigation
- Use type safety to catch issues early
- Read the relevant guide above for router-specific advice

---

## Need a Different Guide?

If you're migrating from a router not listed here or have questions:
- [Open an issue](https://github.com/definev/zenrouter/issues/new)
- Check [Discussions](https://github.com/definev/zenrouter/discussions)

---

**Happy migrating! 🧘**
