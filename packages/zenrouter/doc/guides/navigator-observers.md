# Navigator Observers Guide

Learn how to monitor navigation events in `zenrouter` using `NavigatorObserver`s at both the global (Coordinator) and local (NavigationStack) levels.

## Background

In Flutter, `NavigatorObserver` is used to listen to changes in the navigation stack (push, pop, replace, remove). `zenrouter` provides two ways to integrate these observers into your application structure.

## Global Observers: `CoordinatorNavigatorObserver`

Use this for observers that should track events across **all** navigation stacks in your coordinator. This is ideal for:
- App-wide analytics
- Global navigation logging
- Performance monitoring

### Implementation

Apply the `CoordinatorNavigatorObserver` mixin to your `Coordinator` and implement the `observers` getter:

```dart
class AppCoordinator extends Coordinator<AppRoute> 
    with CoordinatorNavigatorObserver<AppRoute> {
  
  @override
  List<NavigatorObserver> get observers => [
    MyAnalyticsObserver(),
    MyLoggingObserver(),
  ];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) => ...;
}
```

## Local Observers: `NavigationStack`

Use this for observers that are specific to a single navigation stack. This is useful for:
- Tracking events within a specific tab or nested flow
- Debugging a particular part of the UI

### Implementation

Pass the observers to the `NavigationStack` widget:

```dart
NavigationStack<AppRoute>(
  path: coordinator.root,
  coordinator: coordinator,
  observers: [
    LocalDebugObserver(),
  ],
  resolver: (route) => route.transition,
)
```

## Observer Combination Order

When both coordinator and stack observers are defined, they are combined automatically. The final list passed to the underlying `Navigator` is:

1. **Coordinator Observers** (Global)
2. **NavigationStack Observers** (Local)

This ensures that global observers always receive events before local ones.

## Example: Tracking Screen Views

```dart
class AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    print('Analytics: User navigated to ${route.settings.name}');
  }
}

class AppCoordinator extends Coordinator<AppRoute> 
    with CoordinatorNavigatorObserver<AppRoute> {
  
  @override
  List<NavigatorObserver> get observers => [AnalyticsObserver()];
  
  // ...
}
```

## Best Practices

- **Keep it Light**: Observers run on every navigation event. Avoid heavy operations.
- **Prefer Global for Analytics**: Use the coordinator mixin for feature-wide or app-wide analytics to ensure consistent tracking.
- **Use Local for Debugging**: Keep temporary or specific debugging observers local to the `NavigationStack` to avoid noise.
- **Mix and Match**: Don't be afraid to use both! Use global for "what" (analytics) and local for "how" (flow-specific logic).
