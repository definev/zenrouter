The most valuable router tests prove contracts at the graph seams. They do not need to pump the whole application for every assertion. Start with pure manifest and binding tests, then add Coordinator and widget tests only where Flutter behavior matters.

## 1. Validate graph construction

Invalid topology should fail before navigation begins. Test the invariants your feature composition depends on:

```dart
test('rejects equivalent dynamic patterns', () {
  expect(
    () => RouteManifest(
      name: 'app',
      routes: [
        RouteManifestRoute(id: 'by-id', path: '/users/:id'),
        RouteManifestRoute(id: 'by-name', path: '/users/:name'),
      ],
    ),
    throwsA(isA<RouteManifestValidationException>()),
  );
});
```

Also cover duplicate IDs, unknown parents, layout cycles, invalid fixed children, and conflicts introduced only after composing fragments.

## 2. Test match and reverse routing together

Every public pattern should round-trip:

```dart
test('article location round trips', () {
  final uri = manifest.location(
    AppRouteId.article,
    pathParameters: {'id': 'core team'},
    queryParameters: {'view': 'compact'},
  );

  final match = manifest.match(uri)!;

  expect(match.id, AppRouteId.article);
  expect(match.pathParameters['id'], 'core team');
  expect(match.uri.queryParameters['view'], 'compact');
});
```

Include encoded spaces, reserved characters, catch-all segments, query values, and static-versus-dynamic precedence. Reverse generation should reject missing and unexpected parameters instead of emitting a malformed URL.

## 3. Test bindings without widgets

A binding test proves matched values become the correct target:

```dart
test('binding constructs typed article route', () async {
  final registry = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(
        id: AppRouteId.article,
        create: (match) => ArticleRoute(
          match.pathParameters['id']!,
        ),
      ),
    ],
    notFound: NotFoundRoute.new,
  );

  final route = await registry.resolve(Uri.parse('/articles/42'));

  expect(route, isA<ArticleRoute>());
  expect((route as ArticleRoute).id, '42');
});
```

Registry construction should also reject duplicate bindings, unknown IDs, bindings for layout nodes, and unbound manifest routes.

## 4. Test Coordinator transactions

At the Coordinator layer, assert observable state rather than implementation calls:

```dart
await coordinator.pushSilently(ArticleRoute('42'));

expect(coordinator.activeRoute, ArticleRoute('42'));
expect(coordinator.currentUri, Uri.parse('/articles/42'));
expect(coordinator.lastNavigationCommit!.revision, 1);
expect(
  coordinator.lastNavigationCommit!.historyIntent,
  NavigationHistoryIntent.push,
);
```

For nested layouts, assert the owning path changed and unrelated paths did not. For `navigate`, test both the pop-to-existing and push-when-absent branches. For `replace`, assert all old paths were reset.

## 5. Test results, guards, and redirects

Push a route, pop it with a result, and assert the original future completes exactly once. A guard test should prove both blocked and allowed behavior, including no URI or revision change when blocked.

Redirect tests need at least:

- condition false → original target commits;
- condition true → fallback target commits;
- continuation URI is preserved;
- fallback is not redirected into a loop;
- async policy errors are surfaced rather than partially mutating paths.

Plain `GuardRule` and redirect-rule classes can usually be tested without a widget tree.

## 6. Add widget tests at Flutter seams

Use widget tests for behavior that exists only after rendering:

- a `RouteLayout` keeps shell chrome while the child path changes;
- a `NavigationStack` uses the expected transition;
- system back and `PopScope` observe `canPop` changes;
- a generated route builds the right screen from typed parameters;
- restoration occurs before the first stable frame;
- bottom navigation reflects active indexed or branched state.

Avoid loading real repositories in route widget tests. Inject a fake domain store and keep the route value small.

## 7. Verify generated graphs

For file routing, run the generator in CI and fail if it leaves a diff. Add a focused manifest test that asserts critical paths and generated locations, especially after moving dynamic files or layouts.

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```

## A practical test matrix

| Contract | Fastest test |
| --- | --- |
| Pattern validity and specificity | Pure manifest unit test |
| Location encoding | Manifest round-trip test |
| Parameter-to-route conversion | Binding registry unit test |
| Layout/path mutation | Coordinator test |
| Guard and result lifecycle | Path/Coordinator test |
| Shell rendering and system back | Widget test |
| Process restoration | Restoration widget/integration test |
| Browser address/history behavior | Web integration test |
| Generated output stability | CI generation + diff |

## Common testing mistakes

**Only pumping the final screen.** A correct widget does not prove matching, layout ownership, or browser intent.

**Asserting private list mutations.** Test active routes, URIs, commits, and results—the contracts consumers observe.

**Skipping failure tests.** Validation is a feature. Prove bad graphs fail loudly.

**Using one giant end-to-end test.** It is slow and cannot localize which seam failed. Keep a small number of browser tests over a broad base of pure contract tests.

## Checkpoint

Before adding another production recipe, add one manifest round-trip test, one binding test, one transaction/commit test, and one policy test. A failure should tell you whether topology, construction, state mutation, or rendering broke.

Next, the field guides apply these contracts to authentication, bottom navigation, state management, and migration.
