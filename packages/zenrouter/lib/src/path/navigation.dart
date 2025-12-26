part of 'base.dart';

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

  // coverage:ignore-start
  /// Creates a [NavigationPath] with an optional initial stack.
  ///
  /// This is deprecated. Use [NavigationPath.create] or [NavigationPath.createWith] instead.
  @Deprecated('Use NavigationPath.create or NavigationPath.createWith instead')
  factory NavigationPath([
    String? debugLabel,
    List<T>? stack,
    Coordinator? coordinator,
  ]) => NavigationPath._(debugLabel, stack, coordinator);
  // coverage:ignore-end

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
  }) => NavigationPath._(label, stack ?? [], coordinator);

  /// The key used to identify this type in [RouteLayout.definePath].
  static const key = PathKey('NavigationPath');

  /// NavigationPath key. This is used to identify this type in [RouteLayout.definePath].
  @override
  PathKey get pathKey => key;

  @override
  void reset() {
    for (final route in _stack) {
      route.completeOnResult(null, null, true);
    }
    _stack.clear();
  }

  @override
  T? get activeRoute => _stack.lastOrNull;

  @override
  Future<void> activateRoute(T route) async {
    reset();
    push(route);
  }

  @override
  void restore(dynamic data) {
    final rawStack = (data as List).cast<RouteTarget>();

    _stack.clear();
    for (final route in rawStack) {
      route.isPopByPath = false;
      route._path = this;
      _stack.add(route as T);
    }
  }

  @override
  List<dynamic> serialize() {
    final result = <dynamic>[];
    for (final route in stack) {
      switch (route) {
        case RouteLayout():
          result.add({'type': 'layout', 'value': route.runtimeType.toString()});
        case RouteRestorable():
          result.add(RouteRestorable.serialize(route));
        case RouteUnique():
          result.add(route.toUri().toString());
        default:
          throw StateError('Unsupported route type: $route');
      }
    }
    return result;
  }

  @override
  List<T> deserialize(
    List<dynamic> data, [
    RouteUriParserSync<RouteUnique>? parseRouteFromUri,
  ]) {
    parseRouteFromUri ??= _coordinator?.parseRouteFromUriSync;
    final list = <T>[];
    for (final routeRaw in data) {
      if (routeRaw is String) {
        assert(parseRouteFromUri != null);
        final route = parseRouteFromUri!(Uri.parse(routeRaw));
        list.add(route as T);
      }
      if (routeRaw is Map) {
        final isLayout = routeRaw['type'] == 'layout';
        if (isLayout) {
          // ignore: invalid_use_of_protected_member
          final type = RouteLayout.getLayoutTypeByRuntimeType(
            routeRaw['value'] as String,
          );
          if (type == null) throw UnimplementedError();
          list.add(RouteLayout.layoutConstructorTable[type]!() as T);
        } else {
          final strategy = RestorationStrategy.values
              .asNameMap()[routeRaw['strategy'] as String]!;
          assert(
            (strategy == RestorationStrategy.unique &&
                    parseRouteFromUri != null) ||
                strategy == RestorationStrategy.converter,
            'If you want to use RouteRestoration with RestorationStrategy.unique, you must provide a coordinator',
          );
          final route =
              RouteRestorable.deserialize(
                    routeRaw.cast(),
                    parseRouteFromUri: parseRouteFromUri,
                  )
                  as T;
          list.add(route);
        }
      }
    }
    return list;
  }
}
