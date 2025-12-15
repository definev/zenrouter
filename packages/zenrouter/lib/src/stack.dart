part of 'path.dart';

/// A widget that renders a stack of pages based on a [NavigationPath].
///
/// This is the core widget for imperative navigation. It listens to the [path]
/// and updates the [Navigator] with the corresponding pages.
class NavigationStack<T extends RouteTarget> extends StatefulWidget {
  const NavigationStack({
    super.key,
    required this.path,
    required this.resolver,
    this.defaultRoute,
    this.coordinator,
    this.navigatorKey,
  });

  /// Creates a declarative navigation stack.
  ///
  /// This factory method creates a [DeclarativeNavigationStack] which manages
  /// the stack based on a list of routes.
  static DeclarativeNavigationStack<T> declarative<T extends RouteTarget>({
    required List<T> routes,
    required StackTransitionResolver<T> resolver,
    GlobalKey<NavigatorState>? navigatorKey,
    String? debugLabel,
  }) {
    return DeclarativeNavigationStack(
      routes: routes,
      navigatorKey: navigatorKey,
      debugLabel: debugLabel,
      resolver: resolver,
    );
  }

  /// Optional key for accessing the navigator state.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The associated coordinator
  final Coordinator? coordinator;

  /// The navigation path to render.
  final NavigationPath<T> path;

  /// Callback that converts routes to destinations.
  final StackTransitionResolver<T> resolver;

  /// Optional route to push when the stack initializes.
  final T? defaultRoute;

  @override
  State<NavigationStack<T>> createState() => _NavigationStackState<T>();
}

class _NavigationStackState<T extends RouteTarget>
    extends State<NavigationStack<T>> {
  List<Page> _pages = [];
  List<T> _previousRoutes = [];

  @override
  void initState() {
    super.initState();
    if (widget.defaultRoute != null) {
      widget.path.pushOrMoveToTop(widget.defaultRoute!);
    }
    widget.path.addListener(_updatePages);
    _updatePages();
  }

  @override
  void dispose() {
    widget.path.removeListener(_updatePages);
    super.dispose();
  }

  Page _buildPage(T route) {
    /// Set path to route
    route._path = widget.path;
    final destination = widget.resolver(route);
    return destination.pageBuilder(
      context,
      ValueKey(route),
      PopScope(
        canPop: switch (route) {
          RouteGuard() => false,
          _ when destination.guard != null => false,
          _ => true,
        },
        onPopInvokedWithResult: (didPop, result) async {
          route._path ??= widget.path;
          if (!(kIsWeb || kIsWasm)) {
            assert(
              identical(route._path, widget.path),
              'Route must be from the same path',
            );
          }

          switch (didPop) {
            case true when result != null:
              route.onDidPop(result, widget.coordinator);
              route.completeOnResult(result, widget.coordinator);
            case true:
              route.onDidPop(result, widget.coordinator);
              route.completeOnResult(
                route._resultValue,
                widget.coordinator,

                /// Fail silent if it's force pop from platform
                route.isPopByPath == false,
              );
            case false when route is RouteGuard:
              widget.path.pop();
            case false when destination.guard != null:
              final popped = switch (widget.coordinator) {
                null => await destination.guard?.popGuard(),
                final coordinator => await destination.guard?.popGuardWith(
                  coordinator,
                ),
              };
              if (popped == true) widget.path.pop();
            case false:
          }
        },
        child: destination.builder(context),
      ),
    );
  }

  void _updatePages() {
    final currentRoutes = widget.path.stack;

    // Calculate diff between previous and current routes
    final diffOps = myersDiff(_previousRoutes, currentRoutes);

    // Build new pages list using diff operations
    final newPages = <Page>[];
    for (final op in diffOps) {
      switch (op) {
        case Keep<T>(:final oldIndex):
          // Reuse existing page
          newPages.add(_pages[oldIndex]);
        case Insert<T>(:final element):
          // Create new page
          newPages.add(_buildPage(element));
        case Delete<T>():
          // Skip deleted pages
          break;
      }
    }

    _pages = newPages;
    _previousRoutes = List.from(currentRoutes);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant NavigationStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      oldWidget.path.removeListener(_updatePages);
      widget.path.addListener(_updatePages);
      // Reset previous routes and rebuild pages for the new path
      _previousRoutes = [];
      _updatePages();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) return const SizedBox.shrink();
    return Navigator(
      key: widget.navigatorKey,
      pages: _pages,
      onDidRemovePage: (page) {},
    );
  }
}

/// A widget that manages a navigation stack declaratively.
///
/// Instead of pushing and popping, you provide a list of [routes]. The widget
/// calculates the difference between the old and new routes (using Myers diff)
/// and updates the stack accordingly.
class DeclarativeNavigationStack<T extends RouteTarget> extends StatefulWidget {
  const DeclarativeNavigationStack({
    super.key,
    required this.routes,
    this.navigatorKey,
    this.debugLabel,
    required this.resolver,
  });

  /// The list of routes to display.
  final List<T> routes;

  /// Optional key for the navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Optional debug label for the path.
  final String? debugLabel;

  /// Callback to resolve routes to pages.
  final StackTransitionResolver<T> resolver;

  @override
  // ignore: library_private_types_in_public_api
  State<DeclarativeNavigationStack<T>> createState() =>
      _DeclarativeNavigationStackState<T>();
}

class _DeclarativeNavigationStackState<T extends RouteTarget>
    extends State<DeclarativeNavigationStack<T>> {
  late final path = NavigationPath<T>.create(label: widget.debugLabel);
  List<T> _previousRoutes = [];

  @override
  void initState() {
    super.initState();
    _updateStack();
  }

  @override
  void didUpdateWidget(DeclarativeNavigationStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routes != oldWidget.routes) {
      _updateStack();
    }
  }

  void _updateStack() {
    // Calculate diff between previous and current routes
    final diffOps = myersDiff(_previousRoutes, widget.routes);

    // Apply the diff operations to the navigation path
    applyDiff(path, diffOps);

    // Update previous routes for next comparison
    _previousRoutes = List.from(widget.routes);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationStack(
      path: path,
      resolver: widget.resolver,
      navigatorKey: widget.navigatorKey,
    );
  }
}
