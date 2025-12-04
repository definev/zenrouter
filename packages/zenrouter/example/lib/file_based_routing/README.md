# File-Based Routing Example

This example demonstrates a **file-system-based routing convention** for the Coordinator paradigm, similar to Next.js or SvelteKit, with a strict separation between layouts and routes.

## Running the Example

```bash
# From packages/zenrouter/example directory
flutter run -t lib/file_based_routing/main.dart

# Or from the root of the repo
cd packages/zenrouter/example
flutter run -t lib/file_based_routing/main.dart
```

## Convention Overview

### File Naming

- **`routename.dart`** - Standalone route (e.g., `home.dart` → `/home`)
- **`index.dart`** - Default route for a directory (e.g., `products/index.dart` → `/products`)
- **`:parameter.dart`** - Route with path parameter (e.g., `:id.dart` → `/products/:id`)
- **`+layout.dart`** - Layout host for routes in that directory
- **`subfolder/route.dart`** - Nested route under a layout

### Directory Structure = URL Structure

```
routes/
├── home.dart                      → /home (standalone route)
├── products/
│   ├── +layout.dart               → Layout for /products/* routes
│   ├── index.dart                 → /products (default route, hosted by ProductsLayout)
│   └── :id.dart                   → /products/:id (hosted by ProductsLayout)
└── settings/
    ├── +layout.dart               → Layout for /settings/* routes
    ├── index.dart                 → /settings (default route, hosted by SettingsLayout)
    ├── account.dart               → /settings/account (hosted by SettingsLayout)
    └── privacy.dart               → /settings/privacy (hosted by SettingsLayout)
```

## URL Mapping

| File Path | URL | Route Class | Layout? |
|-----------|-----|-------------|---------|
| `home.dart` | `/home` | `HomeRoute` | No |
| `products/index.dart` | `/products` | `ProductsIndexRoute` | ProductsLayout |
| `products/:id.dart` | `/products/123` | `ProductDetailRoute(id: '123')` | ProductsLayout |
| `settings/index.dart` | `/settings` | `SettingsIndexRoute` | SettingsLayout |
| `settings/account.dart` | `/settings/account` | `SettingsAccountRoute` | SettingsLayout |
| `settings/privacy.dart` | `/settings/privacy` | `SettingsPrivacyRoute` | SettingsLayout |

## Layouts and Index Routes

### ✅ DO: Use index.dart for default routes in layout folders

```
products/
├── +layout.dart   ← Layout container
├── index.dart     ← ✓ Default route for /products
└── :id.dart       ← Route for /products/:id
```

### Standalone Routes

```
routes/
├── home.dart      ← ✓ Standalone route (no layout needed)
└── about.dart     ← ✓ Another standalone route
```

## When to Use Layouts

Use `+layout.dart` when you need to:
- Share UI structure (app bar, navigation) across multiple routes
- Maintain separate navigation stacks for a section
- Group related routes together

**Don't use layouts for**:
- Single standalone pages (use simple `.dart` files)
- Routes that don't share structure

## Benefits

✅ **Clear Separation** - Layouts vs standalone routes are visually distinct  
✅ **No Ambiguity** - Can't accidentally navigate to a layout  
✅ **Intuitive** - File structure clearly shows route hierarchy  
✅ **Type-Safe** - Path parameters are typed  
✅ **Code Generation Ready** - Structure enables automatic route generation  

## Key Files

- **[main.dart](main.dart)** - Application entry point
- **[coordinator.dart](coordinator.dart)** - URL parsing and route mapping
- **[routes/](routes/)** - All route files following the convention

## Example: Adding a New Route

### Standalone Route (no layout needed)

```dart
// routes/about.dart
part of '../coordinator.dart';

class AboutRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/about');
  
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About Page')),
    );
  }
}
```

### Route with Layout

```dart
// routes/settings/notifications.dart
part of '../../coordinator.dart';

class SettingsNotificationsRoute extends AppRoute {
  @override
  RouteLayout? get layout => SettingsLayout.instance;
  
  @override
  Uri toUri() => Uri.parse('/settings/notifications');
  
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    return const Center(child: Text('Notification Settings'));
  }
}
```

Then add to coordinator:
```dart
['settings', 'notifications'] => SettingsNotificationsRoute(),
```

## See Also

- [Coordinator Pattern Guide](../../../doc/paradigms/coordinator.md)
- [Coordinator API Reference](../../../doc/api/coordinator.md)
- [File-Based Routing Practice Guide](../../../practices/file-based-routing/README.md)
