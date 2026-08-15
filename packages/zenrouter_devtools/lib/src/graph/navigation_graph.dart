import 'dart:collection';

import 'package:zenrouter/zenrouter.dart';

/// The visual role of a node in a [NavigationGraph].
enum NavigationGraphNodeKind {
  route,
  stackLayout,
  indexedLayout,
  branchedLayout,
}

/// A tooling-friendly view of one declarative route manifest node.
final class NavigationGraphNode<I extends Object> {
  const NavigationGraphNode({
    required this.id,
    required this.label,
    required this.path,
    required this.parentId,
    required this.kind,
    required this.childIds,
    required this.depth,
    required this.branchIndex,
  });

  final I id;
  final String label;
  final String path;
  final I? parentId;
  final NavigationGraphNodeKind kind;
  final List<I> childIds;
  final int depth;

  /// Zero-based position in an indexed or branched parent layout.
  final int? branchIndex;

  bool get isRoute => kind == NavigationGraphNodeKind.route;
  bool get isLayout => !isRoute;
  bool get isIndexedLayout => kind == NavigationGraphNodeKind.indexedLayout;
  bool get isBranchedLayout => kind == NavigationGraphNodeKind.branchedLayout;
}

/// Immutable projection of a [RouteManifest] for navigation visualization.
///
/// The manifest remains the topology source of truth. This projection only
/// adds deterministic child ordering, node depth, display labels, and the
/// active route ancestry for devtool rendering.
final class NavigationGraph<I extends Object> {
  factory NavigationGraph.fromManifest({
    required RouteManifest<I> manifest,
    required Uri currentUri,
    String Function(I id)? labelForId,
  }) {
    final labels = labelForId ?? (I id) => id.toString();
    final childIds = <I, List<I>>{};
    for (final node in manifest.nodes.values) {
      final parentId = node.parentId;
      if (parentId != null) {
        childIds.putIfAbsent(parentId, () => <I>[]).add(node.id);
      }
    }

    int compareChildren(I leftId, I rightId, I? parentId) {
      final parent = parentId == null ? null : manifest.nodes[parentId];
      if (parent is RouteManifestLayout<I>) {
        final declaredChildren = _declaredBranches(parent);
        final leftIndex = declaredChildren.indexOf(leftId);
        final rightIndex = declaredChildren.indexOf(rightId);
        if (leftIndex != -1 || rightIndex != -1) {
          if (leftIndex == -1) return 1;
          if (rightIndex == -1) return -1;
          final declaredOrder = leftIndex.compareTo(rightIndex);
          if (declaredOrder != 0) return declaredOrder;
        }
      }

      final left = manifest.nodes[leftId]!;
      final right = manifest.nodes[rightId]!;
      final kindOrder = _kindRank(left).compareTo(_kindRank(right));
      if (kindOrder != 0) return kindOrder;
      final pathOrder = left.path.compareTo(right.path);
      if (pathOrder != 0) return pathOrder;
      return labels(leftId).compareTo(labels(rightId));
    }

    for (final entry in childIds.entries) {
      entry.value.sort(
        (left, right) => compareChildren(left, right, entry.key),
      );
    }

    final roots = manifest.nodes.values
        .where((node) => node.parentId == null)
        .map((node) => node.id)
        .toList(growable: false)
      ..sort((left, right) => compareChildren(left, right, null));

    final depths = <I, int>{};
    void visit(I id, int depth) {
      depths[id] = depth;
      for (final childId in childIds[id] ?? const []) {
        visit(childId, depth + 1);
      }
    }

    for (final rootId in roots) {
      visit(rootId, 0);
    }

    final activeRouteId = manifest.match(currentUri)?.id;
    final activeNodeIds = <I>{};
    RouteManifestNode<I>? activeNode =
        activeRouteId == null ? null : manifest.nodes[activeRouteId];
    while (activeNode != null && activeNodeIds.add(activeNode.id)) {
      final parentId = activeNode.parentId;
      activeNode = parentId == null ? null : manifest.nodes[parentId];
    }

    final graphNodes = <I, NavigationGraphNode<I>>{};
    for (final node in manifest.nodes.values) {
      final parent =
          node.parentId == null ? null : manifest.nodes[node.parentId];
      final declaredBranches =
          parent is RouteManifestLayout<I>
              ? _declaredBranches(parent)
              : const [];
      final branchIndex = declaredBranches.indexOf(node.id);
      graphNodes[node.id] = NavigationGraphNode<I>(
        id: node.id,
        label: labels(node.id),
        path: node.path,
        parentId: node.parentId,
        kind: switch (node) {
          RouteManifestRoute<I>() => NavigationGraphNodeKind.route,
          RouteManifestLayout<I>(kind: RouteManifestLayoutKind.stack) =>
            NavigationGraphNodeKind.stackLayout,
          RouteManifestLayout<I>(kind: RouteManifestLayoutKind.indexed) =>
            NavigationGraphNodeKind.indexedLayout,
          RouteManifestLayout<I>(kind: RouteManifestLayoutKind.branched) =>
            NavigationGraphNodeKind.branchedLayout,
        },
        childIds: List<I>.unmodifiable(childIds[node.id] ?? const []),
        depth: depths[node.id] ?? 0,
        branchIndex: branchIndex == -1 ? null : branchIndex,
      );
    }

    return NavigationGraph<I>._(
      name: manifest.name,
      currentUri: currentUri,
      nodes: UnmodifiableMapView(graphNodes),
      rootIds: List<I>.unmodifiable(roots),
      activeRouteId: activeRouteId,
      activeNodeIds: Set<I>.unmodifiable(activeNodeIds),
      routeCount: manifest.routes.length,
      layoutCount: manifest.layouts.length,
    );
  }

  const NavigationGraph._({
    required this.name,
    required this.currentUri,
    required this.nodes,
    required this.rootIds,
    required this.activeRouteId,
    required this.activeNodeIds,
    required this.routeCount,
    required this.layoutCount,
  });

  final String name;
  final Uri currentUri;
  final Map<I, NavigationGraphNode<I>> nodes;
  final List<I> rootIds;
  final I? activeRouteId;
  final Set<I> activeNodeIds;
  final int routeCount;
  final int layoutCount;

  bool get isEmpty => nodes.isEmpty;

  NavigationGraphNode<I>? operator [](I id) => nodes[id];

  Iterable<NavigationGraphNode<I>> childrenOf(I id) =>
      nodes[id]!.childIds.map((childId) => nodes[childId]!);
}

List<I> _declaredBranches<I extends Object>(RouteManifestLayout<I> layout) =>
    switch (layout.kind) {
      RouteManifestLayoutKind.stack => <I>[],
      RouteManifestLayoutKind.indexed => layout.indexedChildIds,
      RouteManifestLayoutKind.branched => layout.branchChildIds,
    };

int _kindRank<I extends Object>(RouteManifestNode<I> node) => switch (node) {
  RouteManifestLayout<I>() => 0,
  RouteManifestRoute<I>() => 1,
};
