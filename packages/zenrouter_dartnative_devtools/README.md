# ZenRouter DartNative DevTools

Native in-app navigation inspector for `zenrouter_dartnative`. The 0.1.0
package is separate from the Flutter `zenrouter_devtools` package and has no
Flutter or `vyuh_node_flow` dependency.

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

Graph, observed flow, replay, and screen previews are not part of this initial
package.

## Setup

Until publication, add this package to a DartNative app locally and run
`dn pub get`:

```yaml
dependencies:
  zenrouter_dartnative_devtools:
    path: /path/to/zenrouter/packages/zenrouter_dartnative_devtools
```

For local development, override `zenrouter_dartnative` and `zenrouter_core`
to the sibling packages in the checkout. After publication, use
`zenrouter_dartnative_devtools: ^0.1.0` instead of the path dependency.

Decorate every presentation through `CoordinatorView.presentationBuilder` and
place `NativeDevToolsLauncher` in each screen's `Scaffold.floatingActionButton`
(or AppBar actions). This preserves the Scaffold's native layout and safe area.
Keep one controller for the app's lifetime so the selected tab survives pushes.
The launcher reads the screen brightness when available. If the screen forces
`Scaffold(brightness: ...)`, pass the same value to
`NativeDevToolsLauncher(brightness: ...)` so the separately hosted sheet and its
native material follow that appearance even when the system theme differs.

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
      debugRoutes: [Uri.parse('/'), Uri.parse('/item/42')],
      child: child,
    );
  },
));

// In each screen's native Scaffold:
Scaffold(
  appBar: AppBar(title: const Text('Home')),
  floatingActionButton: const NativeDevToolsLauncher(),
  body: const Text('Hello'),
);
```

Dispose the controller when the app shuts down. The launcher opens a native
adaptive modal sheet on iOS and a modal bottom sheet on Android. The Android
sheet starts at half height and can be dragged to full height. It includes a
drag handle and an in-content close button, with the URI field
and its actions at the top and compact text tabs below. The iOS URI field stays
at the bottom. Both the URI field and quick routes have three direct icon
buttons: right arrow for Navigate, stacked plus for Push, and cycling arrows
for Replace. Actions run while the sheet stays open, including `Pop`, so you can
perform several operations in sequence. `Push` uses `pushSilently` so DevTools
waits for a navigation commit rather than a future route result. `Replace`
clears the navigation tree. Quick route URIs are resolved through the same
coordinator route parser as the URI input.

DevTools owns its native sheet separately from Navigator's sheet stack on both
platforms. The inspector's Pop action removes the app route while the DevTools
sheet remains open; its close button dismisses only the inspector.

The launcher is mounted in each native Scaffold, so it remains available after
a push, including on screens above the root. It hides itself in release builds.
