ZenRouter is useful when navigation has a life outside the widget that triggered it: a browser URL, an incoming notification, a restoration payload, a test, or another feature that needs to open the same destination.

By the end of this chapter you will know what problem ZenRouter owns, what it deliberately leaves to Flutter, and whether the rest of this guide matches your application.

## The problem

A small Flutter app can navigate with `Navigator.push` and a few page builders. The trouble begins when the same screen must also be opened from `/articles/42`, restored after process death, embedded below a persistent shell, and reached from a notification.

Without an explicit model, the app usually grows several partial route tables:

- a widget callback that constructs the page;
- a URI parser that constructs it again;
- a browser-history update with another string path;
- a restoration converter with a slightly different set of parameters;
- tests that know implementation details instead of navigation behavior.

These copies drift. A link can display the right screen while the back stack is wrong, or the stack can be right while the address bar lies.

## The ZenRouter model

ZenRouter treats navigation as a typed graph with a small number of jobs:

| Concept | Owns |
| --- | --- |
| `RouteTarget` | A typed destination and its stable parameters |
| `StackPath` | The ordered or indexed navigation state |
| `RouteLayout` | The shell that renders a child path |
| `RouteManifest` | Static route IDs, URL patterns, and layout parents |
| `RouteBinding` | Construction of a Flutter route from a manifest match |
| `Coordinator` | Navigation transactions, recovery, URL state, and history intent |

The important separation is between **topology** and **presentation**. The manifest says that `article` lives at `/articles/:id`; it does not import an article widget. A binding receives the matched `id` and creates `ArticleRoute(id)`. The route can then build the screen at the Flutter boundary.

```text
RouteManifest → match → RouteBinding → RouteTarget → StackPath → commit
```

The same manifest performs reverse routing, so constructing `/articles/42` and matching `/articles/42` use one pattern rather than two hand-maintained strings.

## What ZenRouter does not replace

ZenRouter does not replace your domain store, dependency injection, or UI architecture. Routes should carry stable navigation facts—IDs, filters, selected branches—not loaded models or service objects. Riverpod, Bloc, Provider, or another store can load the article after `ArticleRoute('42')` selects it.

It also does not force every local flow through the application coordinator. An onboarding wizard can use an imperative `NavigationPath`; a state-derived editor can use a declarative stack; the app boundary can use a Coordinator for URLs and browser history.

## Release status

This edition targets `zenrouter` **3.0.0-beta.1**. Because it is a prerelease, a plain `flutter pub add zenrouter` may still select the stable 2.x line. Pin the beta while following the examples:

```yaml
dependencies:
  zenrouter: ^3.0.0-beta.1
```

The recommended 3.0 path uses `RouteManifest` and `RouteBinding`. Handwritten `parseRouteFromUri` remains available for compatibility and small graphs, but this guide introduces the manifest first so forward matching and reverse URLs cannot drift.

## When the library is a good fit

Continue when one or more of these are true:

- your app has deep links or meaningful web URLs;
- nested shells or tabs own independent navigation state;
- browser back/forward behavior is part of the product contract;
- routes must be restored or tested without reconstructing widget history;
- several features contribute to one route graph;
- you want routing failures to appear during graph construction rather than after release.

For a two-screen mobile-only flow with no external entry points, Flutter's `Navigator` may already be the smallest honest tool.

## Checkpoint

Explain the library without naming a widget:

> ZenRouter keeps the typed route graph, URL model, rendered stacks, and navigation history connected.

If that sentence describes a real problem in your app, continue to **Choose a navigation model**. The next chapter helps you avoid putting every navigation decision into the Coordinator.
