ZenRouter provides three navigation models because “show another screen” can mean three different things. Choosing the smallest correct model keeps local flows simple while preserving a strong application boundary.

## Decision guide

Start with the question that causes navigation:

```text
Does a URL, notification, restoration payload, or host app enter this flow?
│
├─ Yes → Coordinator
│
└─ No → Is the stack derived from application state?
         │
         ├─ Yes → Declarative NavigationStack
         │
         └─ No  → Imperative NavigationPath
```

| Question | Best starting model |
| --- | --- |
| Is this an action inside one local surface? | Imperative `NavigationPath` |
| Is the page list a projection of state? | Declarative `NavigationStack` |
| Does a URI enter or leave the app? | Coordinator + manifest |

These models compose. A Coordinator app may render a declarative checkout inside one route and open an imperative modal flow from another.

## Imperative paths

Use an imperative path when events directly add or remove destinations: an onboarding flow, nested editor, or short modal sequence.

```dart
final path = NavigationPath<AppRoute>.create(
  label: 'onboarding',
  stack: [WelcomeRoute()],
);

await path.push(PermissionsRoute());
final profile = await path.push<ProfileDraft>(ProfileRoute());
await path.pop();
```

`push` returns a `Future` that completes when the route leaves the stack, so a form can return a typed result without creating a global callback registry. Guards and redirects still apply when their mixins are present on the route.

Render the path with a `NavigationStack` and one resolver:

```dart
NavigationStack<AppRoute>(
  path: path,
  resolver: (route) => StackTransition.material(
    route.build(context),
  ),
)
```

Do not add URL strings to a local path merely to make it “router-like.” If an external URI must reconstruct the flow, move that boundary to a Coordinator.

## Declarative stacks

Use a declarative stack when domain state already determines which pages exist. A multi-step form is the usual example: completed steps produce the visible route list.

```dart
NavigationStack.declarative(
  routes: [
    CartRoute(cartId),
    if (checkout.address != null) AddressRoute(cartId),
    if (checkout.payment != null) ReviewRoute(cartId),
  ],
  resolver: (route) => StackTransition.material(
    route.build(context),
  ),
)
```

ZenRouter diffs the previous and next lists and applies the required path changes. Parameterized routes must include state-defining values in `props`; otherwise two different values may compare equal and retain the wrong page entry.

```dart
class ArticleRoute extends RouteTarget {
  ArticleRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
```

Do not mutate the path and the source state independently. The state list is the authority in declarative mode.

## Coordinator navigation

Use a Coordinator when navigation crosses the application boundary. A Coordinator is a Flutter `RouterConfig<Uri>` and owns URI parsing, recovery, navigation transactions, browser history, and layout resolution.

```dart
final coordinator = AppCoordinator();

MaterialApp.router(routerConfig: coordinator);

await coordinator.push(ArticleRoute('42'));
await coordinator.pushUri(Uri.parse('/articles/42'));
await coordinator.recoverUri(Uri.parse('/articles/42'));
```

The distinction between `pushUri` and `recoverUri` is intentional. `pushUri` is an in-app navigation operation. `recoverUri` treats the URI as an external entry point and allows `RouteDeepLink` behavior to decide how existing stacks should be rebuilt.

## Common selection mistakes

**Using Coordinator for every dialog.** This makes route topology describe temporary UI details. Keep short, non-addressable surfaces local.

**Using an imperative path for state-derived navigation.** Two authorities—the state and the path—will disagree. Let the declarative list be the authority.

**Using declarative routes to parse URLs.** A list diff cannot define the external URI contract. Put matching and reverse routing in a manifest.

**Choosing once for the whole application.** The choice is per boundary. A large app can use all three models without creating three competing routers.

## Checkpoint

For each navigation surface in your app, write one sentence:

- “This is an event-driven local flow.”
- “This stack is derived from state.”
- “This flow accepts or publishes an external URI.”

Match the sentence to imperative, declarative, or Coordinator navigation. Next, **A route graph in five minutes** connects these models to routes, paths, layouts, manifests, and bindings.
