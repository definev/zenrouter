<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_dark.png?raw=true">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_light.png?raw=true">
  <img alt="ZenRouter Logo" src="https://github.com/definev/zenrouter/blob/main/assets/zenrouter_light.png?raw=true">
</picture>

**The Ultimate Flutter Router for Every Navigation Pattern**

[![pub package](https://img.shields.io/pub/v/zenrouter.svg)](https://pub.dev/packages/zenrouter)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)
[![Codecov - zenrouter_core](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter_core)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter_core)
[![Codecov - zenrouter_file_generator](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter_file_generator)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter_file_generator)

</div>

ZenRouter is the only router you'll ever need - supporting three distinct paradigms to handle any routing scenario, from simple mobile apps to complex web applications with deep linking.

## Three Paradigms. One Router.

🎮 **Imperative** - Direct control for mobile apps and event-driven navigation  
📊 **Declarative** - State-driven routing for tab bars and dynamic UIs  
🗺️ **Coordinator** - Deep linking and web support for complex applications  

## Why ZenRouter?

✨ **One Router, Three Paradigms** - Choose the approach that fits your needs  
🚀 **Progressive** - Start simple, add complexity only when needed  
🌐 **Full Web Support** - Built-in deep linking and URL synchronization  
⚡ **Blazing Fast** - Efficient Myers diff for optimal performance  
🔒 **Type-Safe** - Catch routing errors at compile-time  
🛡️ **Powerful** - Guards, redirects, and custom transitions built-in  
📝 **No Codegen Needed (for core)** - Pure Dart, no build_runner or generated files required. *(Optional file-based routing via `zenrouter_file_generator` is available when you want codegen.)*  

---

## 📚 Full Documentation

For complete documentation, API reference, examples, and getting started guides:

### **👉 [View Full ZenRouter Documentation](packages/zenrouter/README.md)**

---

## Repository Structure

This monorepo contains:

- **[zenrouter](packages/zenrouter/)** - The core routing library
- **[zenrouter_file_generator](packages/zenrouter_file_generator/)** - File-based routing code generator for ZenRouter's Coordinator paradigm
- **[zenrouter_devtools](packages/zenrouter_devtools/)** - DevTools for debugging navigation

---

## Quick Example

```dart
// Imperative: Direct control
final path = NavigationPath<AppRoute>.create();
path.push(ProfileRoute());

// Declarative: State-driven
NavigationStack.declarative(
  routes: [
    for (final page in pages) PageRoute(page),
  ],
  resolver: (route) => StackTransition.material(...),
)

// Coordinator: Web & deep linking
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) => ...;
}
```

---

## Platform Support

✅ iOS • ✅ Android • ✅ Web • ✅ macOS • ✅ Windows • ✅ Linux

---

## License

Apache 2.0 License - see [LICENSE](LICENSE)

## Author

Created by [definev](https://github.com/definev)

---

<div align="center">

**[Get Started →](packages/zenrouter/README.md)**

</div>