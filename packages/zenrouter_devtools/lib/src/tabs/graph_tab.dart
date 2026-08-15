import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' hide DebugTheme;
import 'package:zenrouter/zenrouter.dart';

import '../coordinator_debug.dart';
import '../graph/navigation_graph.dart';
import '../graph/node_flow_canvas.dart';
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
  final _topologyCanvasKey = GlobalKey<_TopologyNodeFlowCanvasState>();
  Object? _selectedNodeId;
  _NavigationGraphMode _mode = _NavigationGraphMode.topology;

  void _resetView() => _topologyCanvasKey.currentState?.fitToView();

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
          builder: (context, _) => Column(
            children: [
              _GraphModeBar(
                mode: _mode,
                observedEdgeCount: flow.edges.length,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              Expanded(
                child: switch (_mode) {
                  _NavigationGraphMode.topology => _buildTopology(graph),
                  _NavigationGraphMode.observed => ObservedNavigationFlowView(
                    graph: graph,
                    flow: flow,
                    captureEnabled:
                        widget.coordinator.debugScreenCaptureEnabled,
                    onCaptureChanged:
                        widget.coordinator.setDebugScreenCaptureEnabled,
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
    final selectedNode = _selectedNodeId == null
        ? null
        : graph.nodes[_selectedNodeId];
    return Column(
      children: [
        _GraphHeader(
          graph: graph,
          selectedNode: selectedNode,
          onReset: _resetView,
        ),
        Expanded(
          child: _TopologyNodeFlowCanvas(
            key: _topologyCanvasKey,
            graph: graph,
            selectedNodeId: _selectedNodeId,
            onNodeSelected: (id) => setState(() {
              _selectedNodeId = id;
            }),
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
          color: isSelected
              ? DebugTheme.backgroundLight
              : DebugTheme.background,
          borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
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
    final activeNode = graph.activeRouteId == null
        ? null
        : graph.nodes[graph.activeRouteId];
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
                    color: selectedNode == null
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
    super.key,
    required this.node,
    required this.isActive,
    required this.isCurrent,
    required this.isSelected,
  });

  final NavigationGraphNode<Object> node;
  final bool isActive;
  final bool isCurrent;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? _GraphColors.active
        : isSelected
        ? _GraphColors.selected
        : isActive
        ? _GraphColors.activeMuted
        : DebugTheme.border;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${node.label}, ${node.path}',
      child: Padding(
        padding: const EdgeInsets.all(DebugTheme.spacing),
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
                  _NodeBadge(label: 'BRANCH ${branchIndex + 1}', branch: true),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphLayoutGroupCard extends StatelessWidget {
  const _GraphLayoutGroupCard({
    required this.node,
    required this.isActive,
    required this.isSelected,
  });

  final NavigationGraphNode<Object> node;
  final bool isActive;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final layoutColor = _layoutColor(node.kind);
    final borderColor = isSelected
        ? _GraphColors.selected
        : isActive
        ? _GraphColors.activeMuted
        : layoutColor.withValues(alpha: 0.65);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${node.label} layout, ${node.path}',
      child: Container(
        key: ValueKey('topology-layout-group-${node.id}'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: layoutColor.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(DebugTheme.radiusMd),
          border: Border.all(
            color: borderColor,
            width: isSelected || isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(
                horizontal: DebugTheme.spacing,
                vertical: DebugTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: layoutColor.withValues(alpha: 0.13),
                border: Border(
                  bottom: BorderSide(
                    color: layoutColor.withValues(alpha: 0.24),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.layers, color: borderColor, size: 11),
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
                      _NodeBadge(label: _kindLabel(node.kind)),
                      if (node.branchIndex case final branchIndex?) ...[
                        const SizedBox(width: 3),
                        _NodeBadge(label: '#${branchIndex + 1}', branch: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    node.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DebugTheme.textSecondary,
                      fontSize: 8,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
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
        color: branch
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

final _topologyNodeFlowTheme = createNavigationNodeFlowTheme(
  connectionColor: DebugTheme.border,
  selectedColor: _GraphColors.selected,
  endPoint: ConnectionEndPoint.none,
);

class _TopologyNodeFlowCanvas extends StatefulWidget {
  const _TopologyNodeFlowCanvas({
    super.key,
    required this.graph,
    required this.selectedNodeId,
    required this.onNodeSelected,
  });

  final NavigationGraph<Object> graph;
  final Object? selectedNodeId;
  final ValueChanged<Object> onNodeSelected;

  @override
  State<_TopologyNodeFlowCanvas> createState() =>
      _TopologyNodeFlowCanvasState();
}

class _TopologyNodeFlowCanvasState extends State<_TopologyNodeFlowCanvas> {
  late final NodeFlowController<_TopologyNodeData, Object?> _controller;
  late _TopologyNodeFlowModel _model;

  @override
  void initState() {
    super.initState();
    _model = _TopologyNodeFlowModel.calculate(widget.graph);
    _controller = NodeFlowController<_TopologyNodeData, Object?>(
      config: createNavigationNodeFlowConfig(
        minimapThumbnailBuilder: _paintMinimapNode,
      ),
      nodes: _model.nodes,
      connections: _model.connections,
    );
    _restoreSelection();
  }

  @override
  void didUpdateWidget(_TopologyNodeFlowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedNodeIds = <Object>{
      for (final node in _controller.nodes.values)
        if (_controller.isNodeSelected(node.id)) node.data.id,
    };
    final previousPositions = <Object, Offset>{
      for (final node in _controller.nodes.values)
        node.data.id: node.position.value,
    };
    final nextModel = _TopologyNodeFlowModel.calculate(
      widget.graph,
      previousPositions: previousPositions,
    );
    if (nextModel.signature != _model.signature) {
      _model = nextModel;
      _controller.loadGraph(
        NodeGraph<_TopologyNodeData, Object?>(
          nodes: _model.nodes,
          connections: _model.connections,
          viewport: _controller.viewport,
        ),
      );
      _restoreSelection(selectedNodeIds);
    } else if (oldWidget.selectedNodeId != widget.selectedNodeId) {
      _restoreSelection();
    }
  }

  void _restoreSelection([Set<Object> selectedNodeIds = const {}]) {
    final selectedFlowIds = selectedNodeIds
        .map((id) => _model.flowIds[id])
        .whereType<String>()
        .toList(growable: false);
    if (selectedFlowIds.isNotEmpty) {
      _controller.selectNodes(selectedFlowIds);
      return;
    }

    final selectedId = widget.selectedNodeId;
    final flowId = selectedId == null ? null : _model.flowIds[selectedId];
    if (flowId == null) {
      _controller.clearNodeSelection();
    } else if (!_controller.isNodeSelected(flowId)) {
      _controller.selectNode(flowId);
    }
  }

  void fitToView() => _controller.fitToView();

  bool _paintMinimapNode(
    Canvas canvas,
    Node<dynamic> node,
    Rect bounds,
    Color defaultColor,
  ) {
    if (node is GroupNode<dynamic>) return false;
    final data = node.data;
    if (data is! _TopologyNodeData) return false;
    final graphNode = widget.graph.nodes[data.id];
    if (graphNode == null) return false;
    final color = widget.graph.activeRouteId == data.id
        ? _GraphColors.active
        : widget.graph.activeNodeIds.contains(data.id)
        ? _GraphColors.activeMuted
        : defaultColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(1.5)),
      Paint()..color = color,
    );
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationNodeFlowAutoFit(
      onFit: _controller.fitToView,
      child: NodeFlowEditor<_TopologyNodeData, Object?>(
        key: const ValueKey('topology-node-flow'),
        controller: _controller,
        theme: _topologyNodeFlowTheme,
        behavior: NodeFlowBehavior.preview,
        events: NodeFlowEvents<_TopologyNodeData, Object?>(
          onInit: _controller.fitToView,
          node: NodeEvents<_TopologyNodeData>(
            onTap: (node) => widget.onNodeSelected(node.data.id),
          ),
        ),
        nodeBuilder: (context, flowNode) {
          final node = widget.graph.nodes[flowNode.data.id]!;
          return _GraphNodeCard(
            key: ValueKey('topology-route-node-${node.id}'),
            node: node,
            isActive: widget.graph.activeNodeIds.contains(node.id),
            isCurrent: widget.graph.activeRouteId == node.id,
            isSelected: widget.selectedNodeId == node.id,
          );
        },
      ),
    );
  }
}

final class _TopologyNodeData {
  const _TopologyNodeData(this.id);

  final Object id;
}

final class _TopologyNodeFlowModel {
  const _TopologyNodeFlowModel({
    required this.nodes,
    required this.connections,
    required this.flowIds,
    required this.signature,
  });

  static const _nodeWidth = 156.0;
  static const _nodeHeight = 74.0;
  static const _horizontalGap = 28.0;
  static const _verticalGap = 54.0;
  static const _padding = 24.0;
  static const _groupPadding = EdgeInsets.fromLTRB(20, 48, 20, 20);

  factory _TopologyNodeFlowModel.calculate(
    NavigationGraph<Object> graph, {
    Map<Object, Offset> previousPositions = const {},
  }) {
    final positions = <Object, Offset>{};
    final flowIds = <Object, String>{};
    var nodeIndex = 0;
    for (final id in graph.nodes.keys) {
      flowIds[id] = 'topology-node-${nodeIndex++}';
    }

    final subtreeWidths = <Object, double>{};

    double measure(Object id) {
      final node = graph.nodes[id]!;
      final childWidths = <double>[
        for (final childId in node.childIds) measure(childId),
      ];
      final ownWidth = node.isLayout
          ? _nodeWidth + _groupPadding.horizontal
          : _nodeWidth;
      final childrenWidth = childWidths.isEmpty
          ? 0.0
          : childWidths.reduce((left, right) => left + right) +
                _horizontalGap * (childWidths.length - 1);
      final width = childWidths.isEmpty
          ? ownWidth
          : node.isLayout
          ? math.max(ownWidth, childrenWidth + _groupPadding.horizontal)
          : math.max(ownWidth, childrenWidth);
      subtreeWidths[id] = width;
      return width;
    }

    void place(Object id, double left) {
      final node = graph.nodes[id]!;
      final width = subtreeWidths[id]!;
      final ownWidth = node.isLayout
          ? _nodeWidth + _groupPadding.horizontal
          : _nodeWidth;
      positions[id] = Offset(
        left + (width - ownWidth) / 2,
        _padding + node.depth * (_nodeHeight + _verticalGap),
      );

      if (node.childIds.isEmpty) return;
      final childrenWidth =
          node.childIds.fold<double>(
            0,
            (sum, childId) => sum + subtreeWidths[childId]!,
          ) +
          _horizontalGap * (node.childIds.length - 1);
      var childLeft = left + (width - childrenWidth) / 2;
      for (final childId in node.childIds) {
        place(childId, childLeft);
        childLeft += subtreeWidths[childId]! + _horizontalGap;
      }
    }

    for (final rootId in graph.rootIds) {
      measure(rootId);
    }
    var rootLeft = _padding;
    for (final rootId in graph.rootIds) {
      place(rootId, rootLeft);
      rootLeft += subtreeWidths[rootId]! + _horizontalGap;
    }

    final routeInputIds = <Object>{};
    final routeOutputIds = <Object>{};
    for (final node in graph.nodes.values.where((node) => node.isRoute)) {
      final parentId = node.parentId;
      if (parentId != null && graph.nodes[parentId]?.isRoute == true) {
        routeInputIds.add(node.id);
        routeOutputIds.add(parentId);
      }
    }

    final nodes = <Node<_TopologyNodeData>>[];
    final nodesByFlowId = <String, Node<_TopologyNodeData>>{};
    for (final node in graph.nodes.values.where((node) => node.isRoute)) {
      final isCurrent = graph.activeRouteId == node.id;
      final isActive = graph.activeNodeIds.contains(node.id);
      final routeNode = Node<_TopologyNodeData>(
        id: flowIds[node.id]!,
        type: _kindLabel(node.kind),
        position:
            previousPositions[node.id] ?? positions[node.id] ?? Offset.zero,
        size: const Size(_nodeWidth, _nodeHeight),
        data: _TopologyNodeData(node.id),
        ports: createNavigationNodeFlowPorts(
          const Size(_nodeWidth, _nodeHeight),
          includeInput: routeInputIds.contains(node.id),
          includeOutput: routeOutputIds.contains(node.id),
        ),
        theme: _topologyNodeFlowTheme.nodeTheme.copyWith(
          backgroundColor: isCurrent
              ? _GraphColors.activeBackground
              : DebugTheme.backgroundLight,
          borderColor: isCurrent
              ? _GraphColors.active
              : isActive
              ? _GraphColors.activeMuted
              : DebugTheme.border,
          borderWidth: isCurrent ? 1.5 : 1,
        ),
      );
      nodes.add(routeNode);
      nodesByFlowId[routeNode.id] = routeNode;
    }

    final layouts = graph.nodes.values.where((node) => node.isLayout).toList()
      ..sort((left, right) => right.depth.compareTo(left.depth));
    for (final node in layouts) {
      final isActive = graph.activeNodeIds.contains(node.id);
      final group = GroupNode<_TopologyNodeData>(
        id: flowIds[node.id]!,
        position:
            previousPositions[node.id] ?? positions[node.id] ?? Offset.zero,
        size: Size(
          _nodeWidth + _groupPadding.horizontal,
          _nodeHeight + _groupPadding.vertical,
        ),
        title: node.label,
        data: _TopologyNodeData(node.id),
        color: _layoutColor(node.kind),
        behavior: GroupBehavior.explicit,
        nodeIds: {for (final childId in node.childIds) flowIds[childId]!},
        padding: _groupPadding,
        zIndex: -1000 + node.depth,
        preserveWhenEmpty: true,
        widgetBuilder: (context, flowNode) => _GraphLayoutGroupCard(
          node: node,
          isActive: isActive,
          isSelected: flowNode.isSelected,
        ),
      );
      nodes.add(group);
      nodesByFlowId[group.id] = group;
      group.fitToNodes((id) => nodesByFlowId[id]);
    }

    final connections = <Connection<Object?>>[];
    var connectionIndex = 0;
    for (final node in graph.nodes.values) {
      final parentId = node.parentId;
      if (parentId == null) continue;
      final parent = graph.nodes[parentId];
      if (parent == null || parent.isLayout || node.isLayout) continue;
      final isActive =
          graph.activeNodeIds.contains(parentId) &&
          graph.activeNodeIds.contains(node.id);
      final color = isActive
          ? _GraphColors.active
          : node.branchIndex != null
          ? _GraphColors.branch
          : DebugTheme.border;
      connections.add(
        Connection<Object?>(
          id: 'topology-edge-${connectionIndex++}',
          sourceNodeId: flowIds[parentId]!,
          sourcePortId: nodeFlowOutputPortId,
          targetNodeId: flowIds[node.id]!,
          targetPortId: nodeFlowInputPortId,
          color: color,
          selectedColor: color,
          strokeWidth: isActive ? 2 : 1.25,
          selectedStrokeWidth: isActive ? 2 : 1.25,
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.none,
          locked: true,
        ),
      );
    }

    return _TopologyNodeFlowModel(
      nodes: List.unmodifiable(nodes),
      connections: List.unmodifiable(connections),
      flowIds: Map.unmodifiable(flowIds),
      signature: Object.hashAll([
        graph.nodes.length,
        for (final node in graph.nodes.values) ...[
          node.id,
          node.parentId,
          node.kind,
          node.depth,
          node.branchIndex,
          graph.activeNodeIds.contains(node.id),
        ],
      ]),
    );
  }

  final List<Node<_TopologyNodeData>> nodes;
  final List<Connection<Object?>> connections;
  final Map<Object, String> flowIds;
  final int signature;
}

String _kindLabel(NavigationGraphNodeKind kind) => switch (kind) {
  NavigationGraphNodeKind.route => 'ROUTE',
  NavigationGraphNodeKind.stackLayout => 'STACK',
  NavigationGraphNodeKind.indexedLayout => 'INDEXED',
  NavigationGraphNodeKind.branchedLayout => 'BRANCHED',
};

Color _layoutColor(NavigationGraphNodeKind kind) => switch (kind) {
  NavigationGraphNodeKind.stackLayout => _GraphColors.stack,
  NavigationGraphNodeKind.indexedLayout => _GraphColors.indexed,
  NavigationGraphNodeKind.branchedLayout => _GraphColors.branch,
  NavigationGraphNodeKind.route => DebugTheme.border,
};

abstract final class _GraphColors {
  static const active = Color(0xFF34D399);
  static const activeMuted = Color(0xFF237A61);
  static const activeBackground = Color(0xFF0C2E25);
  static const selected = Color(0xFF60A5FA);
  static const stack = Color(0xFF94A3B8);
  static const indexed = Color(0xFF38BDF8);
  static const branch = Color(0xFFA78BFA);
}
