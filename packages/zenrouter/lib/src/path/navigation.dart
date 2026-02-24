// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// A mutable stack path for standard navigation.
///
/// Supports pushing and popping routes. Used for the main navigation stack
/// and modal flows.
///
/// ## Role in Navigation Flow
///
/// [NavigationPath] is the primary path type for imperative navigation:
/// 1. Stores routes in a mutable list (stack)
/// 2. Supports push/pop/remove operations
/// 3. Renders content via [NavigationStack] widget
/// 4. Implements [RestorablePath] for state restoration
///
/// When navigating:
/// - [push] adds a new route to the top
/// - [pop] removes the top route
/// - [navigate] handles browser back/forward
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

  /// The key used to identify this type in [defineLayoutBuilder].
  static const key = PathKey('NavigationPath');

  /// NavigationPath key. This is used to identify this type in [defineLayoutBuilder].
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
    RouteUriParserSync<RouteUri>? parseRouteFromUri,
    RouteLayoutParentConstructor? createLayoutParent,
    DecodeLayoutKeyCallback? decodeLayoutKey,
    RestorableConverterLookupFunction? getRestorableConverter,
  ]) {
    final coordinator = this.coordinator as Coordinator?;

    parseRouteFromUri ??= coordinator?.parseRouteFromUriSync;
    createLayoutParent ??= coordinator?.createLayoutParent;
    decodeLayoutKey ??= coordinator?.decodeLayoutKey;
    getRestorableConverter ??= coordinator?.getRestorableConverter;
    return <T>[
      for (final routeRaw in data)
        RestorableConverter.deserializeRoute(
              routeRaw,
              parseRouteFromUri: parseRouteFromUri,
              createLayoutParent: createLayoutParent,
              decodeLayoutKey: decodeLayoutKey,
              // coverage:ignore-start
              getRestorableConverter:
                  getRestorableConverter ?? RestorableConverter.buildConverter,
              // coverage:ignore-end
            )
            as T,
    ];
  }
}
