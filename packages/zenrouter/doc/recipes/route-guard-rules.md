# Recipe: Composable Route Guard Rules

## Problem

You need to block leaving a screen under several independent conditions — unsaved
edits, an upload in progress, a "are you sure?" confirmation — and reuse those
checks across many routes without copying `popGuard` into every class.

## Solution Overview

Use **`RouteGuardRule`** with a list of **`GuardRule`**s:

- Each rule returns `bool?`: `null` = continue, `true` = allow, `false` = block
- Sync `canPop` / `canPopListenable` drive Flutter `PopScope` (free back when safe)
- Rules stay unit-testable and reusable across editor, settings, checkout, etc.

```
System back / gesture
        │
        ▼
   canPop? ──true──► pop immediately (no dialog)
        │
      false
        ▼
   GuardRule chain (first non-null wins)
        │
   ┌────┴────┐
 null      true/false
  │           │
 next      allow / block
```

## Complete Code Example

Runnable sample:

```bash
cd packages/zenrouter/example
flutter run -t lib/main_guard_rules.dart
```

Source: [`example/lib/main_guard_rules.dart`](../../example/lib/main_guard_rules.dart)

Highlights from that file:

```dart
class UnsavedChangesRule extends GuardRule<AppRoute> {
  @override
  bool canPop(AppRoute route) =>
      route is! EditableRoute || !route.hasUnsavedChanges;

  @override
  ListenableMixin? canPopListenable(AppRoute route) =>
      route is EditableRoute ? route.dirty.toListenableMixin() : null;

  @override
  Future<bool?> guard(covariant GuardRulesCoordinator c, AppRoute route) async {
    if (route is! EditableRoute || !route.hasUnsavedChanges) return null;
    return showDiscardDialog(c.navigator.context);
  }
}

class UploadRoute extends AppRoute
    with EditableRoute, UploadableRoute, RouteGuardRule<AppRoute> {
  @override
  List<GuardRule> get guardRules => const [
    GuardAuditRule(),
    UploadInProgressRule(), // first decisive blocker
    UnsavedChangesRule(),
  ];
}
```

## How the chain works

| Rule return | Meaning |
|-------------|---------|
| `null` | No opinion — try the next rule |
| `true` | Allow pop — **stop** the chain |
| `false` | Block pop — **stop** the chain |

| Sync API | Meaning |
|----------|---------|
| `canPop → true` | This rule does not force `PopScope` intercept |
| `canPop → false` | Force intercept; then run `guard` |
| `canPopListenable` | Rebuild `PopScope` when dirty/uploading flips |
| Empty / all-`null` guards | Pop is **allowed** |

`RouteGuardRule.canPop` is `true` only when **every** rule returns `canPop == true`.
`canPopListenable` merges all rule listenables via `ListenableMixin.merge`.

### Example walkthrough — `UploadRoute`

1. User is uploading (`uploading == true`) and typed a caption (`dirty == true`).
2. `canPop` is `false` (upload rule + unsaved rule).
3. System back → intercept → `popGuardWith` runs:
   - `GuardAuditRule` → `null`
   - `UploadInProgressRule` → dialog; if user cancels leave → `false` → **blocked**
   - If user confirms cancel upload → `true` → **allowed** (unsaved rule never runs)
4. After upload finishes, only unsaved rule still intercepts until caption is cleared.

## Unit-testing rules

Rules are plain classes — no widget tree required:

```dart
test('UnsavedChangesRule continues when route is not editable', () async {
  final rule = const UnsavedChangesRule();
  final route = HomeRoute(); // not EditableRoute

  expect(rule.canPop(route), isTrue);
  expect(rule.canPopListenable(route), isNull);
  expect(
    await rule.guard(_FakeCoordinator(), route),
    isNull,
  );
});

test('UnsavedChangesRule blocks when dirty and dialog declines', () async {
  // Inject a dialog stub / use a test coordinator with a known context
});
```

## Common gotchas

1. **Order matters** — put cheap / hard blockers first (upload), soft prompts later (unsaved).
2. **`canPop` vs `popGuard`** — programmatic `coordinator.pop()` always runs `guard`, even when `canPop` is `true`.
3. **Use `toListenableMixin()`** — Flutter `ValueNotifier` is not a `ListenableMixin`; wrap it:
   ```dart
   dirty.toListenableMixin()
   ```
4. **Rebuild PopScope** — without `canPopListenable`, flipping dirty will not update system-back behavior until the page is rebuilt.
5. **Don’t put `RouteGuard` on login-only flows that should never intercept** — or override `canPop => true` and return `true` from `guard`.
6. **Entry protection is redirect, not guard** — auth “can I open this?” belongs in `RouteRedirect` / `RedirectRule`.

## When to use what

| Situation | API |
|-----------|-----|
| One-off leave check on a single route | `RouteGuard` + `popGuard` |
| Same leave logic on many routes | `RouteGuardRule` + shared `GuardRule`s |
| Free predictive back when clean | `canPop` + `canPopListenable` |
| Block opening a route (auth) | `RouteRedirect` / `RouteRedirectRule` |

## Related

- [Authentication Flow](authentication-flow.md) — entry redirects
- [Mixins API — RouteGuard / RouteGuardRule](../api/mixins.md)
- [ADVANCED.md — GuardRule](../../../skills/zenrouter/ADVANCED.md) (repo skill)
