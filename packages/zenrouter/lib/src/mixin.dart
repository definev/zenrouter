part of 'path.dart';

/// Strategy for handling deep links.
///
/// - [replace]: Replace the current navigation stack (default)
/// - [push]: Push onto the existing navigation stack
/// - [custom]: Custom strategy for handling deep links
enum DeeplinkStrategy { replace, push, custom }

mixin RouteDeepLink on RouteUnique {
  /// The strategy to use when handling this deep link.
  DeeplinkStrategy get deeplinkStrategy;

  /// Custom handler for deep links.
  ///
  /// This is called when [deeplinkStrategy] is [DeeplinkStrategy.custom].
  FutureOr<void> deeplinkHandler(covariant Coordinator coordinator, Uri uri) =>
      null;
}

/// Mixin for routes that need to guard against being popped.
///
/// Implement [popGuard] to control whether the route can be popped.
mixin RouteGuard on RouteTarget {
  /// Called when the route is about to be popped.
  ///
  /// Return `true` to allow the pop, or `false` to prevent it.
  FutureOr<bool> popGuard();
}

/// Builder function for creating a layout widget.
typedef RouteLayoutBuilder<T extends RouteUnique> =
    Widget Function(
      Coordinator coordinator,
      StackPath<T> path,
      RouteLayout<T>? layout,
    );

/// Constructor function for creating a layout instance.
typedef RouteLayoutConstructor<T extends RouteUnique> =
    RouteLayout<T> Function();

/// Mixin for routes that define a layout structure.
///
/// A layout is a route that wraps other routes, such as a shell or a tab bar.
/// It defines how its children are displayed and managed.
mixin RouteLayout<T extends RouteUnique> on RouteUnique {
  /// Identifier for the standard navigation path layout.
  static const navigationPath = 'NavigationPath';

  /// Identifier for the indexed stack path layout.
  static const indexedStackPath = 'IndexedStackPath';

  /// Registers a custom layout constructor.
  ///
  /// Use this to define how a specific layout type should be instantiated.
  static void defineLayout<T extends RouteLayout>(
    Type layout,
    T Function() constructor,
  ) => RouteLayout.layoutConstructorTable[layout] = constructor;

  /// Table of registered layout constructors.
  static Map<Type, RouteLayoutConstructor> layoutConstructorTable = {};

  /// Table of registered layout builders.
  ///
  /// This maps layout identifiers to their widget builder functions.
  static final Map<String, RouteLayoutBuilder> _layoutBuilderTable = {
    navigationPath: (coordinator, path, layout) => NavigationStack(
      path: path as NavigationPath<RouteUnique>,
      navigatorKey: layout == null
          ? coordinator.routerDelegate.navigatorKey
          : null,
      coordinator: coordinator,
      resolver: (route) => switch (route) {
        RouteTransition() => route.transition(coordinator),
        _ => StackTransition.material(
          Builder(builder: (context) => route.build(coordinator, context)),
        ),
      },
    ),
    indexedStackPath: (coordinator, path, layout) => ListenableBuilder(
      listenable: path,
      builder: (context, child) {
        final indexedStackPath = path as IndexedStackPath<RouteUnique>;
        return IndexedStack(
          index: indexedStackPath.activeIndex,
          children: indexedStackPath.stack
              .map((ele) => ele.build(coordinator, context))
              .toList(),
        );
      },
    ),
  };

  @Deprecated(
    'Do not manage [layoutBuilderTable] manually. Instead, use [buildPrimitivePath] to access it and [definePrimitivePath] to register new builders.',
  )
  static Map<String, RouteLayoutBuilder> get layoutBuilderTable =>
      _layoutBuilderTable;

  static Widget buildPrimitivePath<T extends RouteUnique>(
    Type type,
    Coordinator coordinator,
    StackPath<T> path,
    RouteLayout<T>? layout,
  ) {
    final typeString = type.toString().split('<').first;
    if (!_layoutBuilderTable.containsKey(typeString)) {
      throw UnimplementedError(
        'You are not provide layout builder for [$typeString] yet. If you extends [StackPath] class you must register it at [RouteLayout.layoutBuilderTable] to use the [buildPrimitivePathByType]',
      );
    }
    return _layoutBuilderTable[typeString]!(coordinator, path, layout);
  }

  // coverage:ignore-start
  /// Registers a custom layout builder.
  ///
  /// Use this to define how a specific layout type should be built.
  static void definePrimitivePath(Type type, RouteLayoutBuilder builder) {
    final typeString = type.toString().split('<').first;
    _layoutBuilderTable[typeString] = builder;
  }
  // coverage:ignore-end

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  StackPath<RouteUnique> resolvePath(covariant Coordinator coordinator);

  /// URI not use in RouteLayout
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    final pureType = path.runtimeType.toString().split('<').first;
    final builder = RouteLayout._layoutBuilderTable[pureType];
    if (builder == null) {
      throw UnimplementedError(
        'If you define new kind of path layout you must register it at [RouteLayout.layoutTable]',
      );
    }
    return builder(coordinator, path, this);
  }

  @override
  void onDidPop(Object? result, covariant Coordinator? coordinator) {
    super.onDidPop(result, coordinator);
    if (coordinator == null) return;
    resolvePath(coordinator).reset();
  }

  @override
  operator ==(Object other) => other.runtimeType == runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Mixin for routes that redirect to another route.
