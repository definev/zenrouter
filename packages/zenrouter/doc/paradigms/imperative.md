# Imperative Navigation

> **You control the navigation stack directly**

The imperative paradigm gives you full, explicit control over the navigation stack. You manually call methods like `push()`, `pop()`, and `replace()` to manipulate routes - just like Navigator 1.0, but with better type safety and features.

## When to Use Imperative Navigation

✅ **Use imperative navigation when:**
- Building mobile-only apps without web support
- You want simple, straightforward navigation control
- Navigation logic is event-driven (button clicks, gestures)
- You're migrating from Navigator 1.0
- You need fine-grained control over the stack

❌ **Don't use imperative navigation when:**
- You need deep linking or web URL support (use [Coordinator](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md) instead)
- Your navigation is driven by state changes (use [Declarative](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) instead)
- You want automatic browser back button support

## Core Concept

In imperative navigation, you work directly with a `NavigationPath` - a stack-based container for routes. You push routes onto the stack, pop them off, and replace the entire stack as needed.

```dart
final path = NavigationPath<RouteTarget>.create();
// Or: StackPath.navigationStack<RouteTarget>()

// Push a route
await path.push(ProfileRoute('user123'));

// Pop the current route
path.pop({'saved': true});

// Replace the entire stack
path.replace([HomeRoute(), SettingsRoute()]);
```

## Complete Example: Multi-Step Form

This example demonstrates a complete onboarding flow with multiple screens, state management, and navigation guards.

### Step 1: Define Your Data Model

```dart
import 'package:zenrouter/zenrouter.dart';

class OnboardingFormData {
  final String? fullName;
  final String? email;
  final DateTime? birthDate;
  final List<String> interests;
  
  const OnboardingFormData({
    this.fullName,
    this.email,
    this.birthDate,
    this.interests = const [],
  });
  
  // Immutable updates
  OnboardingFormData copyWith({
    String? fullName,
    String? email,
    DateTime? birthDate,
    List<String>? interests,
  }) {
    return OnboardingFormData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      interests: interests ?? this.interests,
    );
  }
}
```

### Step 2: Define Routes That Carry State

Each route carries its own state via constructor parameters:

```dart
sealed class OnboardingRoute extends RouteTarget {
  Widget build(BuildContext context);
}

class PersonalInfoStep extends OnboardingRoute with RouteGuard {
  final OnboardingFormData formData;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  PersonalInfoStep({required this.formData}) {
    // Initialize controllers from route state
    _nameController.text = formData.fullName ?? '';
    _emailController.text = formData.email ?? '';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            ElevatedButton(
              onPressed: () => _onNext(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _onNext(BuildContext context) {
    // Create updated state
    final updatedData = formData.copyWith(
      fullName: _nameController.text,
      email: _emailController.text,
    );
    
    // Navigate to next step with updated state
    onboardingPath.push(PreferencesStep(formData: updatedData));
  }
  
  @override
  Future<bool> popGuard() async {
    // Show confirmation dialog before leaving
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Onboarding?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }
}

class PreferencesStep extends OnboardingRoute {
  final OnboardingFormData formData;
  
  PreferencesStep({required this.formData});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onboardingPath.pop(), // Navigate back
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('What interests you?'),
            // Interest selection UI...
            ElevatedButton(
              onPressed: () {
                // Navigate to next step
                onboardingPath.push(ReviewStep(formData: formData));
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewStep extends OnboardingRoute {
  final OnboardingFormData formData;
  
  ReviewStep({required this.formData});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Name: ${formData.fullName}'),
            Text('Email: ${formData.email}'),
            Text('Interests: ${formData.interests.join(", ")}'),
            ElevatedButton(
              onPressed: () async {
                // Submit and navigate to success
                await _submitForm();
                onboardingPath.push(SuccessStep(formData: formData));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitForm() async {
    // Submit to backend
    await Future.delayed(const Duration(seconds: 2));
  }
}

class SuccessStep extends OnboardingRoute {
  final OnboardingFormData formData;
  
  SuccessStep({required this.formData});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 32),
            Text('Welcome ${formData.fullName}!'),
            ElevatedButton(
              onPressed: () {
                // Reset to welcome screen
                onboardingPath.reset();
                onboardingPath.push(WelcomeStep());
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3: Create Navigation Path

```dart
// Global navigation path for onboarding
final onboardingPath = NavigationPath<OnboardingRoute>.create();
// Or: StackPath.navigationStack<OnboardingRoute>()
```

### Step 4: Render with NavigationStack

```dart
class OnboardingApp extends StatelessWidget {
  const OnboardingApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationStack(
        path: onboardingPath,
        defaultRoute: WelcomeStep(), // Initial route
        resolver: (route) {
          // Convert routes to page destinations
          return StackTransition.material(
            route.build(context),
          );
        },
      ),
    );
  }
}
```

## API Reference

For complete API documentation including all methods, properties, and advanced usage, see:

**[→ Navigation Paths API Reference](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#navigationpath)**

Quick reference for `NavigationPath`:

| Method | Description |
|--------|-------------|
| `push(T)` | Push route onto stack, returns `Future` with pop result |
| `pop([result])` | Pop top route, consults guards |
| `replace(List<T>)` | Replace entire stack |
| `pushOrMoveToTop(T)` | Push or move route to top (for tabs) |
| `remove(T)` | Remove specific route (no guards) |
| `reset()` | Clear all routes (no guards) |

| Property | Description |
|----------|-------------|
| `stack` | Unmodifiable view of current stack |
| `debugLabel` | Optional label for debugging |


## Best Practices

### ✅ DO: Use Immutable State

Routes should carry immutable state and return updated state via `copyWith`:

```dart
class MyRoute extends RouteTarget {
  final String userId;
  final bool isEditing;
  
