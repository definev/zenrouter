Routing bugs are difficult when the only evidence is the last widget on screen. ZenRouter DevTools exposes the static graph, active paths, validation problems, and observed navigation commits so you can diagnose the seam that failed.

## Enable the overlay

Add the package:

```bash
flutter pub add zenrouter_devtools
```

Mix debugging into the Coordinator:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug<AppRoute> {}
```

Debug behavior defaults to development-safe settings. Sensitive applications can disable in-memory route screenshots:

```dart
@override
bool get debugCaptureRouteScreenshots => false;
```

The panel supports floating, side-by-side, and bottom-docked layouts. Choose the mode that leaves the application interaction visible while reproducing a flow.

## Inspect active navigation state

The Inspect tab shows the current layout and path tree. Use it to answer:

- which path owns the active route;
- which nested layouts are active;
- how deep every stack is;
- which branched shell is selected;
- whether a pop changes the expected child path.

If the correct target is in the wrong path, inspect route layout resolution and path registration before debugging screen widgets.

## Read graph topology

The Graph tab appears when the Coordinator exposes a non-empty manifest. Topology is static: routes, layouts, parent edges, patterns, and the route matching the current URI.

Use topology to find:

- an unexpected manifest parent;
- a missing layout node;
- a route absent from the composed graph;
- a generated path that differs from the intended public URL;
- an indexed or branched child attached to the wrong owner.

If the Graph tab is empty, verify that the Coordinator or composed modules expose `routeManifest` rather than relying only on a handwritten parser.

## Observe runtime flow

Observed flow is built from real `NavigationCommit`s. Nodes represent matched routes; edges show the latest action and traversal count. Parameterized locations such as `/items/1` and `/items/2` remain one route node with visible URI variants.

Label an important product action without changing navigation semantics:

```dart
await coordinator.debugFlowAction(
  'Open article from search',
  () => coordinator.push(ArticleRoute('42')),
);
```

The observed graph helps distinguish “the graph allows this edge” from “users actually traversed this edge in the reproduced session.”

## Replay a session

DevTools records a chronological, URI-first `NavigationFlowSession`. Export copies versioned JSON containing locations, timestamps, history intent, and optional action labels. It does not embed screen preview images.

```json
{
  "schemaVersion": 1,
  "kind": "zenrouter.devtools.observedSession",
  "initialUri": "/",
  "transitions": [
    {
      "revision": 1,
      "previousUri": "/",
      "currentUri": "/articles/42",
      "historyIntent": "push",
      "actionLabel": "Open article from search"
    }
  ]
}
```

Import rematches every URI against the current manifest. Unknown locations are skipped, making an old report useful after a graph revision without trusting stale route IDs.

Normal replay animates the graph and timeline; it does not navigate the live app. **Drive** explicitly calls `navigate` for each playhead URI after confirmation. Drive is a diagnostic approximation, not full stack restoration: redirects and guards may run again, and replace/pop distinctions cannot always be reconstructed from the final URI alone.

## Debug in graph order

When an incoming link fails, inspect:

1. **Topology:** does the manifest contain one deterministic match?
2. **Binding:** did the match create the expected typed values?
3. **Policy:** did redirect or deep-link recovery change the target?
4. **Layout:** did the target resolve the correct parent path?
5. **Commit:** what final URI and history intent were published?
6. **Render:** did the route builder receive the expected values?

This order is faster than starting from widget ancestry because it follows the transaction itself.

## Privacy and limitations

Screen previews are downscaled, limited, kept in memory, and excluded from exported sessions. Platform views and cross-origin web images may not render in a captured preview. Disable capture when the app shows sensitive information.

An unmatched commit increments diagnostics but cannot become a typed graph node. Treat a growing unmatched count as evidence that navigation is bypassing or outgrowing the declared manifest.

## Checkpoint

Open the overlay, reproduce one failed or surprising link, and name the exact seam where observed behavior diverges from topology. Export the session and confirm it contains URIs and labels but no image data.

Next, **Test navigation contracts** turns the same seams into fast, deterministic tests.
