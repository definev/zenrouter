# Documentation Update Skill

## Overview

This skill documents the approach for updating code documentation (doc comments) in the ZenRouter codebase after refactoring.

## Documentation Principles

### What to Include
- **Role in Navigation Flow**: Explain how the class/mixin participates in the overall navigation system
- **Method Purpose**: What the method does, not how it does it
- **Relationship to Other Components**: How it connects with other parts of the system
- **When to Override**: For overridable members, explain when customization is needed

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

For abstract classes with mixins:
```dart
/// Brief description of what this is.
///
/// ## Inheritance Architecture
///
/// ```
/// ClassName<T extends RouteUnique>
///   extends ParentClass                    // Parent class responsibility
///   with Mixin1<T>, Mixin2<T>             // Mixin responsibilities
///   implements Interface1, Interface2     // Interface responsibilities
/// ```
///
/// ## Role in Navigation Flow
///
/// [ClassName] orchestrates by:
/// 1. First step
/// 2. Second step
/// ...
///
/// ## Class Architecture
///
/// This class composes functionality from multiple sources:
///
/// | Component | Responsibility |
/// |-----------|----------------|
/// | [ParentClass] | Core responsibility |
/// | [Mixin1] | Feature responsibility |
/// | [Mixin2] | Feature responsibility |
///
/// ## Abstract Nature
///
/// This is an **abstract class** that requires implementation of:
/// - [requiredMethod]: What it does
///
/// You must extend this class and provide the required implementation.
///
/// ## Relationship with Related Components
///
/// Explain the relationship with related components (e.g., CoordinatorModular).

For properties:
```dart
/// Brief description of what this is.
///
/// ## When to Override
/// Override if you need custom behavior.
///
/// ## Relationship
/// Explains how this property connects to other components.
ReturnType get propertyName;
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
| `lib/src/coordinator/base.dart` | Coordinator - Flutter-specific coordinator with Router integration |
| `lib/src/coordinator/layout.dart` | CoordinatorLayout mixin for layout management |
| `lib/src/coordinator/router.dart` | CoordinatorRouterDelegate and CoordinatorRouteParser |
| `lib/src/coordinator/observer.dart` | CoordinatorNavigatorObserver for navigation observation |
| `lib/src/coordinator/restoration/mixin.dart` | CoordinatorRestoration for state restoration |
| `lib/src/coordinator/restoration/restorable.dart` | CoordinatorRestorable and ActiveRouteRestorable |

### zenrouter - Path

| File | Description |
|------|-------------|
| `lib/src/path/layout.dart` | RouteLayoutBinding extension |
| `lib/src/path/navigation.dart` | NavigationPath for mutable stack navigation |
| `lib/src/path/indexed.dart` | IndexedStackPath for tab-based navigation |
| `lib/src/path/stack.dart` | NavigationStack, DeclarativeNavigationStack, IndexedStackPathBuilder |
| `lib/src/path/restoration.dart` | RestorablePath mixin and NavigationPathRestorable |
| `lib/src/path/transition.dart` | StackTransition, CupertinoSheetPage, DialogPage |

### zenrouter - Mixins

| File | Description |
|------|-------------|
| `lib/src/mixin/layout.dart` | RouteLayout for nested layout routes |
| `lib/src/mixin/unique.dart` | RouteUnique for coordinator-integrated routes |
| `lib/src/mixin/restoration.dart` | RouteRestorable and RestorableConverter for custom serialization |
| `lib/src/mixin/transition.dart` | RouteTransition for custom page transitions |
| `lib/src/mixin/query_parameters.dart` | RouteQueryParameters for URL query support |

### zenrouter - Internal

| File | Description |
|------|-------------|
| `lib/src/internal/type.dart` | Type definitions for zenrouter |
| `lib/src/internal/diff.dart` | Myers diff algorithm for route stack comparison |

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
