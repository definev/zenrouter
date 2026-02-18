# Documentation Update Skill

## Overview

This skill documents the approach for updating code documentation (doc comments) in the ZenRouter codebase after refactoring.

## Documentation Principles

### What to Include
- **Role in Navigation Flow**: Explain how the class/mixin participates in the overall navigation system
- **Method Purpose**: What the method does, not how it does it
- **Relationship to Other Components**: How it connects with other parts of the system

### What to Avoid
- **Code Examples**: Do not include code examples in documentation
- **When to Use**: Avoid prescriptive guidance on when to use APIs
- **Implementation Details**: Don't explain internal mechanics

### Documentation Template

For classes/mixins:
```dart
/// Brief description of what this is.
///
/// ## Role in Navigation Flow
///
/// Explain how this component fits in the navigation system:
/// 1. First step in flow
/// 2. Second step
/// 3. Result
mixin RouteExample on RouteTarget { ... }
```

For methods:
```dart
/// What this method does.
/// 
/// Any additional context about behavior.
ReturnType methodName(Parameters);
```

## Files Updated

### zenrouter_core - Mixins

| File | Description |
|------|-------------|
| `lib/src/mixin/uri.dart` | RouteUri base class for URI-based routes |
| `lib/src/mixin/layout.dart` | RouteLayoutParent and RouteLayoutChild for nested navigation |
| `lib/src/mixin/guard.dart` | RouteGuard for pop prevention |
| `lib/src/mixin/deeplink.dart` | RouteDeepLink and DeeplinkStrategy |
| `lib/src/mixin/redirect.dart` | RouteRedirect for route redirection |
| `lib/src/mixin/redirect_rule.dart` | RedirectRule and RedirectResult for composable redirects |
| `lib/src/mixin/identity.dart` | RouteIdentity for route identification |
| `lib/src/mixin/target.dart` | RouteTarget base class with lifecycle |

### zenrouter_core - Coordinator

| File | Description |
|------|-------------|
| `lib/src/coordinator/base.dart` | CoordinatorCore - central navigation hub |
| `lib/src/coordinator/modular.dart` | RouteModule and CoordinatorModular for modular architecture |

### zenrouter_core - Path

| File | Description |
|------|-------------|
| `lib/src/path/base.dart` | StackPath and PathKey |
| `lib/src/path/mutatable.dart` | StackMutatable for push/pop operations |
| `lib/src/path/navigatable.dart` | StackNavigatable for browser history |

### zenrouter_core - Internal

| File | Description |
|------|-------------|
| `lib/src/internal/reactive.dart` | ListenableObject for observer pattern |
| `lib/src/internal/type.dart` | RouteUriParserSync typedef |

### zenrouter - Coordinator

| File | Description |
|------|-------------|
| `lib/src/coordinator/layout.dart` | CoordinatorLayout mixin for layout management |

## Key Concepts Documented

### Route Hierarchy
```
RouteTarget (base class)
  └── RouteUri (implements RouteIdentity<Uri>, RouteLayoutChild)
        └── RouteUnique (most common mixin)
```

### Navigation Flow
1. Navigation method called (push/pop/replace/navigate)
2. RouteRedirect.resolve processes redirects
3. Layout hierarchy resolved via RouteLayoutParent
4. Route pushed/popped on appropriate StackPath
5. Listeners notified, UI rebuilds

### Lifecycle Phases
1. Creation
2. Redirect Resolution
3. Path Binding
4. Build
5. Active
6. Pop Request
7. Guard Check
8. Pop Completion
9. Cleanup

## Common Patterns

### Mixin Documentation Pattern
```dart
/// Mixin that provides [capability] for routes.
///
/// When mixed into routes, enables [specific behavior] by:
/// 1. Doing something during navigation
/// 2. Providing methods for customization
mixin RouteExample on RouteTarget { ... }
```

### Method Documentation Pattern
```dart
/// Performs [action] on the navigation stack.
///
/// Returns [description of return value].
ReturnType methodName(Parameters);
```

## Running Analysis

After updates, verify with:
```bash
dart analyze packages/zenrouter_core/
dart analyze packages/zenrouter/
```

## Notes

- Always add import for referenced types (e.g., `import 'package:zenrouter_core/src/mixin/guard.dart';`)
- Use markdown tables for multi-line documentation
- Keep descriptions concise (1-3 sentences for class docs, 1 line for methods)
- Reference related types using `[TypeName]` bracket notation
