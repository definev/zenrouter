## 3.0.0

- **BREAKING**: Update dependency to `zenrouter: ^3.0.0`
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
