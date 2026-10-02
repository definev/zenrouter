# ZenRouter DartNative DevTools

<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

**Native in-app navigation inspector and URI actions for DartNative.**

[![pub package](https://img.shields.io/pub/v/zenrouter_dartnative_devtools.svg)](https://pub.dev/packages/zenrouter_dartnative_devtools)

</div>

---

Native in-app navigation inspector for `zenrouter_dartnative`, designed
specifically for DartNative runtime environments.

## Features

- Inspect paths by Stack, Branched, and Indexed context, including route URIs
  and the saved routes of inactive branches.
- Pop the active stack or select an indexed route or branch directly from its
  group. Inactive child paths stay read-only until their branch is selected.
- View the active path chain and current URI separately from the URI input.
- Navigate, push, or replace from a URI.
- Configure quick routes with a list of destination URIs.
- Keep URI controls above the scrollable inspector on Android, where the
  keyboard cannot cover a bottom-pinned field. On iOS, the bottom input bar
  follows the on-screen keyboard while editing.
- Use the native sheet surface and iOS 26 Liquid Glass controls, with grouped
  system-style light and dark colors for the content and older iOS versions.

Graph, observed flow, replay, and screen previews belong to graph-canvas
tooling and are not part of this native package.

## Installation

Add `zenrouter_dartnative_devtools` to your DartNative app's `pubspec.yaml`:

```yaml
dependencies:
  dartnative: ^1.0.0
  zenrouter_dartnative: ^0.1.1
  zenrouter_dartnative_devtools: ^0.1.1
```

Run **`dn pub get`** to install.

## Usage

### 1. Presentation builder

Decorate every presentation through `CoordinatorView.presentationBuilder` and
keep one `NativeDevToolsController` for the app's lifetime so the inspector's
selected tab survives pushes.

```dart
final coordinator = AppCoordinator();
final devTools = NativeDevToolsController();

runApp(CoordinatorView<AppRoute>(
  coordinator: coordinator,
  onError: (error, stack) => dnLog('$error\n$stack'),
  presentationBuilder: (context, child) {
    if (const bool.fromEnvironment('dart.vm.product')) return child;
    return NativeDevTools<AppRoute>(
      coordinator: coordinator,
      controller: devTools,
      debugRoutes: [
        Uri.parse('/'),
        Uri.parse('/shelf'),
        Uri.parse('/lot/yirga'),
      ],
      child: child,
    );
  },
));
```

### 2. Scaffold launcher

Place `NativeDevToolsLauncher` in each screen's `Scaffold.floatingActionButton`
(or AppBar actions). This preserves the Scaffold's native layout and safe area:

```dart
Scaffold(
  appBar: AppBar(title: const Text('Home')),
  floatingActionButton: const NativeDevToolsLauncher(),
  body: const Text('Hello'),
);
```

The launcher reads the screen brightness when available. If the screen forces
`Scaffold(brightness: ...)`, pass the same value to
`NativeDevToolsLauncher(brightness: ...)` so the separately hosted sheet and its
native material follow that appearance even when the system theme differs. The
launcher is hidden automatically in release builds.

### 3. Inspector controls and actions

Both the URI input field and quick routes provide three direct actions:

| Action | Icon | Behavior |
|---|---|---|
| **Navigate** | Right arrow | Pops back to an existing route, or pushes if absent |
| **Push** | Stacked plus | Calls `pushSilently` to commit without waiting for result |
| **Replace** | Cycling arrows | Resets the navigation tree to the selected destination |
| **Pop** | Pop button | Removes the active route while DevTools remains open |

Actions execute while the inspector sheet stays open, allowing multiple
navigation operations to be tested in sequence. DevTools owns its native sheet
separately from Navigator's sheet stack on both platforms; closing the inspector
never affects app navigation state.

## Platform behavior

| Platform | Sheet surface | Input and keyboard layout |
|---|---|---|
| **iOS** | Native adaptive modal sheet with Liquid Glass controls | Bottom-docked input bar following the on-screen keyboard |
| **Android** | Half-height modal bottom sheet draggable to full height | Top-anchored URI bar and actions avoiding keyboard overlap |
