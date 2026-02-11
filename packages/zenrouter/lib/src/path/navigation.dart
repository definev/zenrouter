// ignore_for_file: invalid_use_of_protected_member

import 'package:zenrouter/zenrouter.dart';

/// A mutable stack path for standard navigation.
///
/// Supports pushing and popping routes. Used for the main navigation stack
/// and modal flows.
class NavigationPath<T extends RouteTarget> extends StackPath<T>
    with StackMutatable<T>, RestorablePath<T, List<dynamic>, List<T>> {
  NavigationPath._([
    String? debugLabel,
    List<T>? stack,
    Coordinator? coordinator,
  ]) : super(stack ?? [], debugLabel: debugLabel, coordinator: coordinator);

  /// Creates a [NavigationPath] with an optional initial stack.
  ///
  /// This is the standard way to create a mutable navigation stack.
  factory NavigationPath.create({
    String? label,
    List<T>? stack,
    Coordinator? coordinator,
  }) => NavigationPath._(label, stack ?? [], coordinator);

  /// Creates a [NavigationPath] associated with a [Coordinator].
  ///
  /// This constructor binds the path to a specific coordinator, allowing it to
  /// interact with the coordinator for navigation actions.
  factory NavigationPath.createWith({
    required Coordinator coordinator,
    required String label,
    List<T>? stack,
  }) => NavigationPath._(label, stack ?? [], coordinator.rootCoordinator);

  /// The key used to identify this type in [RouteLayout.definePath].
  static const key = PathKey('NavigationPath');

  /// NavigationPath key. This is used to identify this type in [RouteLayout.definePath].
  @override
  PathKey get pathKey => key;

  @override
  void reset() => clear();

  @override
  T? get activeRoute => stack.lastOrNull;

  @override
  Future<void> activateRoute(T route) async {
    reset();
    push(route);
  }

  @override
  void restore(dynamic data) => bindStack(data.cast<RouteTarget>().cast<T>());

  @override
  List<dynamic> serialize() => [
    for (final route in stack) RouteTarget.serialize(route),
  ];

  @override
  List<T> deserialize(
    List<dynamic> data, [
    RouteUriParserSync<RouteUnique>? parseRouteFromUri,
  ]) {
    parseRouteFromUri ??= coordinator?.parseRouteFromUriSync;
    return <T>[
      for (final routeRaw in data)
        RouteTarget.deserialize(routeRaw, parseRouteFromUri: parseRouteFromUri!)
            as T,
    ];
  }
}
