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
- **Observed Session Replay**: Extract the matched transition log as URI-first JSON, then play, step, and scrub it on the Observed canvas. Optional Drive re-issues `navigate` on the live coordinator after a confirm.
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

  // Customize the default layout mode: stack (floating overlay), row (side-by-side), or column (bottom panel)
  @override
  DevToolsLayoutMode get defaultDebugLayoutMode => DevToolsLayoutMode.row;

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

### 3. Layout Modes & Accessing the Overlay

Once integrated, a floating action button (FAB) with a bug icon will appear in your app (by default). Click it to open the debug overlay, or drag the complete URI pill and button to keep it clear of your app's controls. The launcher keeps its position while the panel is opened and closed, and is automatically clamped back into view when the viewport shrinks.

ZenRouter DevTools supports 3 layout modes:
- **Stack Mode (`DevToolsLayoutMode.stack`)**: Floating overlay positioned over your app. Features 2D corner resizing and freely draggable launcher.
- **Row Mode (`DevToolsLayoutMode.row`)**: Side-by-side horizontal split pane. The app occupies the left side while DevTools docks on the right with a draggable edge divider to adjust panel width.
- **Column Mode (`DevToolsLayoutMode.column`)**: Top-and-bottom vertical split pane. The app occupies the top area while DevTools docks at the bottom with a draggable edge divider to adjust panel height.

You can switch layout modes on the fly using the header tool menu (`⋮`) or programmatically via `coordinator.setDebugLayoutMode(mode)`.

The expanded panel preserves your custom resized dimensions and supports fullscreen maximize/restore in all layout modes.

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

## Observed session extract and replay

The Observed canvas records every **matched** navigation commit as a chronological log and collapses that log into the directed journey graph. The replayable unit is that matched log, extracted as a versioned, URI-first JSON document (`NavigationFlowSession`). Unmatched commits stay out of the log; they only increment the header unmatched count.

Replay is graph and timeline playback of that document. **Play** does not move the live app. Arm **Drive** (car icon) after a confirm to call `coordinator.navigate` for each playhead URI. Drive is not a faithful stack restore: `pop` and `replace` both published as `replace`, so Drive only uses `navigate`. Redirects may re-run, and `navigate` to a URI already on the stack may pop and consult `RouteGuard`. Compass and **Navigate Here** remain one-shot live jumps.

### Session JSON

`NavigationFlowSession` stores `initialUri`, timestamps, history intent, optional `debugFlowAction` labels, and URI pairs. Optional route ids are display hints only. The document does **not** include screen previews or PNG / base64 image data.

**Export** always copies the current live `NavigationFlowSession` to the clipboard — never the hydrated or imported document — and does not exit replay. From live, you stay on the live graph. **Import** pastes the same JSON and rematches each URI against the **current** `RouteManifest`. Unmatched URIs are skipped. If every imported row fails rematch, transport stays disabled and the banner says `Imported session did not match this manifest.`

```json
{
  "schemaVersion": 1,
  "kind": "zenrouter.devtools.observedSession",
  "exportedAt": "2026-08-17T12:00:00.000Z",
  "initialUri": "/",
  "ignoredTransitionCount": 0,
  "transitions": [
    {
      "revision": 1,
      "previousUri": "/",
      "currentUri": "/profile",
      "historyIntent": "push",
      "actionLabel": "Open profile",
      "occurredAt": "2026-08-17T12:00:01.250Z"
    }
  ]
}
```

### Canvas playback

When the matched log is not empty, a transport row appears under the Observed header:

- **Play / Pause**, step back / forward, and jump to start / end
- **Drive** (car icon) arms live `navigate` after a confirm; step and Play then move the real coordinator
- **Speed** cycles 0.5× / 1× / 2× / 4×
- **Timeline** opens a slider and a collapsible event list for scrubbing
- **Export** copies the live session JSON (even during replay); **Import** loads a pasted document
- **Exit replay** (visible only while replaying)

Play highlights the playhead's from / to nodes on the existing canvas, shows the best available in-memory preview (live export only), and updates `REPLAY i / n`. Opening the timeline from live enters paused replay on the last event. Tap a timeline row or drag the slider to seek.

### Recording during replay

**Live Play** (Play, step, jump, or timeline from the current session) exports the in-memory log and **pauses recording**. Navigations during that replay — including Drive — are not added to the session. The banner says `Recording paused for replay. Navigations will not be added to this session.` Recording resumes when you Exit replay, leave Observed, leave Graph, or close the overlay. Drive from an imported session also takes a lease so driven `navigate` calls are not recorded.

**Import** loads a pasted document and does **not** pause live recording. The live recorder keeps recording; Exit discards the imported document and shows the live graph again.

### Previews and privacy

Screen previews capture only the app layer, not the devtool overlay. They are downscaled, kept **in memory only**, limited to the 24 most recently previewed routes, and discarded when the Observed flow is cleared. Capture can fail gracefully for platform views or cross-origin web images that Flutter cannot rasterize.

Replay never writes previews to disk or into the extract. The document contains only URIs and labels the developer already saw in the overlay. Previews are latest-per-route, not per-event. When replay falls back to a later visit's frame, the caption is `Preview from a later visit`. Imported documents have no previews.
