## 3.0.0

Stable Flutter navigation inspection tools for ZenRouter 3.

### Breaking changes

- Require `zenrouter: ^3.0.0` and its manifest, binding, and navigation commit
  APIs. Keep the router and DevTools on the same release line.

### Added

- Interactive Topology graph from `RouteManifest`, with active route
  highlighting and layout relationships.
- Observed runtime flow recorder with directed edges, visit counts, transition
  labels, and a switch between topology and observed graph modes.
- URI-first `NavigationFlowSession` JSON export/import, containing history
  intent, labels, and timestamps. Screenshot bytes stay in memory and are
  excluded from exported sessions.
- Replay sessions with Play/Pause, stepping, speed selection, playhead
  highlighting, a scrubber, and a collapsible event list.
- Optional confirmation-gated Drive navigates the live coordinator to the
  playhead URI. Replay alone leaves the application's navigation state intact.
- Clipboard export and import rematch URIs against the current manifest;
  unmatched URIs are skipped. Live replay holds a recording/capture pause
  lease; importing a session does not itself pause recording.
- Automatic bounded in-memory screen previews on observed nodes, with a capture
  toggle and an overridable default capture setting.
- Floating Stack, horizontal Row, and vertical Column panel layouts, controlled
  by `defaultDebugLayoutMode`, `debugLayoutMode`, and `setDebugLayoutMode`.
- Resizable panel with fullscreen/restore controls and viewport clamping.
- Freely draggable panel header and collapsed launcher, preserving the
  launcher's position when opening and closing the inspector.
- See-through panel surfaces with backdrop blur, controlled by
  `defaultDebugPanelSeeThrough` and `setDebugPanelSeeThrough`. Viewports narrower
  than 600 logical pixels enable this mode until explicitly toggled.
- Compact mobile header, icon-only tabs, and an expandable URI input bar.

### Changed

- Render both graph modes through `vyuh_node_flow` for consistent pan, zoom,
  selection, connections, and viewport fitting.
- Use unified `Flex` split panels and enlarged interaction targets from `hit`
  for narrow resize handles; resizing keeps the opposite corner anchored.
- Keep route screenshots bounded and separate from serialized navigation logs.

### Fixed

- Request a frame when scheduling a preview on an idle screen, so opening the
  recorder captures the app without waiting for another UI update.
- Apply mobile safe-area and keyboard insets to the panel and launcher without
  double-counting the bottom inset.
- Clamp dragged/resized panels and launchers to the current viewport.

### Requirements

- Dart 3.9 or newer; Flutter 3.32 or newer; `zenrouter: ^3.0.0`.
- This is the Flutter inspector. Native apps use the separate
  `zenrouter_dartnative_devtools` 0.1.0 package.

## 3.0.0-beta.1

Prerelease for early testers. APIs may still change before 3.0.0.

- **BREAKING**: Update dependency to `zenrouter: ^3.0.0-beta.1`
- **Feat**: Support **Stack** (floating overlay), **Row** (side-by-side horizontal split), and **Column** (bottom panel vertical split) layout modes for DevTools with an anchored header tool menu (`⋮`), coordinator configuration (`defaultDebugLayoutMode`, `debugLayoutMode`, `setDebugLayoutMode`), and unified `Flex` split panels using `package:hit` for enlarged touch/drag targets on minimal resize handles.
- **Feat**: Add an interactive declarative navigation graph with active route highlighting.
- **Feat**: Add an observed runtime flow recorder with directed edges, visit counts, action labels, and a Graph mode switcher.
- **Feat**: Extract the Observed matched transition log as a URI-first `NavigationFlowSession` JSON document. The document contains URIs, history intent, labels, and timestamps — never PNG previews.
- **Feat**: Replay extracted sessions on the Observed canvas with Play/Pause, step, speed, and playhead highlight. Optional confirm-gated Drive calls `navigate` on the live coordinator for the playhead URI; Play alone does not drive the app.
- **Feat**: Export Observed session JSON to the clipboard and import it by rematching URIs against the current `RouteManifest`. Unmatched URIs are skipped. Live Play pauses recording; Import does not.
- **Feat**: Add an Observed replay timeline with a scrubber and collapsible event list.
- **Feat**: Make the debug panel resizable with fullscreen/restore controls and responsive viewport clamping.
- **Feat**: Make the collapsed devtool launcher freely draggable, position-preserving, and safe-area aware.
- **Feat**: Add automatic, memory-bounded app screen previews to Observed flow nodes with a capture toggle.
- **Changed**: Render Topology and Observed graphs with `vyuh_node_flow` for consistent pan, zoom, selection, connections, and viewport fitting.

## 2.0.0

- **BREAKING**: Update dependency to `zenrouter: ^2.0.0`

## 1.1.1
- **Feat**: Display correct `url` for each `RouteUnique`
- **Feat**: Display better type of `StackPath`
- **Feat**: Display `RouteLayout` in `Inspect Tab`

## 1.1.0
- **BREAKING**: Update dependency to `zenrouter: ^1.2.0`
- **Feat**: New sub module `Coordinator` aware in `Inspect Tab 
- **Feat**: Add `navigate` method
- **Fix**: Fix Increase close button size in `DebugOverlay`

## 1.0.0
- **BREAKING**: Update dependency to `zenrouter: ^1.0.0`
- Support for new `RouteRedirectRule` feature
- Compatible with zenrouter's modular coordinator architecture

## 0.4.5
- Add dependency on `cupertino_icons` fix blank icon in debug overlay

## 0.4.4
- Update `zenrouter` version

## 0.4.3 
- Remove toast notifications

## 0.4.2
- **Docs**: Update README

## 0.4.1
- **Docs**: Update README and add screenshots

## 0.4.0
- Create `example` app
- Update README.md

## 0.3.1
- Bump zenrouter version to 0.4.0

## 0.3.0

- Modularize `DebugOverlay` into separate tabs for better maintainability.
- Add **Problems** tab for detecting layout configuration issues (missing, duplicated, unknown paths).
- Add **Active** tab for visualizing the active layout hierarchy.
- UI improvements: standardized theming, better header, and tab reordering.
- Add support for `recover` function

## 0.2.0

- Bump `zenrouter` version

## 0.1.1

- Fix broken homepage link

## 0.1.0

- Initial release of ZenRouter DevTools.
- Visual debug overlay for inspecting navigation stacks.
- Deep link testing: Push or replace routes by URI.
- Quick access to predefined debug routes.
- Visual stack inspection with support for nested and stateful shells.