  MyRoute({required this.userId, this.isEditing = false});
  
  MyRoute copyWith({String? userId, bool? isEditing}) {
    return MyRoute(
      userId: userId ?? this.userId,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}
```

### ✅ DO: Implement Equality for Parameterized Routes

Routes with parameters must override `props`:

```dart
class ProfileRoute extends RouteTarget {
  final String userId;
  
  ProfileRoute(this.userId);
  
  @override
  List<Object?> get props => [userId];
}
```

### ✅ DO: Use Guards for Unsaved Changes

Prevent accidental data loss with `RouteGuard`:

```dart
class FormRoute extends RouteTarget with RouteGuard {
  bool hasUnsavedChanges = false;
  
  @override
  Future<bool> popGuard() async {
    if (!hasUnsavedChanges) return true;
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('Discard changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }
}
```

### ❌ DON'T: Use Global Mutable State

Avoid storing form state in global variables:

```dart
// ❌ BAD
var globalFormData = FormData();

class MyRoute extends RouteTarget {
  void onSubmit() {
    globalFormData.name = controller.text; // Mutating global state
  }
}

// ✅ GOOD
class MyRoute extends RouteTarget {
  final FormData formData; // State passed via constructor
  
  MyRoute({required this.formData});
  
  void onSubmit() {
    final updated = formData.copyWith(name: controller.text);
    path.push(NextRoute(formData: updated));
  }
}
```

### ❌ DON'T: Assume Stack Order

Don't rely on specific stack positions - they can change:

```dart
// ❌ BAD
path.stack[0]; // Might not be what you expect

// ✅ GOOD
path.stack.firstWhere((r) => r is HomeRoute);
```

## Common Patterns

### Pattern: Multi-Step Wizard

```dart
// Step 1 → Step 2 → Step 3 → Complete
path.push(Step1(data: data));
// In Step1: path.push(Step2(data: updatedData));
// In Step2: path.push(Step3(data: updatedData));
// In Step3: path.replace([HomeRoute()]); // Reset after completion
```

### Pattern: Modal Flow

```dart
// Show a modal flow that returns a result
final result = await path.push(ModalFlowStart());
if (result != null) {
  // Use the result
  print('User selected: $result');
}
```

### Pattern: Conditional Navigation

```dart
void navigateBasedOnState() {
  if (user.isLoggedIn) {
    path.push(DashboardRoute());
  } else {
    path.push(LoginRoute());
  }
}
```

## Transition to Other Paradigms

### Moving to Declarative

If your navigation becomes state-driven, consider [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md):

```dart
// Instead of imperatively pushing based on state...
if (selectedTab == 0) path.pushOrMoveToTop(Tab1());
if (selectedTab == 1) path.pushOrMoveToTop(Tab2());

// ...derive the stack from state declaratively
NavigationStack.declarative(
  routes: [
    HomeRoute(),
    if (selectedTab == 0) Tab1(),
    if (selectedTab == 1) Tab2(),
  ],
  resolver: (route) => ...,
)
```

### Moving to Coordinator

If you need deep linking or web support, upgrade to [Coordinator](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md):

```dart
// 1. Add RouteUnique to your routes
class HomeRoute extends RouteTarget with RouteUnique {
  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return HomeScreen();
  }
}

// 2. Create a Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile'] => ProfileRoute(),
      _ => NotFoundRoute(),
    };
  }
}

// 3. Use MaterialApp.router
MaterialApp.router(
  routerDelegate: coordinator.routerDelegate,
  routeInformationParser: coordinator.routeInformationParser,
)
```

## See Also

- [Declarative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/declarative.md) - State-driven routing
- [Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator.md) - Deep linking and web support
- [Route Mixins Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/mixins.md) - RouteGuard, RouteRedirect, and more
- [NavigationPath API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#navigationpath) - Complete API reference
