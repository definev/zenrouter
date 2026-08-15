import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

import '../coordinator_debug.dart';
import '../graph/navigation_graph.dart';
import '../graph/observed_flow_view.dart';
import '../widgets/debug_theme.dart';

/// Interactive visualization of the coordinator's declarative route graph.
class NavigationGraphTab<T extends RouteUnique> extends StatefulWidget {
  const NavigationGraphTab({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  State<NavigationGraphTab<T>> createState() => _NavigationGraphTabState<T>();
}

class _NavigationGraphTabState<T extends RouteUnique>
    extends State<NavigationGraphTab<T>> {
  final TransformationController _transformationController =
      TransformationController();
  Object? _selectedNodeId;
  _NavigationGraphMode _mode = _NavigationGraphMode.topology;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value =
        _transformationController.value.clone()..setIdentity();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        final graph = NavigationGraph<Object>.fromManifest(
          manifest: widget.coordinator.routeManifest,
          currentUri: widget.coordinator.currentUri,
        );
        if (graph.isEmpty) return const _EmptyGraph();
        final flow = widget.coordinator.debugNavigationFlow;
        return ListenableBuilder(
          listenable: flow,
          builder:
              (context, _) => Column(
                children: [
                  _GraphModeBar(
                    mode: _mode,
                    observedEdgeCount: flow.edges.length,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  Expanded(
                    child: switch (_mode) {
                      _NavigationGraphMode.topology => _buildTopology(graph),
                      _NavigationGraphMode.observed =>
                        ObservedNavigationFlowView(
                          graph: graph,
                          flow: flow,
                          onClear: widget.coordinator.clearDebugNavigationFlow,
                        ),
                    },
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildTopology(NavigationGraph<Object> graph) {
    final layout = _GraphLayout.calculate(graph);
    final selectedNode =
        _selectedNodeId == null ? null : graph.nodes[_selectedNodeId];
    return Column(
      children: [
        _GraphHeader(
          graph: graph,
          selectedNode: selectedNode,
          onReset: _resetView,
        ),
        Expanded(
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 0.45,
              maxScale: 2.5,
              child: SizedBox(
                width: layout.size.width,
                height: layout.size.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GraphEdgePainter(layout.edges),
                      ),
                    ),
                    for (final placedNode in layout.nodes)
                      Positioned(
                        left: placedNode.rect.left,
                        top: placedNode.rect.top,
                        width: placedNode.rect.width,
                        height: placedNode.rect.height,
                        child: _GraphNodeCard(
                          node: placedNode.node,
                          isActive: graph.activeNodeIds.contains(
                            placedNode.node.id,
                          ),
                          isCurrent: graph.activeRouteId == placedNode.node.id,
                          isSelected: _selectedNodeId == placedNode.node.id,
                          onTap:
                              () => setState(() {
                                _selectedNodeId = placedNode.node.id;
                              }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _NavigationGraphMode { topology, observed }

class _GraphModeBar extends StatelessWidget {
  const _GraphModeBar({
    required this.mode,
    required this.observedEdgeCount,
    required this.onChanged,
  });

  final _NavigationGraphMode mode;
  final int observedEdgeCount;
  final ValueChanged<_NavigationGraphMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      color: DebugTheme.background,
      child: Row(
        children: [
          Expanded(
            child: _GraphModeButton(
              label: 'Topology',
              isSelected: mode == _NavigationGraphMode.topology,
              onTap: () => onChanged(_NavigationGraphMode.topology),
            ),
          ),
          Expanded(
            child: _GraphModeButton(
              label: 'Observed',
              count: observedEdgeCount,
              isSelected: mode == _NavigationGraphMode.observed,
              onTap: () => onChanged(_NavigationGraphMode.observed),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphModeButton extends StatelessWidget {
  const _GraphModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              isSelected ? DebugTheme.backgroundLight : DebugTheme.background,
          borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? DebugTheme.textPrimary
                        : DebugTheme.textDisabled,
                fontSize: DebugTheme.fontSizeSm,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: DebugTheme.spacingXs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _GraphColors.branch.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(DebugTheme.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: _GraphColors.branch,
                    fontSize: 8,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GraphHeader extends StatelessWidget {
  const _GraphHeader({
    required this.graph,
    required this.selectedNode,
    required this.onReset,
  });

  final NavigationGraph<Object> graph;
  final NavigationGraphNode<Object>? selectedNode;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final activeNode =
        graph.activeRouteId == null ? null : graph.nodes[graph.activeRouteId];
    final inspectedNode = selectedNode ?? activeNode;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DebugTheme.spacingMd,
        DebugTheme.spacingSm,
        DebugTheme.spacingXs,
        DebugTheme.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: DebugTheme.backgroundDark,
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${graph.name}  •  ${graph.routeCount} routes  •  '
                  '${graph.layoutCount} layouts',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DebugTheme.textPrimary,
                    fontSize: DebugTheme.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  inspectedNode == null
                      ? 'No route matches ${graph.currentUri}'
                      : '${selectedNode == null ? 'Current' : 'Selected'}: '
                          '${inspectedNode.label}  ${inspectedNode.path}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        selectedNode == null
                            ? _GraphColors.active
                            : _GraphColors.selected,
                    fontSize: DebugTheme.fontSizeSm,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onReset,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                CupertinoIcons.arrow_counterclockwise,
                size: 14,
                color: DebugTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphNodeCard extends StatelessWidget {
  const _GraphNodeCard({
    required this.node,
    required this.isActive,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  final NavigationGraphNode<Object> node;
  final bool isActive;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isCurrent
            ? _GraphColors.active
            : isSelected
            ? _GraphColors.selected
            : isActive
            ? _GraphColors.activeMuted
            : DebugTheme.border;
    final background =
        isCurrent
            ? _GraphColors.activeBackground
            : isSelected
            ? _GraphColors.selectedBackground
            : DebugTheme.backgroundLight;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${node.label}, ${node.path}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DebugTheme.spacing),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(DebugTheme.radius),
            border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
            boxShadow:
                isCurrent
                    ? [
                      BoxShadow(
                        color: _GraphColors.active.withValues(alpha: 0.18),
                        blurRadius: 10,
                      ),
                    ]
                    : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    node.isRoute
                        ? CupertinoIcons.arrow_right_circle
                        : CupertinoIcons.layers,
                    color: borderColor,
                    size: 12,
                  ),
                  const SizedBox(width: DebugTheme.spacingXs),
                  Expanded(
                    child: Text(
                      node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DebugTheme.textPrimary,
                        fontSize: DebugTheme.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const Icon(
                      CupertinoIcons.location_fill,
                      color: _GraphColors.active,
                      size: 10,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                node.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DebugTheme.textSecondary,
                  fontSize: DebugTheme.fontSizeSm,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _NodeBadge(label: _kindLabel(node.kind)),
                  if (node.branchIndex case final branchIndex?) ...[
                    const SizedBox(width: 3),
                    _NodeBadge(
                      label: 'BRANCH ${branchIndex + 1}',
                      branch: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeBadge extends StatelessWidget {
  const _NodeBadge({required this.label, this.branch = false});

  final String label;
  final bool branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color:
            branch
                ? _GraphColors.branch.withValues(alpha: 0.12)
                : DebugTheme.backgroundDark,
        borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: branch ? _GraphColors.branch : DebugTheme.textMuted,
          fontSize: 7,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _EmptyGraph extends StatelessWidget {
  const _EmptyGraph();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(DebugTheme.spacingLg),
        child: Text(
          'No declarative route graph found.\n'
          'Expose a RouteManifest from your coordinator.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DebugTheme.textDisabled,
            fontSize: DebugTheme.fontSizeMd,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

final class _GraphLayout {
  const _GraphLayout({
    required this.nodes,
    required this.edges,
    required this.size,
  });

  static const _nodeWidth = 156.0;
  static const _nodeHeight = 74.0;
  static const _horizontalGap = 54.0;
  static const _verticalGap = 18.0;
  static const _padding = 24.0;

  factory _GraphLayout.calculate(NavigationGraph<Object> graph) {
    final placedNodes = <_PlacedGraphNode>[];
    final centers = <Object, Offset>{};
    var leafIndex = 0;
    var maxDepth = 0;

    double place(Object id) {
      final node = graph.nodes[id]!;
      maxDepth = math.max(maxDepth, node.depth);
      final childCenters = <double>[
        for (final childId in node.childIds) place(childId),
      ];
      final centerY =
          childCenters.isEmpty
              ? _padding +
                  _nodeHeight / 2 +
                  leafIndex++ * (_nodeHeight + _verticalGap)
              : (childCenters.first + childCenters.last) / 2;
      final center = Offset(
        _padding + _nodeWidth / 2 + node.depth * (_nodeWidth + _horizontalGap),
        centerY,
      );
      centers[id] = center;
      placedNodes.add(
        _PlacedGraphNode(
          node: node,
          rect: Rect.fromCenter(
            center: center,
            width: _nodeWidth,
            height: _nodeHeight,
          ),
        ),
      );
      return centerY;
    }

    for (final rootId in graph.rootIds) {
      place(rootId);
    }

    final edges = <_GraphEdge>[];
    for (final placedNode in placedNodes) {
      final parentId = placedNode.node.parentId;
      if (parentId == null) continue;
      final parentCenter = centers[parentId]!;
      final childCenter = centers[placedNode.node.id]!;
      edges.add(
        _GraphEdge(
          start: Offset(parentCenter.dx + _nodeWidth / 2, parentCenter.dy),
          end: Offset(childCenter.dx - _nodeWidth / 2, childCenter.dy),
          isActive:
              graph.activeNodeIds.contains(parentId) &&
              graph.activeNodeIds.contains(placedNode.node.id),
          isBranch: placedNode.node.branchIndex != null,
        ),
      );
    }

    final leafCount = math.max(1, leafIndex);
    return _GraphLayout(
      nodes: List.unmodifiable(placedNodes),
      edges: List.unmodifiable(edges),
      size: Size(
        _padding * 2 + (maxDepth + 1) * _nodeWidth + maxDepth * _horizontalGap,
        math.max(
          220,
          _padding * 2 +
              leafCount * _nodeHeight +
              (leafCount - 1) * _verticalGap,
        ),
      ),
    );
  }

  final List<_PlacedGraphNode> nodes;
  final List<_GraphEdge> edges;
  final Size size;
}

final class _PlacedGraphNode {
  const _PlacedGraphNode({required this.node, required this.rect});

  final NavigationGraphNode<Object> node;
  final Rect rect;
}

final class _GraphEdge {
  const _GraphEdge({
    required this.start,
    required this.end,
    required this.isActive,
    required this.isBranch,
  });

  final Offset start;
  final Offset end;
  final bool isActive;
  final bool isBranch;
}

class _GraphEdgePainter extends CustomPainter {
  const _GraphEdgePainter(this.edges);

  final List<_GraphEdge> edges;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final color =
          edge.isActive
              ? _GraphColors.active
              : edge.isBranch
              ? _GraphColors.branch
              : DebugTheme.border;
      final controlOffset = (edge.end.dx - edge.start.dx) * 0.5;
      final path =
          Path()
            ..moveTo(edge.start.dx, edge.start.dy)
            ..cubicTo(
              edge.start.dx + controlOffset,
              edge.start.dy,
              edge.end.dx - controlOffset,
              edge.end.dy,
              edge.end.dx,
              edge.end.dy,
            );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = edge.isActive ? 2 : 1.25,
      );
      canvas.drawCircle(
        edge.start,
        edge.isActive ? 3 : 2,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphEdgePainter oldDelegate) =>
      oldDelegate.edges != edges;
}

String _kindLabel(NavigationGraphNodeKind kind) => switch (kind) {
  NavigationGraphNodeKind.route => 'ROUTE',
  NavigationGraphNodeKind.stackLayout => 'STACK',
  NavigationGraphNodeKind.indexedLayout => 'INDEXED',
  NavigationGraphNodeKind.branchedLayout => 'BRANCHED',
};

abstract final class _GraphColors {
  static const active = Color(0xFF34D399);
  static const activeMuted = Color(0xFF237A61);
  static const activeBackground = Color(0xFF0C2E25);
  static const selected = Color(0xFF60A5FA);
  static const selectedBackground = Color(0xFF112A46);
  static const branch = Color(0xFFA78BFA);
}
