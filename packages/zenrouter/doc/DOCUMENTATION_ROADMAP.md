# ZenRouter Documentation Roadmap

Welcome to the ZenRouter documentation! This roadmap helps you navigate our comprehensive guides based on your needs.

## 🎯 For New Users

### Start Here
1. **[README.md](../README.md)** - Overview and quick paradigm selection
2. **[Getting Started Guide](guides/getting-started.md)** - Installation and paradigm quick starts

### Learn Your Paradigm
Choose based on your needs:
- **Simple mobile app?** → [Imperative Pattern](paradigms/imperative.md)
- **State-driven UI?** → [Declarative Pattern](paradigms/declarative.md)
- **Web/deep linking?** → [Coordinator Pattern](paradigms/coordinator/coordinator.md)

### Build Common Features
Explore our [Recipes & Cookbook](recipes/):
- [404 Handling](recipes/404-handling.md) - Custom error pages
- [Bottom Navigation](recipes/bottom-navigation.md) - Tab bars with persistent state
- [Authentication Flow](recipes/authentication-flow.md) - Guards and protected routes

---

## 🔄 For Migrating Users

Coming from another router? We have dedicated migration guides:

| Your Current Router | Migration Guide | Key Topics |
|---------------------|-----------------|------------|
| go_router | [from-go-router.md](migration/from-go-router.md) | GoRoute → RouteTarget, ShellRoute → RouteLayout |
| auto_route | [from-auto-route.md](migration/from-auto-route.md) | Removing build_runner, AutoTabsRouter → IndexedStackPath |
| Navigator 1.0/2.0 | [from-navigator.md](migration/from-navigator.md) | Named routes → Type-safe classes |

---

## 🍳 By Use Case

