<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_dark.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_light.png?raw=true">
  <img alt="ZenRouter Logo" src="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_light.png?raw=true">
</picture>

**The Ultimate Flutter Router for Every Navigation Pattern**

[![pub package](https://img.shields.io/pub/v/zenrouter.svg)](https://pub.dev/packages/zenrouter)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter)
[![Codecov - zenrouter_core](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter_core)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter_core)

</div>

---

## Architecture Overview

ZenRouter provides three navigation paradigms through a layered architecture:

```
RouteTarget (base class for all routes)
  ├── Imperative    → NavigationPath + NavigationStack
  ├── Declarative   → NavigationStack.declarative (Myers diff)
  └── Coordinator   → Coordinator<T> + MaterialApp.router
        └── RouteUnique (URI-based identity for deep linking)
```

### Paradigm Selection

```
Need deep linking, URL sync, or browser back button?
│
├─ YES → Coordinator
│
└─ NO → Is navigation derived from state?
       │
       ├─ YES → Declarative
       │
       └─ NO → Imperative
```

|  | **Imperative** | **Declarative** | **Coordinator** |
|---|:---:|:---:|:---:|
| Simplicity | ⭐⭐⭐ | ⭐⭐ | ⭐ |
| Web / Deep Linking | ❌ | ❌ | ✅ |
| State-Driven | Compatible | ✅ Native | Compatible |
| Route Mixins | Guard, Redirect, Transition | Guard, Redirect, Transition | Guard, Redirect, Transition, **DeepLink** |

---

## Quick Example

```dart
// Imperative: Direct stack control
final path = NavigationPath<AppRoute>.create();
path.push(ProfileRoute());

// Declarative: State-driven navigation via Myers diff
NavigationStack.declarative(
  routes: [
    for (final page in pages) PageRoute(page),
  ],
  resolver: (route) => StackTransition.material(...),
)

// Coordinator: Deep linking, web, and state restoration
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) => ...;
}
```

---

## Repository Structure

| Package | Responsibility |
|---------|----------------|
| [`zenrouter`](packages/zenrouter/) | Flutter integration: `Coordinator`, `NavigationStack`, `StackTransition`, state restoration |
| [`zenrouter_core`](packages/zenrouter_core/) | Platform-independent core: `RouteTarget`, `CoordinatorCore`, `StackPath`, and all route mixins |
| [`zenrouter_devtools`](packages/zenrouter_devtools/) | DevTools extension for inspecting routes, testing deep links, and debugging navigation |
| [`zenrouter_file_generator`](packages/zenrouter_file_generator/) | Optional `build_runner` code generator for Next.js-style file-based routing on top of Coordinator |

---

## Documentation

### **👉 [Full Documentation & Examples](packages/zenrouter/README.md)**

### Platform Support

✅ iOS · ✅ Android · ✅ Web · ✅ macOS · ✅ Windows · ✅ Linux

---

## License

Apache 2.0 — see [LICENSE](LICENSE)

## Created With Love By

[definev](https://github.com/definev)

---

<div align="center">

**[Get Started →](packages/zenrouter/README.md)**

</div>