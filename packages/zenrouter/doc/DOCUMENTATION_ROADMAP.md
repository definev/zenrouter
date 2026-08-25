# Documentation

## Start

1. [README](../README.md)
2. [Getting Started](guides/getting-started.md) — pick imperative, declarative, or Coordinator

| Topic | Doc |
|-------|-----|
| Imperative / declarative | [Imperative](paradigms/imperative.md), [Declarative](paradigms/declarative.md) |
| Coordinator | [Coordinator](paradigms/coordinator/coordinator.md) |
| Shells, tabs, branched stacks | [Layouts](guides/route-layout.md) |
| Feature modules | [Modular coordinator](guides/coordinator-modular.md) |
| Nested coordinators | [Coordinator as RouteModule](guides/coordinator-as-module.md) |
| Query strings | [Query parameters](guides/query-parameters.md) |
| Process death | [State restoration](guides/state-restoration.md) |
| Embed without `Router` | [CoordinatorView](guides/coordinator-view.md) |

2.x: [Migrating from 2.x](guides/getting-started.md#migrating-from-2x)

## Migration

| From | Guide |
|------|-------|
| go_router | [from-go-router.md](migration/from-go-router.md) |
| auto_route | [from-auto-route.md](migration/from-auto-route.md) |
| Navigator 1.0 / 2.0 | [from-navigator.md](migration/from-navigator.md) |

## Recipes

- [404 Handling](recipes/404-handling.md)
- [Bottom Navigation](recipes/bottom-navigation.md)
- [Authentication](recipes/authentication-flow.md)
- [Route Transitions](recipes/route-transitions.md)
- [URL Strategies](recipes/url-strategies.md)
- [State Management](recipes/state-management.md)
- [Route Versioning](recipes/route-versioning.md)
- [Guard rules](recipes/route-guard-rules.md)

[All recipes](recipes/)

## Guides

- [Getting Started](guides/getting-started.md)
- [Layouts](guides/route-layout.md)
- [Modular coordinator](guides/coordinator-modular.md)
- [Coordinator as RouteModule](guides/coordinator-as-module.md)
- [CoordinatorView](guides/coordinator-view.md)
- [Query parameters](guides/query-parameters.md)
- [State restoration](guides/state-restoration.md)
- [Navigator observers](guides/navigator-observers.md)

## API

- [Navigation Paths](api/navigation-paths.md)
- [Route Mixins](api/mixins.md)
- [Coordinator API](api/coordinator.md)

## Paradigms

- [Imperative](paradigms/imperative.md)
- [Declarative](paradigms/declarative.md)
- [Coordinator](paradigms/coordinator/coordinator.md)

## Architecture

- [Web navigation backbone](architecture/web-navigation-backbone-technical-report-vi.md)

## Suggested order

**Mobile, no URLs:** Getting Started (imperative or declarative) → [transitions](recipes/route-transitions.md)

**Web / deep links:** Getting Started (Coordinator) → Layouts → 404 / auth recipes

**Multi-feature:** Modular coordinator → Coordinator as RouteModule → State restoration

**Migrating:** [migration/](migration/) → Getting Started

- [GitHub](https://github.com/definev/zenrouter)
- [pub.dev](https://pub.dev/packages/zenrouter)
- [Examples](https://github.com/definev/zenrouter/tree/main/packages/zenrouter/example/lib)
- [Issues](https://github.com/definev/zenrouter/issues)
