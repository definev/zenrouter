part of 'base.dart';

enum _ResolveLayoutStrategy { pushToTop, override }

/// Mixin that owns layout-parent registration and hierarchy activation.
///
/// Pure-Dart counterpart to Flutter's widget [layoutBuilder] table. Registers
/// [RouteLayoutParent] constructors and activates nested layouts before
/// navigation operations.
mixin CoordinatorLayoutCore<T extends RouteUri> on CoordinatorCore<T> {
  final _layoutParentConstructorTable =
      <Object, RouteLayoutParentConstructor>{};

  late final Map<Object, RouteLayoutParentConstructor>
  layoutParentConstructorTable = isRouteModule
      ? (coordinator as CoordinatorLayoutCore)._layoutParentConstructorTable
      : _layoutParentConstructorTable;

  /// Registers a constructor for a layout parent identified by [layoutKey].
  @override
  void defineLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  ) => layoutParentConstructorTable[layoutKey] = constructor;

  /// Retrieves the constructor for [layoutKey], or `null` if unregistered.
  RouteLayoutParentConstructor? getLayoutParentConstructor(Object layoutKey) =>
      layoutParentConstructorTable[layoutKey];

  /// Creates a layout parent via the registered constructor for [layoutKey].
  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) =>
      layoutParentConstructorTable[layoutKey]?.call(layoutKey);

  /// Ensures the layout hierarchy is properly activated for navigation.
  @protected
  Future<void> prepareParentLayoutList(
    RouteLayoutParent layout, {
    _ResolveLayoutStrategy strategy = _ResolveLayoutStrategy.override,
  }) async {
    RouteLayoutParent? current = layout;
    List<RouteLayoutParent> parentLayoutList = [];
    List<StackPath> parentLayoutPathList = [];
    while (current != null) {
      parentLayoutList.add(current);
      parentLayoutPathList.add(current.resolvePath(this));
      current = current.resolveParentLayout(this);
    }
    parentLayoutPathList.add(root);

    for (var i = parentLayoutPathList.length - 1; i >= 1; i--) {
      final grandParentLayout = parentLayoutPathList[i];
      final parentLayout = parentLayoutList[i - 1];
      switch (strategy) {
        case _ResolveLayoutStrategy.pushToTop
            when grandParentLayout is StackMutatable:
          await grandParentLayout.pushOrMoveToTop(parentLayout);
        default:
          await grandParentLayout.activateRoute(parentLayout);
      }
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _layoutParentConstructorTable.clear();
    super.dispose();
  }
}
