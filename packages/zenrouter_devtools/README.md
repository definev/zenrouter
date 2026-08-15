<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

# ZenRouter DevTools

A powerful debugging tool for [ZenRouter](https://pub.dev/packages/zenrouter), providing a visual overlay to inspect navigation stacks, test deep links, and manage routes.

[![pub package](https://img.shields.io/pub/v/zenrouter_devtools.svg)](https://pub.dev/packages/zenrouter_devtools)
[![Codecov - zenrouter](https://codecov.io/gh/definev/zenrouter/branch/main/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?branch=main&flags=zenrouter)

</div>

## Features

- **Visual Stack Inspection**: View the current navigation hierarchy, including active paths, nested routers, and their stack history.
- **Navigation Graph**: Explore the declarative route topology, layout branches, URI patterns, and the highlighted path to the currently matched route.
- **Observed Runtime Flow**: Record real route-to-route transitions while using the app, including direction, visit counts, history intent, and optional action labels.
- **Screen Previews**: See low-resolution screenshots of the real app screen inside Observed flow nodes, with an in-panel privacy toggle and bounded memory use.
- **Resizable Debug Panel**: Drag the panel's top-left corner to resize it, or maximize and restore it from the header when a large graph needs more space.
- **Movable Launcher**: Drag the collapsed URI pill and bug button anywhere in the safe viewport; its position survives opening and closing the panel.
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

  // Disable automatic in-memory screenshots for sensitive apps
  @override
  bool get debugCaptureRouteScreenshots => false;

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

Once integrated, a floating action button (FAB) with a bug icon will appear in your app (by default). Click it to open the debug overlay, or drag the complete URI pill and button to keep it clear of your app's controls. The launcher keeps its position while the panel is opened and closed, and is automatically clamped back into view when the viewport shrinks.

The expanded panel defaults to `420 × 500` on desktop. Drag the resize handle in its top-left corner for a custom size, or use the fullscreen control in the header. Custom dimensions are preserved when toggling fullscreen and automatically clamped when the viewport becomes smaller.

- **Inspect Tab**: Shows the current navigation tree. You can see active paths, pop routes, and switch between stateful shell branches.
- **Graph Tab / Topology**: Shows coordinators, layouts, and routes from `routeManifest`. Pan or zoom the canvas, select nodes for details, and follow the green path to the route matching the current URI.
- **Graph Tab / Observed**: Builds a directed journey graph from real navigation commits. Edges show the latest action and traversal count; nodes show visits, the last concrete URI, and a preview of the real app screen. Recording and preview capture start automatically when the devtool attaches. Use the camera button to pause capture or the trash button to clear the graph.
- **Routes Tab**: Lists your `debugRoutes` for quick navigation.
- **Input Area**: Type a URI (e.g., `/user/123`) and click "Push" or "Replace" to navigate.

The Graph tab appears automatically when the coordinator exposes a non-empty declarative manifest, including generated and composed manifests. Runtime transitions are recorded without additional annotations. To replace an inferred `push` or `replace` label with a product-facing action name, wrap the navigation call:

```dart
onPressed: () => coordinator.debugFlowAction(
  'Open profile',
  () => coordinator.push(const ProfileRoute()),
);
```

Screen previews capture only the app layer, not the devtool overlay. They are downscaled, kept in memory only, limited to the 24 most recently previewed routes, and discarded when the Observed flow is cleared. Capture can fail gracefully for platform views or cross-origin web images that Flutter cannot rasterize.
