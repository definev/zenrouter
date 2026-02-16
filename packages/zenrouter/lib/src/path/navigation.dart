// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:zenrouter/src/coordinator/base.dart';
import 'package:zenrouter/src/internal/type.dart';
import 'package:zenrouter/src/mixin/restoration.dart';
import 'package:zenrouter/src/path/restoration.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// A mutable stack path for standard navigation.
///
/// Supports pushing and popping routes. Used for the main navigation stack
/// and modal flows.
class NavigationPath<T extends RouteTarget> extends StackPath<T>
    with
        ChangeNotifier,
        StackMutatable<T>,
        RestorablePath<T, List<dynamic>, List<T>> {
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
    required CoordinatorCore coordinator,
    required String label,
    List<T>? stack,
  }) => NavigationPath._(label, stack ?? [], coordinator as Coordinator);

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
    for (final route in stack) RestorableConverter.serializeRoute(route),
  ];

  @override
  List<T> deserialize(
    List<dynamic> data, [
    RouteUriParserSync<RouteIdentity>? parseRouteFromUri,
  ]) {
    parseRouteFromUri ??= coordinator?.parseRouteFromUriSync;
    return <T>[
      for (final routeRaw in data)
        RestorableConverter.deserializeRoute(
              routeRaw,
              parseRouteFromUri: parseRouteFromUri!,
            )
            as T,
    ];
  }
}
