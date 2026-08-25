ZenRouter navigation methods describe intent. Choosing the method that matches the product behavior is more reliable than rebuilding stack lists or publishing URLs by hand.

## Route operations at a glance

| Operation | Meaning | History intent |
| --- | --- | --- |
| `push(route)` | Add a new page entry and wait for its pop result | push |
| `pushSilently(route)` | Add a page and complete after the commit | push |
| `navigate(route)` | Pop to an equal route, or push if absent | replace or push |
| `replace(route)` | Reset all paths and activate one destination | replace |
| `pushReplacement(route)` | Replace the active entry and optionally complete it | replace |
| `pushOrMoveToTop(route)` | Reuse an existing entry without duplicating it | push |
| `pop(result)` | Pop the deepest eligible path | replace |
| `recover(route)` | Apply external-entry deep-link policy | strategy-specific |

Every Coordinator operation resolves redirects, finds the target layout, mutates the owning path, and publishes one `NavigationCommit` after the transaction finishes.

## Push and return a result

`push` returns the result produced when that exact page entry is popped:

```dart
final saved = await coordinator.push<bool>(EditArticleRoute('42'));

if (saved == true) {
  await articles.refresh('42');
}
```

The editor completes the result through the Coordinator:

```dart
await coordinator.pop(true);
```

In 3.0, popping completes the entry result and runs its pop lifecycle. Do not manually complete the same result from `onDidPop`.

Use `pushSilently` when code must await the navigation commit but must not wait for the user to leave the destination. Router and deep-link integrations commonly need this behavior:

```dart
await coordinator.pushSilently(ArticleRoute('42'));
// The route is now committed; this line does not wait for a future pop.
```

## Navigate versus push

`navigate` searches the owning path for an equal route. If found, it pops back to that entry. If absent, it pushes a new entry.

```dart
await coordinator.navigate(HomeRoute());
```

This is useful for global destinations such as Home or an existing settings screen. Equality is therefore part of navigation behavior. Parameterized routes must include parameters in `props`.

Use `push` when a repeated destination should create a distinct history entry. ZenRouter separates route value equality from imperative page-entry identity, so two equal route values can coexist when you intentionally push both.

## Replace and replacement

`replace` resets every path and reconstructs one valid navigation context. It is appropriate after sign-out, unrecoverable restoration, or a deep link whose strategy explicitly replaces the current state.

```dart
await coordinator.replace(LoginRoute());
```

`pushReplacement` is narrower: it replaces the current entry, respects its guard, optionally completes that entry with a result, and returns the new entry's future result.

```dart
await coordinator.pushReplacement<DashboardResult, LoginResult>(
  DashboardRoute(),
  result: LoginResult.success,
);
```

## URI operations

URI helpers parse through the same manifest and binding registry before delegating to route operations:

```dart
final uri = AppCoordinator.location.article('42');

await coordinator.pushUri(uri);
await coordinator.navigateUri(uri);
await coordinator.replaceUri(uri);
await coordinator.recoverUri(uri);
```

Receiver-flipped helpers are also available:

```dart
await uri.pushSilentlyWith(coordinator);
```

Use typed routes for internal navigation when you already have the destination value. Use URI operations when testing or crossing a location boundary. Both paths must resolve to the same graph node.

## External recovery

`recoverUri` is not another spelling of `pushUri`. It treats the location as an external entry point. A target with `RouteDeepLink` can select `navigate`, `push`, `replace`, or a custom handler. A route without a deep-link mixin defaults to replacement, producing a safe context from an unknown starting stack.

## Commits and browser history

After each transaction, the Coordinator publishes:

```dart
NavigationCommit(
  revision: 12,
  previousUri: Uri.parse('/articles'),
  currentUri: Uri.parse('/articles/42'),
  historyIntent: NavigationHistoryIntent.push,
)
```

The revision is monotonic within the Coordinator. The browser adapter consumes `push`, `replace`, or `traverse` intent instead of guessing from widget changes. A guarded operation that changes nothing does not publish a fake final state.

## Common mistakes

**Awaiting `push` in a deep-link handler.** The handler waits until the route is popped. Use `pushSilently` when completion means “committed.”

**Using `replace` for ordinary forward navigation.** This erases every path, including nested shell state.

**Calling `push` for a global singleton destination.** Repeated taps create duplicates. Use `navigate` or `pushOrMoveToTop` according to the desired history.

**Constructing a different URL at the call site.** Use the generated or handwritten manifest location so parsing and reverse routing remain one contract.

## Checkpoint

Test one route through both paths:

```text
location → manifest match → binding → typed route → location
```

Then test `push`, `navigate`, and `replace` and assert the active stack, final URI, commit revision, and history intent. Next, **Paths and layouts** explains where those operations land in a nested application.
