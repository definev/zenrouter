This recipe implements bottom navigation where Home, Search, and Profile each retain an independent detail stack. If your product wants fixed single-screen tabs, use the smaller `IndexedStackPath` model from chapter 8 instead.

## Product contract

We will implement:

- switching tabs does not push a route;
- each tab retains its current depth;
- a deep link selects the correct branch;
- tapping the active tab again pops that branch to its root;
- system back pops inside the active branch before leaving the shell.

## Path topology

```text
AppShellLayout (BranchedStackPath)
├── HomeBranchLayout
│   └── homePath: HomeRoute → ArticleRoute
├── SearchBranchLayout
│   └── searchPath: SearchRoute → SearchResultRoute
└── ProfileBranchLayout
    └── profilePath: ProfileRoute → AccountRoute
```

Every branch entry is a layout because it owns a child path.

## Create child paths

```dart
late final homePath = NavigationPath<AppRoute>.createWith(
  label: 'home-branch',
  coordinator: this,
)..bindLayout(HomeBranchLayout.new);

late final searchPath = NavigationPath<AppRoute>.createWith(
  label: 'search-branch',
  coordinator: this,
)..bindLayout(SearchBranchLayout.new);

late final profilePath = NavigationPath<AppRoute>.createWith(
  label: 'profile-branch',
  coordinator: this,
)..bindLayout(ProfileBranchLayout.new);
```

Create the fixed branch selector and bind the outer shell:

```dart
late final branches = BranchedStackPath<AppRoute>.createWith(
  [
    HomeBranchLayout(),
    SearchBranchLayout(),
    ProfileBranchLayout(),
  ],
  label: 'main-branches',
  coordinator: this,
)..bindLayout(AppShellLayout.new);

@override
List<StackPath> get paths => [
  ...super.paths,
  branches,
  homePath,
  searchPath,
  profilePath,
];
```

Stable, unique labels let restoration distinguish the three histories.

## Render the bottom bar

```dart
class AppShellLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  BranchedStackPath<AppRoute> resolvePath(
    covariant AppCoordinator coordinator,
  ) => coordinator.branches;

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) {
    final branches = coordinator.branches;

    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: ListenableBuilder(
        listenable: branches,
        builder: (context, _) => NavigationBar(
          selectedIndex: branches.activeBranchIndex,
          onDestinationSelected: (index) async {
            if (index == branches.activeBranchIndex) {
              await coordinator.resetActiveBranchToRoot();
            } else {
              await branches.goToBranch(index);
            }
          },
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

`resetActiveBranchToRoot` is application policy, not a ZenRouter magic method: implement it by popping or resetting only the selected child path. This makes the reselect promise explicit and testable.

## Assign routes to branch layouts

```dart
class ArticleRoute extends AppRoute {
  ArticleRoute(this.id);
  final String id;

  @override
  Type? get layout => HomeBranchLayout;

  @override
  List<Object?> get props => [id];
}

class SearchResultRoute extends AppRoute {
  SearchResultRoute(this.query);
  final String query;

  @override
  Type? get layout => SearchBranchLayout;
}
```

The Coordinator resolves the target's branch layout, activates the outer shell, selects the branch, and mutates only its child path.

## Declare the manifest branches

The manifest mirrors runtime ownership:

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
RouteManifestLayout.stack(
  id: AppRouteId.homeBranch,
  path: '/',
  parentId: AppRouteId.shell,
),
```

Add equivalent stack layouts for Search and Profile, then attach each leaf route to its branch with `parentId`.

## Deep-link behavior

Opening `/search/results/flutter` should:

1. match the result leaf under Search;
2. activate `AppShellLayout`;
3. select `SearchBranchLayout`;
4. prepare `searchPath`;
5. commit `SearchResultRoute('flutter')`;
6. leave Home and Profile histories untouched when policy allows.

Whether an external link preserves other branches or replaces the complete context is a `RouteDeepLink` strategy decision. Test it explicitly.

## Back behavior

Coordinator pop searches active mutatable paths from deepest to outermost and pops one eligible path. A detail page in Search leaves before the application shell. When every branch is at its root, the platform can leave the app according to host behavior.

## Failure modes

**The bar pushes branch roots.** Tab taps create duplicates. Select the branch path instead.

**Detail routes name the outer shell.** They land in the branch selector rather than its child stack. Name the branch layout.

**Reselect resets all paths.** Other tabs lose retained state. Target only the active child path.

**Branches are not in the manifest.** Deep links may render a leaf without reconstructing the correct shell topology.

## Checkpoint

Create independent two-deep histories in Home and Search. Switch repeatedly, deep-link into Profile, reselect each active tab, and use system back. Assert selection and all three path stacks after every step.

Next, **State management** defines what belongs in those route values and what stays in domain stores.
