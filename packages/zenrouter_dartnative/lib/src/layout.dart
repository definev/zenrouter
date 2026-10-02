import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import 'coordinator.dart';
import 'path.dart';
import 'route.dart';

/// Registers a path's layout with its coordinator, as in ZenRouter.
extension RouteLayoutBinding<T extends RouteUnique> on StackPath<T> {
  void bindLayout(RouteLayoutParent<T> Function() constructor) {
    final owner = proxyCoordinator ?? coordinator;
    if (owner is! Coordinator<T>) {
      throw StateError('bindLayout requires a path with a Coordinator.');
    }
    owner.defineLayoutParent(constructor);
  }
}

/// Route layout mixin for DartNative screens.
///
/// A layout owns route topology through [resolvePath], while its ordinary
/// [RouteUnique.build] implementation chooses the DartNative widget renderer.
/// Routing state therefore stays independent of `Scaffold`, tab bars, and any
/// future native container implementation.
mixin RouteLayout<T extends RouteUnique> on RouteUnique
    implements RouteLayoutParent<T> {
  @override
  StackPath<T> resolvePath(covariant Coordinator<T> coordinator);

  @override
  Object get layoutKey => runtimeType;

  @override
  Uri toUri() => Uri(pathSegments: ['__layout', '$layoutKey']);

  late final _layoutProxy = RouteLayoutParent.proxy(this);

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    super.onDidPop(result, coordinator);
    _layoutProxy.onDidPop(result, coordinator);
  }

  @override
  bool operator ==(Object other) => _layoutProxy == other;

  @override
  int get hashCode => _layoutProxy.hashCode;
}

typedef IndexedLayoutBuilder<T extends RouteUnique> =
    Widget Function(BuildContext context, IndexedLayoutSnapshot<T> layout);

/// Immutable input passed from [IndexedStackPathBuilder] to a native layout.
///
/// It exposes only navigation state and an intent method. The shell renders
/// that state but never owns a second selected-index value.
final class IndexedLayoutSnapshot<T extends RouteUnique> {
  const IndexedLayoutSnapshot({
    required this.activeIndex,
    required this.routes,
    required this.children,
    required Future<void> Function(int index) selectIndex,
  }) : _selectIndex = selectIndex;

  final int activeIndex;
  final List<T> routes;
  final List<Widget> children;
  final Future<void> Function(int index) _selectIndex;

  T get activeRoute => routes[activeIndex];

  Future<void> selectIndex(int index) => _selectIndex(index);
}

/// Renders an indexed route path without owning its navigation state.
///
/// The app supplies the native shell. A bottom-navigation implementation
/// normally returns a [Scaffold] containing an [IndexedStack] and a
/// [BottomNavigationBar]. Every child stays mounted while the coordinator's
/// indexed path remains the sole source of truth for selection.
class IndexedStackPathBuilder<T extends RouteUnique> extends StatefulWidget {
  const IndexedStackPathBuilder({
    super.key,
    required this.coordinator,
    required this.path,
    required this.builder,
  });

  final Coordinator<T> coordinator;
  final IndexedStackPath<T> path;
  final IndexedLayoutBuilder<T> builder;

  @override
  State<IndexedStackPathBuilder<T>> createState() =>
      _IndexedStackPathBuilderState<T>();
}

class _IndexedStackPathBuilderState<T extends RouteUnique>
    extends State<IndexedStackPathBuilder<T>> {
  @override
  void initState() {
    super.initState();
    _validateOwner();
    widget.path.addListener(_changed);
  }

  @override
  void didUpdateWidget(IndexedStackPathBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.path, widget.path) ||
        !identical(oldWidget.coordinator, widget.coordinator)) {
      oldWidget.path.removeListener(_changed);
      _validateOwner();
      widget.path.addListener(_changed);
    }
  }

  void _validateOwner() {
    final owner = widget.path.proxyCoordinator ?? widget.path.coordinator;
    if (!identical(owner?.root, widget.coordinator.root)) {
      throw StateError('IndexedStackPathBuilder path/coordinator mismatch.');
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final routes = widget.path.stack;
    return widget.builder(
      context,
      IndexedLayoutSnapshot(
        activeIndex: widget.path.activeIndex,
        routes: routes,
        children: List<Widget>.unmodifiable([
          for (var index = 0; index < routes.length; index++)
            KeyedSubtree(
              key: ValueKey(index),
              child: Builder(
                builder: (context) =>
                    routes[index].build(widget.coordinator, context),
              ),
            ),
        ]),
        selectIndex: (index) =>
            widget.coordinator.selectIndex(widget.path, index),
      ),
    );
  }

  @override
  void dispose() {
    widget.path.removeListener(_changed);
    super.dispose();
  }
}
