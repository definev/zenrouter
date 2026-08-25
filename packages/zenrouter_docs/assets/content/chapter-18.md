ZenRouter coordinates navigation state; it does not replace Riverpod, Bloc, Provider, Redux, or a custom domain store. A clean integration gives routes stable external identity while domain state owns loading, caching, edits, and business rules.

## The boundary rule

Put a value on the route when it must survive one or more of these boundaries:

- a copied URL;
- a browser refresh;
- process restoration;
- a notification or host-app request;
- a navigation contract test.

Keep it in the domain store when it represents mutable loaded state, a service, cache, credential, or large object graph.

| Route value | Domain/store value |
| --- | --- |
| `articleId: '42'` | loaded `Article`, comments, cache status |
| `collectionId` | paged collection records |
| `sort=newest` | current fetched result set |
| `draftId` | mutable editor buffer and autosave state |
| selected tab/branch | each feature's domain data |

## Load data from a typed route

The route selects data; the screen observes the store:

```dart
class ArticleRoute extends AppRoute {
  ArticleRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Widget build(
    covariant AppCoordinator coordinator,
    BuildContext context,
  ) => ArticleScreen(articleId: id);
}
```

With Riverpod, for example:

```dart
class ArticleScreen extends ConsumerWidget {
  const ArticleScreen({super.key, required this.articleId});
  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleProvider(articleId));
    return article.when(
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(error),
      data: (value) => ArticleView(value),
    );
  }
}
```

A deep link and an in-app push now use the same loading path because both produce `ArticleRoute('42')`.

## Inject application policy into the Coordinator

Redirects and recovery sometimes need session or feature state. Inject narrow interfaces:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, AppRouteId> {
  AppCoordinator({required this.session, required this.features});

  final SessionReader session;
  final FeatureFlagReader features;
}
```

Avoid global service lookup inside every route. Constructor injection makes policy tests deterministic and allows multiple Coordinator instances in embedded surfaces.

## State-driven navigation

When the list of visible pages is itself a projection of state, use a declarative stack:

```dart
NavigationStack.declarative(
  routes: [
    CartRoute(cart.id),
    if (checkout.address != null) AddressRoute(cart.id),
    if (checkout.payment != null) ReviewRoute(cart.id),
  ],
  resolver: resolveCheckoutRoute,
)
```

The store owns the list. UI events change domain state; the route list follows. Do not also call path `push` for the same transition.

For Coordinator navigation, state changes may request a transaction, but the Coordinator remains the owner of paths and URI commits. A logout listener can call `replace(HomeRoute())`; it should not mutate internal path lists.

## Query state

Optional, shareable view state belongs in query parameters. `RouteQueryParameters` can update the URI while retaining the same route entry:

```dart
route.updateQueries(
  coordinator,
  queries: {
    ...route.queries,
    'sort': 'newest',
    'page': '1',
  },
);
```

The store may use these values as provider keys. The route still owns their external representation.

## Drafts and results

Keep an editor buffer in a store keyed by a stable `draftId`. The route carries that ID and guards departure while the store reports unsaved changes. On save, pop with a small result:

```dart
final saved = await coordinator.push<bool>(EditDraftRoute(draftId));
if (saved == true) drafts.invalidate(draftId);
```

Do not return the whole mutable draft through the route result unless it truly is a small, isolated local flow.

## Restoration

After process death, the application must recreate the screen from route values plus domain storage. If restoration requires an in-memory object that cannot be reloaded, the route carries hidden state.

Persist domain drafts and caches using the domain layer. Persist route identity through URIs or a versioned `RestorableConverter`.

## Common mistakes

**Route starts network work in its constructor.** Matching becomes side-effectful and hard to cancel. Let the screen/store own loading.

**Store duplicates the router stack.** Two authorities drift. Store domain state; observe navigation state from paths and commits.

**Route carries a provider container or Bloc.** The destination becomes tied to one runtime instance and cannot restore cleanly.

**Auth listener pushes Login repeatedly.** Use an idempotent redirect for protected arrivals and one explicit replace on sign-out.

## Checkpoint

Recreate one production screen after a simulated restart using only its route value and domain stores. Open the same screen from a deep link and an in-app push. Both should load the same data and publish the same location.

Next, **Migrate to 3.0** applies these boundaries without forcing a full application rewrite.
