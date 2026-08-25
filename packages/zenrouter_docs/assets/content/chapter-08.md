Bottom navigation is a product contract, not merely an integer. Before choosing a path, decide whether each tab is one fixed destination or a mini-application with its own retained history.

## Two valid tab models

| Promise to the user | Path |
| --- | --- |
| “Switch destinations; each tab is one screen.” | `IndexedStackPath` |
| “Return to this tab exactly where you left it.” | `BranchedStackPath` |

Using the wrong model usually appears as duplicate roots, detail pages disappearing on tab changes, or one global stack whose back behavior crosses unrelated tabs.

## Fixed destinations with IndexedStackPath

An indexed path owns a fixed route list and one active index:

```dart
late final tabsPath = IndexedStackPath<AppRoute>.createWith(
  [HomeTabRoute(), SearchTabRoute(), ProfileTabRoute()],
  coordinator: this,
  label: 'main-tabs',
)..bindLayout(TabsLayout.new);
```

The layout renders the path and observes selection:

```dart
class TabsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(
    covariant AppCoordinator coordinator,
  ) => coordinator.tabsPath;

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: ListenableBuilder(
        listenable: coordinator.tabsPath,
        builder: (context, _) => NavigationBar(
          selectedIndex: coordinator.tabsPath.activeIndex,
          onDestinationSelected: coordinator.tabsPath.activateAt,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
```

Use this model when a tab selection is the entire state. It keeps each fixed child alive, but it does not give each tab an independent push stack.

## Retained navigation with BranchedStackPath

A branched path has fixed branch layouts. Every branch layout owns its own child `NavigationPath`:

```text
AppShellLayout
├── HomeBranchLayout
│   └── homePath: Home → Article 42
├── SearchBranchLayout
│   └── searchPath: Search → Result 9
└── ProfileBranchLayout
    └── profilePath: Profile
```

Create and bind the branch selector:

```dart
late final branches = BranchedStackPath<AppRoute>.createWith(
  [
    HomeBranchLayout(),
    SearchBranchLayout(),
    ProfileBranchLayout(),
  ],
  coordinator: this,
  label: 'app-branches',
)..bindLayout(AppShellLayout.new);
```

Register each branch's child path in `coordinator.paths`. Switch branches without mutating their child stacks:

```dart
await coordinator.branches.goToBranch(1);
```

When the user returns to Home, `homePath` still contains `ArticleRoute('42')` if that is the promised behavior.

## Manifest topology

The static graph must describe the same fixed branch roots:

```dart
RouteManifestLayout.branched(
  id: AppRouteId.shell,
  path: '/',
  childIds: [
    AppRouteId.homeBranch,
    AppRouteId.searchBranch,
    AppRouteId.profileBranch,
  ],
),
```

Every child ID must refer to a direct child layout, not a leaf route. The owning Coordinator validates missing roots and duplicate branch membership.

## Reselect behavior

A second tap on the active tab needs an explicit product rule:

- preserve the current detail route;
- pop the branch to its root;
- scroll the current root to the top;
- refresh the current content.

Do not implement reset by pushing the root again. That creates equal duplicate entries and makes the system back button surprising. Reset or navigate within the active child path deliberately.

## Deep links into a branch

When `/search/results/9` arrives, the manifest identifies the search branch parent. The Coordinator activates the shell, selects Search, prepares `searchPath`, and commits the result route. Other branch stacks remain available unless the deep-link strategy replaces the entire application context.

## Failure modes

**One global path for every tab.** Back crosses tab history and selection becomes a side channel.

**Indexed routes with detail pushes.** There is nowhere to retain per-tab depth. Use branch layouts with child paths.

**The bottom bar owns its own route list.** Selection, restoration, and the router can disagree. Read the active index from the path.

**Branches are leaf routes in the manifest.** Branched children must be layouts because each one owns a child stack.

## Checkpoint

Open a three-deep route in Home, switch to Search and open a result, then return to Home. Verify the exact product promise: retained depth or an explicit reset—never accidental behavior.

Next, **URLs, parameters, and 404s** makes every branch location reproducible from outside the app.
