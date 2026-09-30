## 0.1.0

Initial native in-app navigation inspector for `zenrouter_dartnative` 0.1.0.

### Inspection and navigation

- `NativeDevTools<T>` decorates route presentations and provides the inspector
  scope; `NativeDevToolsController` preserves the selected tab across screens.
- Inspect stack, indexed, and branched paths, route URIs, retained inactive
  branch routes, the active path chain, and the current coordinator URI.
- Pop the active stack and select indexed routes or branches directly from
  their groups. Inactive child paths remain read-only until selected.
- Navigate, push, and replace through a URI input and configurable quick-route
  URIs, resolved by the application's coordinator parser.
- Push uses `pushSilently` to await commitment instead of a later pop result;
  Replace resets the navigation tree. Actions leave the inspector open so
  several navigation operations can be inspected in sequence.

### Native inspector UI

- `NativeDevToolsLauncher` integrates with each screen's native Scaffold
  floating action button or AppBar actions and remains available after pushes.
  It hides itself in release builds.
- Present an adaptive native modal sheet on iOS and a bottom sheet on Android.
  The Android sheet starts at half height, supports expansion to full height,
  and includes a drag handle and in-content close button.
- Keep the Android URI field and actions above the scrollable inspector and
  compact tabs, avoiding obstruction by the keyboard.
- Position the iOS URI bar at the bottom and follow the keyboard during editing.
- Provide direct Navigate, Push, and Replace buttons for both the URI input and
  quick routes.
- Apply grouped system light/dark colors and native sheet materials, including
  iOS 26 Liquid Glass controls. An explicit launcher brightness can follow a
  screen that overrides the system theme.

### Sheet lifecycle

- Own the DevTools sheet independently of the application's Navigator stack;
  popping an app route leaves the inspector open, and closing the inspector
  dismisses only its own surface.
- Coalesce repeated open requests while a previous sheet is closing.
- Recover opening after a missing native dismissal callback; release the opening
  lock after presentation failure.
- Ignore completion from old sheets after a replacement opens, and prevent a
  pending reopen from presenting a new sheet after controller disposal.

### Requirements and scope

- Dart 3.9 or newer; DartNative SDK/framework 1.0.0;
  `zenrouter_dartnative: ^0.1.0`.
- This package has no Flutter or `vyuh_node_flow` dependency. Topology graphs,
  observed flow recording, replay, and screen previews are outside the 0.1.0
  feature set.
- Decorate every route through `CoordinatorView.presentationBuilder`, keep one
  controller for the app lifetime, and dispose it during application shutdown.
- Resolve SDK dependencies with `dn pub get`. Public publication has the same
  framework dependency/registry gate as `zenrouter_dartnative`.
