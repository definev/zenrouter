import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_core/zenrouter_core.dart';
import 'package:zenrouter_nocterm/src/coordinator/base.dart';
import 'package:zenrouter_nocterm/src/internal/type.dart';
import 'package:zenrouter_nocterm/src/mixin/unique.dart';
import 'package:zenrouter_nocterm/src/path/indexed.dart';
import 'package:zenrouter_nocterm/src/path/navigation.dart';

class NavigationStack<T extends RouteTarget> extends StatefulComponent {
  const NavigationStack({
    super.key,
    required this.path,
    this.coordinator,
    required this.resolver,
  });

  final NavigationPath<T> path;
  final Coordinator? coordinator;
  final NavigationStackResolver<T> resolver;

  @override
  State<StatefulComponent> createState() => _NavigationStackState<T>();
}

class _NavigationStackState<T extends RouteTarget>
    extends State<NavigationStack<T>> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  List<T> _currentStack = [];

  void _applyDiff() async {
    final diffOps = myersDiff<T>(_currentStack, component.path.stack);
    final state = _navigatorKey.currentState!;
    for (final op in diffOps) {
      switch (op) {
        case Keep<T>():
          break;
        case Delete<T>():
          state.pop();
        case Insert<T>():
          final route = component.resolver.call(op.element);
          state.push(route);
      }
    }
    await Future.delayed(Duration.zero);
    _currentStack = component.path.stack;
  }

  @override
  void initState() {
    super.initState();
    component.path.addListener(_applyDiff);
    Future(_applyDiff);
  }

  @override
  void dispose() {
    component.path.removeListener(_applyDiff);
    super.dispose();
  }

  @override
  void didUpdateComponent(covariant NavigationStack<T> oldComponent) {
    super.didUpdateComponent(oldComponent);

    if (oldComponent.path != component.path) {
      oldComponent.path.removeListener(_applyDiff);
      component.path.addListener(_applyDiff);
      _applyDiff();
    }
  }

  @override
  Component build(BuildContext context) {
    return Navigator(key: _navigatorKey, routes: {});
  }
}

/// Widget that builds an [IndexedStack] from an [IndexedStackPath].
/// Ensures that the stack caches pages when rebuilding the widget tree.
///
/// ## Role in Navigation Flow
///
/// [IndexedStackPathBuilder] renders indexed navigation:
/// 1. Receives an [IndexedStackPath] with fixed routes
/// 2. Builds all route widgets once and caches them
/// 3. Uses [IndexedStack] to show only the active route
/// 4. Rebuilds when the active index changes
class IndexedStackPathBuilder<T extends RouteUnique> extends StatefulComponent {
  const IndexedStackPathBuilder({
    super.key,
    required this.path,
    required this.coordinator,
  });

  /// The path that maintains the indexed stack state.
  final IndexedStackPath<T> path;

  /// The coordinator used to resolve and build routes in the stack.
  final Coordinator coordinator;

  @override
  State<IndexedStackPathBuilder<T>> createState() =>
      _IndexedStackPathBuilderState<T>();
}

class _IndexedStackPathBuilderState<T extends RouteUnique>
    extends State<IndexedStackPathBuilder<T>> {
  List<Component>? _children;

  List<Component> _buildChildren(List<T> stack) =>
      stack.map((ele) => ele.build(component.coordinator, context)).toList();

  @override
  Component build(BuildContext context) {
    return (_children ??= _buildChildren(
      component.path.stack,
    ))[component.path.activeIndex];
  }
}