### Basic Navigation
1. [Getting Started - Imperative](guides/getting-started.md#imperative-quick-start)
2. [Navigation Paths API](api/navigation-paths.md)

### Tab Navigation  
1. [Getting Started - Declarative](guides/getting-started.md#declarative-quick-start)
2. [Bottom Navigation Recipe](recipes/bottom-navigation.md)

### Web & Deep Linking
1. [Getting Started - Coordinator](guides/getting-started.md#coordinator-quick-start)
2. [Coordinator Pattern Guide](paradigms/coordinator/coordinator.md)
3. [URL Strategies Recipe](recipes/url-strategies.md)

### Authentication & Guards
1. [Authentication Flow Recipe](recipes/authentication-flow.md)
2. [Route Mixins - RouteRedirect](api/mixins.md#routeredirect)

### Custom Transitions
1. [Route Transitions Recipe](recipes/route-transitions.md)
2. [Route Mixins - RouteTransition](api/mixins.md#routetransition)

### State Management
1. [State Management Recipe](recipes/state-management.md)
2. [State Restoration Guide](guides/state-restoration.md)

---

## 📖 By Document Type

### 📚 Guides (Learning-Oriented)
Step-by-step tutorials for getting started:
- [Getting Started](guides/getting-started.md) - Choose and learn your paradigm
- [Route Layout](guides/route-layout.md) - Create custom layouts
- [Query Parameters](guides/query-parameters.md) - Handle URL query parameters  
- [State Restoration](guides/state-restoration.md) - Android state preservation
- [Navigator Observers](guides/navigator-observers.md) - Track navigation events

### 🍳 Recipes (Problem-Oriented)
Practical solutions for specific scenarios:
- [404 Handling](recipes/404-handling.md)
- [Authentication Flow](recipes/authentication-flow.md)
- [Bottom Navigation](recipes/bottom-navigation.md)
- [Route Transitions](recipes/route-transitions.md)
- [State Management](recipes/state-management.md)
- [URL Strategies](recipes/url-strategies.md)

### 🔧 API Reference (Information-Oriented)
Complete technical documentation:
- [Core Classes](api/core-classes.md) - RouteTarget fundamentals
- [Navigation Paths](api/navigation-paths.md) - NavigationPath, IndexedStackPath
- [Route Mixins](api/mixins.md) - Guards, redirects, transitions
- [Coordinator API](api/coordinator.md) - Deep linking reference

### 🎓 Paradigm Guides (Understanding-Oriented)
Deep dives into each pattern:
- [Imperative Pattern](paradigms/imperative.md)
- [Declarative Pattern](paradigms/declarative.md)
- [Coordinator Pattern](paradigms/coordinator/coordinator.md)

### 🔄 Migration Guides (Task-Oriented)
Switching from other routers:
- [From go_router](migration/from-go-router.md)
- [From auto_route](migration/from-auto-route.md)
- [From Navigator 1.0/2.0](migration/from-navigator.md)

---

## 📊 Documentation Structure

```
zenrouter/
├── README.md                    # Quick overview & links
├── doc/
    ├── guides/                # Step-by-step learning
    │   ├── getting-started.md
    │   ├── route-layout.md
    │   ├── query-parameters.md
    │   ├── state-restoration.md
    │   └── navigator-observers.md
    │
    ├── recipes/               # Practical solutions
    │   ├── README.md            # Recipe index
    │   ├── 404-handling.md
    │   ├── authentication-flow.md
    │   ├── bottom-navigation.md
    │   ├── route-transitions.md
    │   ├── state-management.md
    │   └── url-strategies.md
    │
    ├── migration/             # Switching routers
    │   ├── README.md            # Migration index
    │   ├── from-go-router.md
    │   ├── from-auto-route.md
    │   └── from-navigator.md
    │
    ├── api/                   # Technical reference
    │   ├── core-classes.md
    │   ├── navigation-paths.md
    │   ├── mixins.md
    │   └── coordinator.md
    │
    └── paradigms/             # Pattern deep dives
        ├── imperative.md
        ├── declarative.md
        └── coordinator/
            └── coordinator.md
```

---

## ✨ Quick Reference

### Core Concepts
- **RouteTarget** - Base class for all routes ([Core Classes](api/core-classes.md))
- **NavigationPath** - Stack container ([Navigation Paths](api/navigation-paths.md))
- **Coordinator** - Deep linking coordinator ([Coordinator API](api/coordinator.md))

### Route Mixins
- **RouteUnique** - URI-based equality ([Mixins](api/mixins.md#routeunique))
- **RouteRedirect** - Guards and redirects ([Mixins](api/mixins.md#routeredirect))
- **RouteGuard** - Pop prevention ([Mixins](api/mixins.md#routeguard))
- **RouteLayout** - Custom layouts ([Route Layout Guide](guides/route-layout.md))
- **RouteQueryParameters** - Reactive query params ([Query Parameters Guide](guides/query-parameters.md))

### Navigation Paths
- **NavigationPath** - Standard stack ([Navigation Paths](api/navigation-paths.md#navigationpath))
- **IndexedStackPath** - Tab navigation ([Navigation Paths](api/navigation-paths.md#indexedstackpath))

---

## 🎯 Learning Paths

### Path 1: Mobile-First Developer
1. [Imperative Quick Start](guides/getting-started.md#imperative-quick-start)
2. [Route Transitions Recipe](recipes/route-transitions.md)
3. [Authentication Flow Recipe](recipes/authentication-flow.md)
4. [State Management Recipe](recipes/state-management.md)

### Path 2: Web Developer
1. [Coordinator Quick Start](guides/getting-started.md#coordinator-quick-start)
2. [URL Strategies Recipe](recipes/url-strategies.md)
3. [404 Handling Recipe](recipes/404-handling.md)
4. [Coordinator Pattern Guide](paradigms/coordinator/coordinator.md)

### Path 3: Flutter Veteran (migrating)
1. Choose migration guide:
   - [From go_router](migration/from-go-router.md)
   - [From auto_route](migration/from-auto-route.md)  
   - [From Navigator](migration/from-navigator.md)
2. [Getting Started](guides/getting-started.md) - Map to ZenRouter concepts
3. [Recipes](recipes/) - See advanced patterns
4. [API Reference](api/) - Complete technical details

---

## 📝 Documentation Principles

### 1. **Calm and In Control**
Documentation should make you feel confident, not overwhelmed.

### 2. **Progressive Disclosure**
Start simple, reveal complexity as needed.

### 3. **Practical Examples**
Every concept has runnable code.

### 4. **Multiple Entry Points**
Find what you need from any starting point.

---

## 🔗 External Resources

- **GitHub Repository**: [definev/zenrouter](https://github.com/definev/zenrouter)
- **Pub.dev Package**: [pub.dev/packages/zenrouter](https://pub.dev/packages/zenrouter)
- **Example Apps**: [GitHub Examples](https://github.com/definev/zenrouter/tree/main/packages/zenrouter/example)
- **Issue Tracker**: [GitHub Issues](https://github.com/definev/zenrouter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/definev/zenrouter/discussions)

---

**Last Updated**: 2026-01-06  
**Version**: 0.4.14

---

🧘 **Happy routing with ZenRouter!**
