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

  // coverage:ignore-start
  /// Custom handler for deep links.
  ///
  /// This is called when [deeplinkStrategy] is [DeeplinkStrategy.custom].
  FutureOr<void> deeplinkHandler(covariant Coordinator coordinator, Uri uri) =>
      null;
  // coverage:ignore-end
}

/// Mixin for routes that need to guard against being popped.
///
/// Implement [popGuard] to control whether the route can be popped.
mixin RouteGuard on RouteTarget {
  // coverage:ignore-start
  /// Called when the route is about to be popped.
  ///
  /// Return `true` to allow the pop, or `false` to prevent it.
  FutureOr<bool> popGuard() => true;
  // coverage:ignore-end

  /// Called in [Coordinator] or [StackPath] that contains [Coordinator] when the route is about to be popped.
  ///
  /// This method helps ensuring the path belong to that route have the same coordinator with coordinator that with function take.
  /// Return `true` to allow the pop, or `false` to prevent it.
  FutureOr<bool> popGuardWith(covariant Coordinator coordinator) {
    assert(_path?.coordinator == coordinator, '''
[RouteGuard] The path [${_path.toString()}] is associated with a different coordinator (or null) than the one currently handling the navigation.
Expected coordinator: $coordinator
Path's coordinator: ${_path?.coordinator}
Ensure that the path is created with the correct coordinator using `.createWith()` and that routes are being managed by the correct coordinator.
''');
    return popGuard();
  }
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
  @Deprecated('Use [NavigationPath.key] instead')
  static const navigationPath = 'NavigationPath';

  /// Identifier for the indexed stack path layout.
  @Deprecated('Use [IndexedStackPath.key] instead')
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
  static final Map<PathKey, RouteLayoutBuilder> _layoutBuilderTable = {
    NavigationPath.key: (coordinator, path, layout) => NavigationStack(
      path: path as NavigationPath<RouteUnique>,
      navigatorKey: layout == null
          ? coordinator.routerDelegate.navigatorKey
          : null,
      coordinator: coordinator,
      resolver: (route) {
        switch (route) {
          case RouteTransition():
            return route.transition(coordinator);
          default:
            final builder = Builder(
              builder: (context) => route.build(coordinator, context),
            );
            return switch (coordinator.transitionStrategy) {
              DefaultTransitionStrategy.material => StackTransition.material(
                builder,
              ),
              DefaultTransitionStrategy.cupertino => StackTransition.cupertino(
                builder,
              ),
              DefaultTransitionStrategy.none => StackTransition.none(builder),
            };
        }
      },
    ),
    IndexedStackPath.key: (coordinator, path, layout) => ListenableBuilder(
      listenable: path,
      builder: (context, child) {
        final indexedStackPath = path as IndexedStackPath<RouteUnique>;
        return IndexedStackPathBuilder(
          path: indexedStackPath,
          coordinator: coordinator,
        );
      },
    ),
  };

  // coverage:ignore-start
  @Deprecated(
    'Do not manage [layoutBuilderTable] manually. Instead, use [RouteLayout.buildPath] to access it and [defineLayout] to register new builders.',
  )
  static Map<PathKey, RouteLayoutBuilder> get layoutBuilderTable =>
      _layoutBuilderTable;

  @Deprecated(
    'Use [buildPath] instead. This method won\'t work in minifier mode so migrate to [buildPath]. This will be removed in the next major version.',
  )
  static Widget buildPrimitivePath<T extends RouteUnique>(
    Type type,
    Coordinator coordinator,
    StackPath<T> path,
    RouteLayout<T>? layout,
  ) {
    final typeString = type.toString().split('<').first;
    final key = PathKey(typeString);

    if (!_layoutBuilderTable.containsKey(key)) {
      throw UnimplementedError(
        'You are not provide layout builder for [$typeString] yet. If you extends [StackPath] class you must register it at [RouteLayout.layoutBuilderTable] to use the [RouteLayout.buildPath]',
      );
    }
    return _layoutBuilderTable[key]!(coordinator, path, layout);
  }
  // coverage:ignore-end

  static Widget buildRoot(Coordinator coordinator) {
    final rootPathKey = coordinator.root.pathKey;

    if (!_layoutBuilderTable.containsKey(rootPathKey)) {
      throw UnimplementedError(
        'You are not provide layout builder for [${rootPathKey.path}] yet. If you extends [StackPath] class you must register it by [RouteLayout.definePath] to use the [RouteLayout.buildRoot]',
      );
    }

    return _layoutBuilderTable[rootPathKey]!(
      coordinator,
      coordinator.root,
      null,
    );
  }
  /// Build the layout for this route.
  Widget buildPath(Coordinator coordinator) {
    final path = resolvePath(coordinator);

    if (!_layoutBuilderTable.containsKey(path.pathKey)) {
      throw UnimplementedError(
        'You are not provide layout builder for [${path.pathKey.path}] yet. If you extends [StackPath] class you must register it by [RouteLayout.definePath] to use the [RouteLayout.buildPath]',
      );
    }
    return _layoutBuilderTable[path.pathKey]!(coordinator, path, this);
  }

  // coverage:ignore-start
  /// Registers a custom layout builder.
  ///
  /// Use this to define how a specific layout type should be built.
  static void definePath(PathKey key, RouteLayoutBuilder builder) =>
      _layoutBuilderTable[key] = builder;
  // coverage:ignore-end

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  StackPath<RouteUnique> resolvePath(covariant Coordinator coordinator);

  // coverage:ignore-start
  /// URI not use in RouteLayout
  @override
  Uri toUri() => Uri.parse('/');
  // coverage:ignore-end

  @override
  Widget build(covariant Coordinator coordinator, BuildContext context) =>
      buildPath(coordinator);

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
  static Future<T> resolve<T extends RouteTarget>(
    T route,
    Coordinator? coordinator,
  ) async {
    T target = route;
    while (target is RouteRedirect) {
      final redirect = target as RouteRedirect;
      final newTarget = await switch (coordinator) {
        null => redirect.redirect(),
        final coordinator => redirect.redirectWith(coordinator),
      };
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

  // coverage:ignore-start
  /// Returns the route to redirect to, or `null` to stay on the current route.
  FutureOr<T?> redirect() => null;
  // coverage:ignore-end

  /// Called in [Coordinator] or [StackPath] that contains [Coordinator] when the route is resolving.
  ///
  /// This method helps ensuring the path belong to that route have the same coordinator with coordinator that with function take.
  /// Returns the route to redirect to, or `null` to stay on the current route.
  FutureOr<T?> redirectWith(covariant Coordinator coordinator) => redirect();
}

/// The base class for all navigation targets (routes).
///
/// A [RouteTarget] represents a destination in the app. It can hold state
/// and parameters.
///
/// Subclasses should implement [props] for equality checks if they have parameters.
abstract class RouteTarget extends Equatable {
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

  /// Internal properties that are hardcoded and cannot ignore.
  @override
  List<Object?> get internalProps => [runtimeType, _path, _onResult];

  /// The list of properties used for equality comparison.
  ///
  /// Override this to include route parameters in equality checks.
  @override
  List<Object?> get props => [];

  @mustCallSuper
  void onDidPop(Object? result, covariant Coordinator? coordinator) {
    /// Handle force pop from navigator
    if (coordinator == null &&
        isPopByPath == false &&
        _path?.stack.contains(this) == true) {
      if (_path case NavigationPath path) {
        path.remove(this);
      }
    }
  }

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
        '$this: Missing RouteLayout constructor for [$layout] must define by calling [RouteLayout.defineLayout] in [defineLayout] function at [${coordinator.runtimeType}]',
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
    super.onDidPop(result, coordinator);
    if (_path case NavigationPath path) {
      if (this is! RouteGuard && !isPopByPath) {
        path.remove(this);
      }
    }
  }
}
