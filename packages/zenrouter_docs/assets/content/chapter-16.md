Authentication is an incoming-route problem first. If a signed-out user opens `/account/settings?section=billing`, the application should show Login, preserve that complete location, and resolve it once after the session becomes valid.

## Desired transaction

```text
/account/settings?section=billing
  → manifest matches AccountSettingsRoute
  → auth redirect detects signed-out session
  → LoginRoute(continueUri: requestedUri)
  → login succeeds
  → recoverUri(continueUri)
  → AccountSettingsRoute commits once
```

The protected screen never flashes, Login is not pushed repeatedly, and the query string survives.

## Keep session state outside routes

Expose authentication through a service or store owned by the application:

```dart
class SessionStore extends ChangeNotifier {
  UserSession? _session;

  bool get isSignedIn => _session != null;

  Future<void> signIn(Credentials credentials) async {
    _session = await authApi.createSession(credentials);
    notifyListeners();
  }

  Future<void> signOut() async {
    await authApi.deleteSession();
    _session = null;
    notifyListeners();
  }
}
```

The Coordinator may receive this store through its constructor. Routes carry locations and stable IDs, not authentication tokens.

## Redirect protected arrivals

Extract the rule when several routes share the policy:

```dart
class RequireSessionRule extends RedirectRule<AppRoute> {
  const RequireSessionRule();

  @override
  RedirectResult<AppRoute> redirectResult(
    covariant AppCoordinator coordinator,
    AppRoute route,
  ) {
    if (coordinator.session.isSignedIn) {
      return const RedirectResult.continueRedirect();
    }

    return RedirectResult.redirectTo(
      LoginRoute(continueUri: route.toUri()),
    );
  }
}
```

Protected routes opt into the rule chain:

```dart
class AccountSettingsRoute extends AppRoute
    with RouteRedirectRule<AppRoute> {
  @override
  List<RedirectRule<AppRoute>> get redirectRules => const [
    RequireSessionRule(),
  ];
}
```

The rule returns “continue” when access is allowed and a typed Login route when it is not. `null` at the low-level redirect contract means cancel navigation; it is not the “allow” result.

## Preserve the continuation URI

Login is a public route outside the protected account layout:

```dart
class LoginRoute extends AppRoute {
  LoginRoute({this.continueUri});

  final Uri? continueUri;

  @override
  List<Object?> get props => [continueUri];

  @override
  Uri toUri() => AppCoordinator.location.login(
    continueTo: continueUri?.toString(),
  );
}
```

Encoding the continuation in the Login URL is optional for a purely in-memory flow, but it is useful when Login itself may be refreshed. Validate continuation locations before using them; accept application-relative URIs, not arbitrary external redirect targets.

## Resume after login

The screen delegates credentials to the session store. After success, recover the intended location or replace with a safe default:

```dart
Future<void> submit(Credentials credentials) async {
  await coordinator.session.signIn(credentials);

  final destination = route.continueUri;
  if (destination == null) {
    await coordinator.replace(HomeRoute());
  } else {
    await coordinator.recoverUri(destination);
  }
}
```

The second recovery resolves the auth rule again. Because the session is now valid, the rule continues to the original target. This idempotence is what prevents special “skip guard once” flags.

## Sign out safely

Signing out invalidates protected stacks. Clear domain caches as required, then replace the navigation context:

```dart
await coordinator.session.signOut();
await coordinator.replace(HomeRoute());
```

Do not leave protected account routes beneath Login in history. A later back gesture should not reveal stale UI from the signed-in session.

## Async session restoration

At application start, distinguish “session not loaded” from “signed out.” If redirect evaluation races a persisted-session lookup, users can be sent to Login unnecessarily. Bootstrap session state before accepting the first protected route, or let the redirect await a single shared initialization future.

Never create one network request per redirect hop. Session initialization should be memoized by the store.

## Security boundary

Route redirects improve UX; they are not authorization. The backend must still reject unauthorized data access. Treat route policy as controlling which UI context is shown, not as granting permission.

## Test matrix

| Starting state | Incoming URI | Expected final route |
| --- | --- | --- |
| signed in | `/account/settings` | Account settings |
| signed out | `/account/settings` | Login with continuation |
| signed out | `/login` | Login, no loop |
| login succeeds | saved continuation | exact protected route |
| login fails | saved continuation | Login, intent retained |
| sign out from account | any protected stack | safe public root |

Also test query strings, encoded parameters, expired sessions, two simultaneous protected navigation requests, and a continuation rejected by validation.

## Checkpoint

Open a protected URL in a fresh browser context, refresh Login, sign in, and verify the exact original URI commits once. Sign out, press back, and confirm no protected screen is reachable from retained history.

Next, **Bottom navigation** turns the retained-branch model into a complete product recipe.
