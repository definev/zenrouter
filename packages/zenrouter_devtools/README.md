<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

# ZenRouter DevTools

A powerful debugging tool for [ZenRouter](https://pub.dev/packages/zenrouter), providing a visual overlay to inspect navigation stacks, test deep links, and manage routes.

[![pub package](https://img.shields.io/pub/v/zenrouter_devtools.svg)](https://pub.dev/packages/zenrouter_devtools)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)

</div>

## Features

- **Visual Stack Inspection**: View the current navigation hierarchy, including active paths, nested routers, and their stack history.
- **Deep Link Testing**: Push or replace routes directly by entering a URI, making it easy to test deep linking logic.
- **Quick Actions**: Define common debug routes (e.g., specific screens, edge cases) and access them with a single click.
- **Route Management**: Pop routes from the stack or remove specific entries from history directly from the UI.
- **Stateful Shell Support**: Identify and navigate between stateful shell branches.

## Getting started

Add `zenrouter_devtools` to your `pubspec.yaml`:

```yaml
dependencies:
  zenrouter_devtools: ^latest_version
```

## Usage

To enable the devtools, mix `CoordinatorDebug` into your `Coordinator` class.

### 1. Mixin `CoordinatorDebug`

```dart
class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug<AppRoute> {
  // ... your existing coordinator implementation
}
```

### 2. Configure Debug Features (Optional)

You can customize the devtools by overriding properties in your coordinator:

```dart
class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug<AppRoute> {
  // Only enable in debug mode (default)
  @override
  bool get debugEnabled => kDebugMode;

  // Add quick-access debug routes
  @override
  List<AppRoute> get debugRoutes => [
    const LoginRoute(),
    const UserProfileRoute(id: '123'),
    const SettingsRoute(),
  ];

  // Customize how paths are labeled in the inspector
  @override
  String debugLabel(StackPath path) {
    if (path is NavigationPath) return 'Main Stack';
    return super.debugLabel(path);
  }
}
```

### 3. Accessing the Overlay

Once integrated, a floating action button (FAB) with a bug icon will appear in your app (by default). Click it to open the debug overlay.

- **Inspect Tab**: Shows the current navigation tree. You can see active paths, pop routes, and switch between stateful shell branches.
- **Routes Tab**: Lists your `debugRoutes` for quick navigation.
- **Input Area**: Type a URI (e.g., `/user/123`) and click "Push" or "Replace" to navigate.
