# Navigation Methods Reference

When to use each navigation method on `Coordinator` / `CoordinatorCore`.

---

## Quick Reference

| Method | Stack effect | Use when |
|:-------|:-------------|:---------|
| `push(route)` | Adds to top | Going forward to a new screen |
| `pop([result])` | Removes top | Going back; optionally returns a result |
| `navigate(route)` | Pops to existing or pushes new | Sidebar/breadcrumb taps; browser back/forward |
| `replace(route)` | Clears **all** paths, sets one route | Full state reset (e.g. sign-out → sign-in) |
| `pushReplacement(route)` | Pops current, pushes new in-place | Swap current screen (e.g. onboarding step → next step) |
| `pushOrMoveToTop(route)` | Pushes new or moves existing to top | Tab-like nav where duplicates should be avoided |
| `tryPop([result])` | Pops if possible; returns success | Conditional back (check if pop was blocked by guard) |
| `recover(route)` | Depends on `RouteDeepLink` strategy | Deep link / URL bar navigation |

---

## Detailed Guide

### push

```dart
coordinator.push(ProductDetailRoute(id: '42'));
```

- Adds the route on top of the active `NavigationPath`.
- Resolves redirects before pushing.
- Resolves the route's parent layout hierarchy automatically.
- Returns `Future<R?>` — completes when the pushed route is popped, with its result.

**Use for:** Standard forward navigation (tapping a list item, opening a detail page, showing a modal).

**Example — awaiting a result:**

```dart
final confirmed = await coordinator.push<bool>(ConfirmationRoute());
if (confirmed == true) { /* proceed */ }
```

---

### pop

```dart
coordinator.pop();
coordinator.pop(result);  // pass a result back
```

- Removes the top route from all paths that have ≥ 2 entries.
- If the top route has a `RouteGuard`, the guard is consulted first.
- Completes the `Future` returned by the corresponding `push` call.

**Use for:** Back button, "Go back" actions, dismissing a detail screen.

---

### tryPop

```dart
final popped = await coordinator.tryPop();
if (popped == true)  { /* pop succeeded */ }
if (popped == false) { /* blocked by RouteGuard */ }
if (popped == null)  { /* no path with ≥ 2 entries */ }
```

- Like `pop`, but returns a `bool?` indicating what happened.
- Only pops from the **nearest** eligible path (not all paths like `pop`).

**Use for:** When you need to know if the pop actually happened (e.g. a custom back button that shows feedback if blocked).

---

### navigate

```dart
coordinator.navigate(TransactionsRoute());
```

- **If** the route already exists in the target path's stack → pops back to it (removing routes above).
- **If not** → pushes the route as new.
- Handles browser back/forward navigation correctly.

**Use for:** Sidebar nav, breadcrumb taps, bottom bar items on `NavigationPath` stacks — situations where the user might navigate to a screen they've already visited.

> [!TIP]
> Prefer `navigate` over `push` for same-level navigation (sidebar, tabs with `NavigationPath`) to avoid growing the stack with duplicate entries.

---

### replace

```dart
coordinator.replace(SignInRoute());
```

- **Clears all paths** (calls `reset()` on every path).
- Pushes the route as the only entry in the appropriate path.
- Full navigation state reset.

**Use for:** State transitions that invalidate the entire nav history — sign-out, session expiry, switching accounts, or initial app routing.

> [!CAUTION]
> This resets **all** paths including nested layout paths. Only use for true full-state resets.

---

### pushReplacement

```dart
coordinator.pushReplacement(NextStepRoute(), result: currentResult);
```

- Pops the current route (respecting `RouteGuard`) then pushes the new route in its place.
- If the guard blocks the pop, the replacement is cancelled and returns `null`.
- `result` is delivered to the popped route.

**Use for:** Replacing the current screen without leaving it in the history — onboarding steps, wizard flows, "edit → save → detail" transitions.

---

### pushOrMoveToTop

```dart
coordinator.pushOrMoveToTop(ChatRoute(id: 'abc'));
```

- If the route is already in the stack → moves it to the top (no duplicate).
- If not in the stack → pushes it normally.

**Use for:** Notification taps, chat conversations — scenarios where tapping the same item twice shouldn't create two copies in the stack.

---

### recover

```dart
coordinator.recover(route);
```

- Used internally by the router delegate for deep link / URL bar navigation.
- Checks if the route implements `RouteDeepLink` and respects its `deeplinkStrategy`:

| Strategy | Behaviour |
|:---------|:----------|
| `DeeplinkStrategy.replace` | Calls `replace(route)` — **default for all routes** |
| `DeeplinkStrategy.navigate` | Calls `navigate(route)` |
| `DeeplinkStrategy.push` | Calls `push(route)` |
| `DeeplinkStrategy.custom` | Calls `route.deeplinkHandler(coordinator, uri)` |

**Use for:** You rarely call this directly. Override `RouteDeepLink` on specific routes to control how they behave when opened via URL.

---

## Decision Flowchart

```
What kind of navigation?
│
├─ Going forward to a new screen
│  └─ push()
│
├─ Going back
│  ├─ Just go back → pop()
│  └─ Need to know if blocked → tryPop()
│
├─ Switching between sibling screens (sidebar, breadcrumb)
│  └─ navigate()
│
├─ Replacing the current screen in-place
│  └─ pushReplacement()
│
├─ Avoiding duplicate entries in the stack
│  └─ pushOrMoveToTop()
│
├─ Full state reset (sign-out, switch account)
│  └─ replace()
│
└─ Handling a deep link / URL change
   └─ recover() (automatic — configure via RouteDeepLink)
```

---

## Common Patterns

### Sign-out flow

```dart
await authService.signOut();
coordinator.replace(SignInRoute());   // clear all history
```

### Sidebar / drawer navigation

```dart
// Use navigate — pops back if already visited, pushes if new
coordinator.navigate(SettingsRoute());
coordinator.navigate(TransactionsRoute());
```

### Detail → edit → save → back to detail

```dart
// In EditRoute's save handler:
coordinator.pushReplacement(DetailRoute(id: id), result: savedData);
```

### Notification deep link

```dart
class NotificationRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
  // Opens on top of whatever is currently showing
}
```
