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
/// Use this mixin to intercept pop operations and conditionally prevent them.
/// Common use cases include:
/// - **Unsaved changes**: Prompt user before losing form data
/// - **Confirmation dialogs**: Require explicit confirmation before leaving
/// - **Async validation**: Check with a server before allowing navigation
///
/// **Example - Confirmation Dialog:**
/// ```dart
/// class EditFormRoute extends RouteTarget with RouteUnique, RouteGuard {
///   bool hasUnsavedChanges = false;
///
///   @override
///   FutureOr<bool> popGuard() async {
///     if (!hasUnsavedChanges) return true;
///
///     // Show confirmation dialog
///     final shouldPop = await showDialog<bool>(
///       context: navigatorContext,
///       builder: (context) => AlertDialog(
///         title: Text('Discard changes?'),
///         content: Text('You have unsaved changes.'),
///         actions: [
///           TextButton(
///             onPressed: () => Navigator.pop(context, false),
///             child: Text('Cancel'),
///           ),
///           TextButton(
///             onPressed: () => Navigator.pop(context, true),
///             child: Text('Discard'),
///           ),
///         ],
///       ),
///     );
///     return shouldPop ?? false;
///   }
/// }
/// ```
///
/// **Note:** Guards are consulted during:
/// - [NavigationPath.pop] and [Coordinator.tryPop]
/// - Browser back button navigation
/// - [IndexedStackPath.goToIndexed] when leaving the current tab
mixin RouteGuard on RouteTarget {
  // coverage:ignore-start
  /// Called when the route is about to be popped.
  ///
  /// Return `true` to allow the pop, or `false` to prevent it.
  /// This can be async to show dialogs or perform validation.
  ///
  /// **Important:** This method should not have side effects beyond
  /// showing UI (like dialogs). The actual pop happens after this returns.
  FutureOr<bool> popGuard() => true;
  // coverage:ignore-end

  /// Called when the route is about to be popped, with coordinator access.
  ///
  /// This variant provides access to the [Coordinator] for routes that need
  /// to check application state or access dependencies during the guard check.
  ///
  /// **Coordinator Binding:**
  /// The assertion ensures the route's path was created with the same coordinator
  /// that is handling the navigation. This prevents bugs where routes are
  /// accidentally managed by the wrong coordinator.
  ///
  /// **Example - State-dependent guard:**
  /// ```dart
  /// @override
  /// FutureOr<bool> popGuardWith(AppCoordinator coordinator) async {
  ///   // Access app state through coordinator
  ///   if (coordinator.authState.isLoggingOut) {
  ///     return false; // Prevent navigation during logout
  ///   }
  ///   return popGuard();
  /// }
  /// ```
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
    'Do not manage [layoutBuilderTable] manually. Instead, use [RouteLayout.buildPath] to access it and [definePath] to register new builders.',
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
        'No layout builder provided for [$typeString]. If you extend the [StackPath] class, you must register it in [RouteLayout.definePath] to use [RouteLayout.buildPath].',
      );
    }
    return _layoutBuilderTable[key]!(coordinator, path, layout);
  }
  // coverage:ignore-end

  static Widget buildRoot(Coordinator coordinator) {
    final rootPathKey = coordinator.root.pathKey;

    if (!_layoutBuilderTable.containsKey(rootPathKey)) {
      throw UnimplementedError(
        'No layout builder provided for [${rootPathKey.path}]. If you extend the [StackPath] class, you must register it via [RouteLayout.definePath] to use [RouteLayout.buildRoot].',
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
        'No layout builder provided for [${path.pathKey.path}]. If you extend the [StackPath] class, you must register it via [RouteLayout.definePath] to use [RouteLayout.buildPath].',
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
  /// RouteLayout does not use a URI.
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

/// A mixin that provides redirection logic for routes.
///
/// `RouteRedirect` allows a route to specify another route to navigate to
/// instead of itself. This is commonly used for:
/// - **Authentication**: Redirecting unauthenticated users to a login page.
/// - **Permissions**: Redirecting users to an "Access Denied" page.
/// - **Aliases**: Mapping old route definitions to new ones.
///
/// When a route with this mixin is resolved by the [Coordinator], it calls
/// [redirect] (or [redirectWith]) to determine the final target. If multiple
/// redirects are chained, they are followed sequentially until a non-redirecting
/// route is reached.
///
/// **Example - Authentication Redirect:**
/// ```dart
/// class ProfileRoute extends RouteTarget with RouteUnique, RouteRedirect<AppRoute> {
///   @override
///   FutureOr<AppRoute?> redirectWith(AppCoordinator coordinator) {
///     // Check authentication state
///     if (!coordinator.authService.isLoggedIn) {
///       return LoginRoute(returnTo: this);
///     }
///     // Return self to stop redirection and navigate here
///     return this;
///   }
/// }
/// ```
///
/// **Example - Chained Redirects:**
/// ```dart
/// class OldDashboardRoute extends RouteTarget with RouteUnique, RouteRedirect<AppRoute> {
///   @override
///   FutureOr<AppRoute?> redirect() => NewDashboardRoute();
/// }
///
/// class NewDashboardRoute extends RouteTarget with RouteUnique, RouteRedirect<AppRoute> {
///   @override
///   FutureOr<AppRoute?> redirect() => this; // Stop here
/// }
/// ```
///
/// **Redirect Resolution Order:**
/// 1. Framework calls [redirectWith] (or [redirect] if no coordinator)
/// 2. If result is `null`, redirection is cancelled (user handled navigation manually)
/// 3. If result is `this`, navigation proceeds to this route
/// 4. If result is another route, process repeats with the new route
mixin RouteRedirect<T extends RouteTarget> on RouteTarget {
  /// Resolves the final destination route by following any redirects.
  ///
  /// This method is used internally by the framework to find the ultimate [RouteTarget].
  /// It follows the [redirect] chain until it reaches a route that doesn't redirect.
  ///
  /// **Error Handling:**
  /// If any redirect throws an exception, it propagates up to the caller
  /// (typically [Coordinator.push] or [Coordinator.replace]).
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

      // If redirect returns null, stop redirection and return the original route
      if (newTarget == null) return route;

      // If it redirects to itself, we've found our destination
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
  /// Defines the redirection target for this route.
  ///
  /// Implement this method to return:
  /// - `null`: Redirect was handled manually by user code (e.g., you called
  ///   [Coordinator.push] yourself). Framework stops and uses original route.
  /// - `this`: Stop here and navigate to this route.
  /// - `anotherRoute`: Continue redirection with the new target.
  ///
  /// **Async Support:**
  /// This method returns [FutureOr], allowing async operations like
  /// checking server state or loading data before determining the target.
  FutureOr<T?> redirect() => null;
  // coverage:ignore-end

  /// Called when the route is being resolved, providing access to the [Coordinator].
  ///
  /// This variant is preferred when redirection logic depends on application state
  /// or services accessible via the coordinator.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// FutureOr<AppRoute?> redirectWith(AppCoordinator coordinator) async {
  ///   final user = await coordinator.userService.getCurrentUser();
  ///   if (user == null) return LoginRoute();
  ///   if (!user.hasPermission('admin')) return AccessDeniedRoute();
  ///   return this;
  /// }
  /// ```
  ///
  /// Default implementation calls [redirect].
  FutureOr<T?> redirectWith(covariant Coordinator coordinator) => redirect();
}

/// The base class for all navigation targets (routes).
///
/// A [RouteTarget] represents a destination in the app. It can hold state
/// and parameters. Every screen, dialog, or navigable destination should
/// extend this class.
///
/// ## Route Lifecycle
///
/// Routes go through distinct phases during their lifetime:
///
/// ```
/// ┌─────────────────────────────────────────────────────────────────────┐
/// │                        ROUTE LIFECYCLE                              │
/// ├─────────────────────────────────────────────────────────────────────┤
/// │  1. CREATION        → Route instance created (constructor called)   │
/// │  2. REDIRECT CHECK  → RouteRedirect.redirect() called if applicable │
/// │  3. PATH BINDING    → Route assigned to a StackPath (_path set)     │
/// │  4. BUILD           → build() called to create the widget           │
/// │  5. ACTIVE          → Route is visible and receiving interactions   │
/// │  6. POP REQUEST     → User/system requests pop (guard consulted)    │
/// │  7. POP COMPLETION  → onDidPop() + completeOnResult() called        │
/// │  8. CLEANUP         → Route removed from path, _path set to null    │
/// └─────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Internal State
///
/// Routes maintain internal state managed by the framework:
/// - **`_path`**: The [StackPath] containing this route. Set during push.
/// - **`_onResult`**: A [Completer] that resolves when the route is popped.
/// - **`_resultValue`**: The result passed to [pop] before [onDidPop] is called.
/// - **`isPopByPath`**: Whether the pop was initiated by [StackPath.pop].
///
/// ## Result Handling
///
/// Routes can return a result when popped:
/// ```dart
/// // Pushing with result
/// final result = await coordinator.push<String>(SelectColorRoute());
/// print('Selected: $result');
///
/// // Popping with result (in route or widget)
/// coordinator.pop('blue');
/// ```
///
/// ## Equality
///
/// Override [props] to include route parameters in equality checks:
/// ```dart
/// class ProductRoute extends RouteTarget with RouteUnique {
///   final String productId;
///   ProductRoute(this.productId);
///
///   @override
///   List<Object?> get props => [productId];
/// }
/// ```
abstract class RouteTarget extends Equatable {
  /// Completer that resolves when this route is popped.
  ///
  /// The future completes with the result passed to [pop] or [completeOnResult].
  /// This is set fresh each time the route is pushed.
  Completer<Object?> _onResult = Completer();

  @visibleForTesting
  /// The completer for the result of the route. For testing purposes only.
  /// DO NOT USE THIS MANUALLY. USE [completeOnResult] instead.
  Completer<Object?> get onResult => _onResult;

  /// The [StackPath] that currently contains this route.
  ///
  /// This is set when the route is pushed onto a path and cleared when popped.
  /// Used internally to ensure routes are managed by the correct path.
  StackPath? _path;

  /// The result value to be returned when this route is popped.
  ///
  /// This is set by [StackPath.pop] before [onDidPop] is called, allowing
  /// the widget tree to access the result during disposal.
  Object? _resultValue;

  /// Whether this route was popped by the path mechanism.
  ///
  /// When `true`, the pop was initiated by [NavigationPath.pop] or similar.
  /// When `false`, the pop was initiated by the system (e.g., back button).
  ///
  /// This is used internally to prevent double removal from the stack.
  bool isPopByPath = false;

  /// Internal properties that are hardcoded and cannot be ignored.
  ///
  /// These are used for identity checks within the framework. Do not override.
  /// See [props] for user-defined equality properties.
  @override
  List<Object?> get internalProps => [runtimeType, _path, _onResult];

  /// The list of properties used for equality comparison.
  ///
  /// Override this to include route parameters in equality checks.
  /// Two routes are equal if they have the same type and equal [props].
  ///
  /// **Example:**
  /// ```dart
  /// class UserRoute extends RouteTarget with RouteUnique {
  ///   final int userId;
  ///   UserRoute(this.userId);
  ///
  ///   @override
  ///   List<Object?> get props => [userId];
  /// }
  /// ```
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
