Authentication, unsaved changes, and upload cancellation are all navigation policies, but they run at different moments. Use redirects to resolve an arrival and guards to approve a departure.

## Choose the correct policy seam

| Question | API |
| --- | --- |
| May the current route be left? | `RouteGuard` / `GuardRule` |
| Should this incoming route become another route? | `RouteRedirect` / `RouteRedirectRule` |
| How should an external link rebuild state? | `RouteDeepLink` |

Mixing these jobs causes loops and confusing browser behavior. An authentication check is not a pop guard; unsaved edits are not an incoming redirect.

## Guard a departure

A one-off editor can implement `RouteGuard`:

```dart
class EditArticleRoute extends AppRoute with RouteGuard {
  EditArticleRoute(this.id, this.dirty);

  final String id;
  final ValueNotifier<bool> dirty;

  @override
  bool get canPop => !dirty.value;

  @override
  ListenableMixin? get canPopListenable =>
      dirty.toListenableMixin();

  @override
  Future<bool> popGuardWith(AppCoordinator coordinator) async {
    if (!dirty.value) return true;
    return showDiscardDialog(coordinator.navigator.context);
  }
}
```

`canPop` gives Flutter a synchronous answer for system back and predictive-back integration. The listenable updates that answer when dirty state changes. Programmatic `coordinator.pop()` still evaluates the guard.

## Reuse GuardRule chains

When multiple routes share leave policies, extract `GuardRule`s and mix in `RouteGuardRule`:

```dart
class UploadRoute extends AppRoute
    with RouteGuardRule<AppRoute> {
  @override
  List<GuardRule<AppRoute>> get guardRules => const [
    UploadInProgressRule(),
    UnsavedChangesRule(),
  ];
}
```

Rules return `bool?`:

| Result | Meaning |
| --- | --- |
| `null` | No opinion; continue to the next rule |
| `true` | Allow; stop the chain |
| `false` | Block; stop the chain |

Put cheap, hard blockers before softer confirmation prompts. Plain rule classes can be unit-tested without rendering the route.

## Redirect an arrival

Protect an incoming account route with `RouteRedirect`:

```dart
class AccountRoute extends AppRoute with RouteRedirect {
  @override
  FutureOr<AppRoute?> redirectWith(
    covariant AppCoordinator coordinator,
  ) {
    if (coordinator.session.isSignedIn) return this;
    return LoginRoute(continueUri: toUri());
  }
}
```

Returning `this` keeps the original route. Returning another route continues resolution with that target. Returning `null` cancels navigation. Preserve the requested URI—including its query string—so login can recover the exact destination.

After successful sign-in:

```dart
await coordinator.recoverUri(loginRoute.continueUri);
```

Keep Login outside the protected layout and make the policy idempotent. The rule that redirects Account to Login must not also redirect Login to itself.

## Reusable redirects

Use `RouteRedirectRule` when a policy applies to several route families: authenticated routes, completed-onboarding routes, or feature-flagged routes. Keep the rule focused on navigation state; domain authorization still belongs in the service or backend.

## Transaction behavior

Redirects resolve before the target mutates a path. A chain that resolves to `null` cancels navigation. A final target is laid out and committed once.

Guards run before the current entry leaves. If a guard blocks, the stack remains authoritative. The browser adapter republishes the current location when necessary instead of leaving the address bar on an uncommitted destination.

## Failure modes

**Auth implemented as a guard.** It only controls leaving the current screen and cannot safely resolve a protected incoming link.

**Unsaved edits implemented as a redirect.** The incoming target knows nothing about whether the current editor may leave.

**Redirect loses intent.** After login the user lands on Home rather than the original deep link. Carry `continueUri`.

**Redirect loop.** The fallback route satisfies the same redirect condition. Exclude it explicitly and test the chain.

**Guard state is not listenable.** System-back affordances remain stale when dirty/uploading state changes.

## Test the policy

Test at least these cases:

1. Signed-in Account navigation commits Account once.
2. Signed-out Account navigation commits Login and preserves the full URI.
3. Login itself never redirects back to Login.
4. Successful login recovers the original URI once.
5. A dirty editor blocks pop when confirmation declines and leaves URI/stack unchanged.
6. The same editor pops and completes its result when confirmation accepts.

## Checkpoint

Paste a protected URL into a fresh browser context, sign in, and return to the exact requested location. Then edit a form and verify system back, programmatic pop, the stack, and the address bar all honor the same guard result.

Next, **Restoration and recovery** explains how external links and process death rebuild valid navigation contexts.
