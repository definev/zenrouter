Migrate by product contract and concept, not by replacing method names. Start with one vertical slice—root, detail, shell, deep link, and back behavior—and compare what users can observe before expanding the migration.

## Concept map

| Familiar concept | ZenRouter seam |
| --- | --- |
| Navigator page or named route | typed `RouteTarget` |
| `Navigator.push` / `pop` | `NavigationPath` or Coordinator `push` / `pop` |
| Navigator 2 page list | declarative `NavigationStack` |
| route table / parser | `RouteManifest` + `RouteBinding` |
| route information restore | manifest location + Coordinator commit |
| shell / nested route | `RouteLayout` + owned child path |
| tab shell with retained stacks | `BranchedStackPath` + branch layouts |
| redirect callback / route guard | `RouteRedirectRule` |
| leave confirmation | `RouteGuard` / `GuardRule` |
| generated route class | route target or file-generated route |
| nested router outlet | layout `buildPath` or `CoordinatorView` |

## From Navigator 1.0

If the current flow uses `Navigator.push` and has no URL boundary, start with an imperative path:

```dart
final path = NavigationPath<AppRoute>.create(
  label: 'checkout',
  stack: [CartRoute()],
);

await path.push(AddressRoute());
await path.pop();
```

Replace string arguments with route constructors and keep the existing event-driven mental model. Introduce a Coordinator only when the flow must accept external locations or publish browser history.

Named route arguments become constructor parameters and `props`:

```dart
class ProductRoute extends AppRoute {
  ProductRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
```

## From Navigator 2.0

Map the `RouteInformationParser` and `RouterDelegate` boundary to a Coordinator. The manifest parses and generates locations; bindings construct route values; paths own navigation state; the Flutter Coordinator publishes pages and history.

Do not copy a hand-maintained `pages` list into a second Coordinator stack. Decide whether the old list was state-derived (declarative stack) or transaction-driven (Coordinator/path), then keep one authority.

## From go_router

Map `GoRoute` path declarations to manifest routes and builders to bindings plus route builders:

```dart
RouteManifestRoute(
  id: AppRouteId.product,
  path: '/products/:id',
)

RouteBinding(
  id: AppRouteId.product,
  create: (match) => ProductRoute(
    match.pathParameters['id']!,
  ),
)
```

`ShellRoute` maps to a manifest layout, `RouteLayout`, and an owned path. A stateful shell with independent tab histories maps to a branched layout rather than one flat path.

Map a global redirect callback into small `RedirectRule`s attached only to route families that need them. Preserve continuation URIs during authentication rather than depending on global mutable redirect state.

Replace string calls such as `go('/products/42')` with typed routes for internal navigation or manifest locations at a URI boundary:

```dart
await coordinator.push(ProductRoute('42'));
await coordinator.pushUri(AppCoordinator.location.product('42'));
```

## From auto_route

Generated page-route types map naturally to ZenRouter route targets. Choose handwritten manifests when explicit graph composition is useful, or use `zenrouter_file_generator` when directory ownership and generated navigation helpers match the team workflow.

Nested router declarations map to layouts and paths. Generated path parameters remain typed constructor fields. Route guards that approve entry map to redirects; leave confirmations map to guards.

Do not assume every generated nested router needs a nested Coordinator. Most are layouts or feature modules inside one application Coordinator.

## Preserve observable contracts

For the migration slice, record and compare:

```text
incoming URI
typed destination parameters
active shell and child path
back / forward behavior
pop result completion
query updates
restoration after process death
unknown-location behavior
```

The new implementation may use different internal classes, but these outcomes should change only when the product requirement changes intentionally.

## Incremental embedding

`CoordinatorView` can host a migrated feature inside the old application's surface:

```dart
CoordinatorView<AppRoute>(
  coordinator: migratedFeatureCoordinator,
  initialUri: Uri.parse('/products/42'),
)
```

The old router continues to own the application URL and system back until the boundary moves. Forward relevant external locations explicitly; do not let both routers publish browser history.

## Migration order

1. Choose one root-to-detail slice.
2. Write its manifest and round-trip tests.
3. Bind existing screens through typed route targets.
4. Model one shell with a layout and child path.
5. Port redirects and leave guards to their distinct seams.
6. Compare deep links, back, queries, results, and restoration.
7. Embed or route traffic to the new slice.
8. Remove the old declarations only after production contracts match.

## Common mistakes

**Syntax-only replacement.** Calling `coordinator.push` everywhere does not establish URL topology or layout ownership.

**Two route authorities.** Keeping the old route table and a new manifest indefinitely guarantees drift. Use a staged boundary, then remove the old owner.

**Flattening shells.** Nested navigation becomes a global stack and back crosses product boundaries.

**Migrating every route at once.** Failures cannot be localized and rollback is difficult. Move vertical slices with explicit tests.

## Checkpoint

Describe the migrated feature entirely in ZenRouter nouns: manifest nodes, bindings, route targets, layouts, paths, policies, and commits. Then prove its public URI, active screen, back behavior, and restoration match the previous product contract.

You now have the complete learning path. Use the chapter sidebar and in-page outline for review, and keep the Markdown source beside the graph as the library evolves.