///
/// This is useful for authentication flows (redirect to login if not authenticated)
/// or for aliases.
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  /// Resolves the final destination route, following any redirects.
  static Future<T> resolve<T extends RouteTarget>(T route) async {
    T target = route;
    while (target is RouteRedirect) {
      final newTarget = await (target as RouteRedirect).redirect();
      // If redirect returns null, do nothing
      if (newTarget == null) return route;
      if (newTarget == target) break;
      if (newTarget is T) {
        /// Complete the result future to prevent the route from being popped.
        target.completeOnResult(null, null, true);
        target = newTarget;
      }
    }
    return target;
  }

  /// Returns the route to redirect to, or `null` to stay on the current route.
  FutureOr<T?> redirect();
}

/// The base class for all navigation targets (routes).
///
/// A [RouteTarget] represents a destination in the app. It can hold state
/// and parameters.
///
/// Subclasses should implement [props] for equality checks if they have parameters.
abstract class RouteTarget extends Object {
  Completer<Object?> _onResult = Completer();

  @visibleForTesting
  /// The completer for the result of the route. For testing purposes only.
  /// DO NOT USE THIS MANUALLY. USE [completeOnResult] instead.
  Completer<Object?> get onResult => _onResult;

  StackPath? _path;

  Object? _resultValue;

  /// Whether this route was popped by the path mechanism.
  ///
  /// This is used internally to prevent double removal.
  bool isPopByPath = false;

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      _path.hashCode ^
      _onResult.hashCode ^
      mapPropsToHashCode(props);

  /// The list of properties used for equality comparison.
  ///
  /// Override this to include route parameters in equality checks.
  List<Object?> get props => [];

  @override
  operator ==(Object other) => compareWith(other);

  /// Checks if this route is equal to another route.
  ///
  /// Two routes are equal if they have the same runtime type and navigation path.
  /// Must call this function when you override == operator.
  @pragma('vm:prefer-inline')
  bool compareWith(Object other) {
    if (identical(this, other)) return true;
    return other is RouteTarget &&
        other.runtimeType == runtimeType &&
        iterableEquals(props, other.props);
  }

  void onDidPop(Object? result, covariant Coordinator? coordinator) {}

  @override
  String toString() =>
      '$runtimeType${props.isEmpty ? '' : '[${props.map((p) => p.toString()).join(',')}]'}';

  /// Completes the route's result future.
  ///
  /// This is called when the route is popped with a result.
  void completeOnResult(
    Object? result,
    covariant Coordinator? coordinator, [
    bool failSilent = false,
  ]) {
    if (failSilent && _onResult.isCompleted) {
      _resultValue = null;
      _path = null;
      return;
    }
    _onResult.complete(result);
    _resultValue = result;
    _path = null;
  }
}

/// Mixin for routes that define a custom transition.
mixin RouteTransition on RouteUnique {
  /// Returns the [StackTransition] for this route.
  StackTransition<T> transition<T extends RouteUnique>(
    covariant Coordinator coordinator,
  );
}

/// Base mixin for unique routes in the application.
///
/// Most routes should mix this in. It provides integration with the [Coordinator]
/// and layout system.
mixin RouteUnique on RouteTarget {
  /// The type of layout that wraps this route.
  ///
  /// Return the type of the [RouteLayout] subclass that should contain this route.
  Type? get layout => null;

  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
  RouteLayout? createLayout(covariant Coordinator coordinator) {
    final constructor = RouteLayout.layoutConstructorTable[layout];
    if (constructor == null) {
      throw UnimplementedError(
        'Layout constructor for [$layout] must define in [RouteLayout.layoutConstructorTable] in [defineLayout] function at your [Coordinator]',
      );
    }
    return constructor();
  }

  /// Resolves the active layout instance for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  RouteLayout? resolveLayout(covariant Coordinator coordinator) {
    if (layout == null) return null;
    final layouts = coordinator.activeLayouts;
    if (layouts.isEmpty && layout == null) return null;
    for (var i = layouts.length - 1; i >= 0; i -= 1) {
      final l = layouts[i];
      if (l.runtimeType == layout) return l;
    }
    return createLayout(coordinator);
  }

  /// Builds the widget for this route.
  Widget build(covariant Coordinator coordinator, BuildContext context);

  /// Returns the URI representation of this route.
  Uri toUri();

  @override
  @mustCallSuper
  void onDidPop(
    Object? result,
    covariant Coordinator<RouteUnique>? coordinator,
  ) {
    if (_path case NavigationPath path) {
      if (this is! RouteGuard && !isPopByPath) {
        path.remove(this);
      }
    }
  }
}
