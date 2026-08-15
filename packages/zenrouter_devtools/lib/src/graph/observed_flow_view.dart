import 'package:flutter/cupertino.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' hide DebugTheme;

import '../widgets/debug_theme.dart';
import 'navigation_flow.dart';
import 'navigation_graph.dart';
import 'node_flow_canvas.dart';

class ObservedNavigationFlowView extends StatefulWidget {
  const ObservedNavigationFlowView({
    super.key,
    required this.graph,
    required this.flow,
    required this.captureEnabled,
    required this.onCaptureChanged,
    required this.onClear,
  });

  final NavigationGraph<Object> graph;
  final NavigationFlowRecorder<Object> flow;
  final bool captureEnabled;
  final ValueChanged<bool> onCaptureChanged;
  final VoidCallback onClear;

  @override
  State<ObservedNavigationFlowView> createState() =>
      _ObservedNavigationFlowViewState();
}

class _ObservedNavigationFlowViewState
    extends State<ObservedNavigationFlowView> {
  late final NodeFlowController<_ObservedNodeData, Object?> _controller;
  late _ObservedNodeFlowModel _model;
  Object? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _model = _ObservedNodeFlowModel.calculate(widget.graph, widget.flow);
    _controller = NodeFlowController<_ObservedNodeData, Object?>(
      config: createNavigationNodeFlowConfig(
        minimapThumbnailBuilder: _paintMinimapNode,
      ),
      nodes: _model.nodes,
      connections: _model.connections,
    );
  }

  @override
  void didUpdateWidget(ObservedNavigationFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedNodeIds = <Object>{
      for (final node in _controller.nodes.values)
        if (_controller.isNodeSelected(node.id)) node.data.id,
    };
    final previousPositions = <Object, Offset>{
      for (final node in _controller.nodes.values)
        node.data.id: node.position.value,
    };
    final nextModel = _ObservedNodeFlowModel.calculate(
      widget.graph,
      widget.flow,
      previousPositions: previousPositions,
    );
    if (nextModel.signature != _model.signature) {
      _model = nextModel;
      _controller.loadGraph(
        NodeGraph<_ObservedNodeData, Object?>(
          nodes: _model.nodes,
          connections: _model.connections,
          viewport: _controller.viewport,
        ),
      );
      _restoreSelection(selectedNodeIds);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetView() => _controller.fitToView();

  bool _paintMinimapNode(
    Canvas canvas,
    Node<dynamic> node,
    Rect bounds,
    Color defaultColor,
  ) {
    final data = node.data;
    if (data is! _ObservedNodeData) return false;
    final color = widget.graph.activeRouteId == data.id
        ? _ObservedFlowColors.active
        : defaultColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(1.5)),
      Paint()..color = color,
    );
    return true;
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

    final selectedId = _selectedNodeId;
    final flowId = selectedId == null ? null : _model.flowIds[selectedId];
    if (flowId == null) {
      _controller.clearNodeSelection();
    } else if (!_controller.isNodeSelected(flowId)) {
      _controller.selectNode(flowId);
    }
  }

  void _clearFlow() {
    setState(() => _selectedNodeId = null);
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final currentId = widget.graph.activeRouteId;
    final inspectedId = _selectedNodeId ?? currentId;
    final inspectedNode = inspectedId == null
        ? null
        : widget.graph.nodes[inspectedId];

    return Column(
      children: [
        _FlowHeader(
          flow: widget.flow,
          inspectedNode: inspectedNode,
          isSelected: _selectedNodeId != null,
          captureEnabled: widget.captureEnabled,
          onCaptureChanged: widget.onCaptureChanged,
          onReset: _resetView,
          onClear: _clearFlow,
        ),
        Expanded(
          child: widget.flow.edges.isEmpty
              ? const _EmptyObservedFlow()
              : NavigationNodeFlowAutoFit(
                  onFit: _controller.fitToView,
                  child: NodeFlowEditor<_ObservedNodeData, Object?>(
                    key: const ValueKey('observed-node-flow'),
                    controller: _controller,
                    theme: _observedNodeFlowTheme,
                    behavior: NodeFlowBehavior.preview,
                    events: NodeFlowEvents<_ObservedNodeData, Object?>(
                      onInit: _controller.fitToView,
                      node: NodeEvents<_ObservedNodeData>(
                        onTap: (node) => setState(() {
                          _selectedNodeId = node.data.id;
                        }),
                      ),
                    ),
                    labelBuilder:
                        (context, connection, label, position, onTap) =>
                            _ObservedFlowEdgeLabel(
                              label: label.text,
                              size: position.size,
                              onTap: onTap,
                            ),
                    nodeBuilder: (context, node) {
                      final id = node.data.id;
                      final graphNode = widget.graph.nodes[id]!;
                      final flowNode = widget.flow.nodes[id]!;
                      return _ObservedFlowNodeCard(
                        key: ValueKey('observed-flow-node-$id'),
                        graphNode: graphNode,
                        flowNode: flowNode,
                        isCurrent: currentId == id,
                        isSelected: _selectedNodeId == id,
                        captureEnabled: widget.captureEnabled,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.flow,
    required this.inspectedNode,
    required this.isSelected,
    required this.captureEnabled,
    required this.onCaptureChanged,
    required this.onReset,
    required this.onClear,
  });

  final NavigationFlowRecorder<Object> flow;
  final NavigationGraphNode<Object>? inspectedNode;
  final bool isSelected;
  final bool captureEnabled;
  final ValueChanged<bool> onCaptureChanged;
  final VoidCallback onReset;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final node = inspectedNode;
    final previewCount = flow.nodes.values
        .where((flowNode) => flowNode.screenPreview != null)
        .length;
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
                  '${flow.nodes.length} screens  •  ${flow.edges.length} '
                  'paths  •  ${flow.transitions.length} transitions'
                  '${previewCount == 0 ? '' : '  •  $previewCount previews'}'
                  '${flow.ignoredTransitionCount == 0 ? '' : '  •  ${flow.ignoredTransitionCount} unmatched'}',
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
                  node == null
                      ? 'Navigate in the app to discover a flow'
                      : '${isSelected ? 'Selected' : 'Current'}: '
                            '${node.label}  ${node.path}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? _ObservedFlowColors.selected
                        : _ObservedFlowColors.active,
                    fontSize: DebugTheme.fontSizeSm,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            key: const ValueKey('observed-screen-capture-toggle'),
            semanticsLabel: captureEnabled
                ? 'Disable automatic screen previews'
                : 'Enable automatic screen previews',
            icon: captureEnabled
                ? CupertinoIcons.camera_fill
                : CupertinoIcons.camera,
            color: captureEnabled
                ? _ObservedFlowColors.active
                : DebugTheme.textSecondary,
            onTap: () => onCaptureChanged(!captureEnabled),
          ),
          _HeaderAction(
            semanticsLabel: 'Reset observed graph view',
            icon: CupertinoIcons.arrow_counterclockwise,
            onTap: onReset,
          ),
          _HeaderAction(
            semanticsLabel: 'Clear observed flow',
            icon: CupertinoIcons.trash,
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.color = DebugTheme.textSecondary,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 32,
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _EmptyObservedFlow extends StatelessWidget {
  const _EmptyObservedFlow();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(DebugTheme.spacingLg),
        child: Text(
          'No transitions observed yet.\n'
          'Keep this devtool attached and navigate around the app.',
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

class _ObservedFlowNodeCard extends StatelessWidget {
  const _ObservedFlowNodeCard({
    super.key,
    required this.graphNode,
    required this.flowNode,
    required this.isCurrent,
    required this.isSelected,
    required this.captureEnabled,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final bool isCurrent;
  final bool isSelected;
  final bool captureEnabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? _ObservedFlowColors.active
        : isSelected
        ? _ObservedFlowColors.selected
        : DebugTheme.border;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${graphNode.label}, visited ${flowNode.visitCount} times',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DebugTheme.radius - 1),
        child: ColoredBox(
          color: const Color(0x00000000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ObservedScreenPreview(
                  key: ValueKey('observed-screen-preview-${graphNode.id}'),
                  preview: flowNode.screenPreview,
                  captureEnabled: captureEnabled,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DebugTheme.spacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.rectangle_stack,
                          color: borderColor,
                          size: 12,
                        ),
                        const SizedBox(width: DebugTheme.spacingXs),
                        Expanded(
                          child: Text(
                            graphNode.label,
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
                            color: _ObservedFlowColors.active,
                            size: 10,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            flowNode.lastUri.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DebugTheme.textSecondary,
                              fontSize: DebugTheme.fontSizeSm,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Text(
                          '×${flowNode.visitCount}',
                          style: const TextStyle(
                            color: DebugTheme.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObservedScreenPreview extends StatelessWidget {
  const _ObservedScreenPreview({
    super.key,
    required this.preview,
    required this.captureEnabled,
  });

  final NavigationFlowScreenPreview? preview;
  final bool captureEnabled;

  @override
  Widget build(BuildContext context) {
    final screenPreview = preview;
    if (screenPreview != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            screenPreview.bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) => _buildPlaceholder(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x08000000), Color(0x66000000)],
              ),
            ),
          ),
        ],
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() => ColoredBox(
    color: DebugTheme.backgroundDark,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            captureEnabled ? CupertinoIcons.camera : CupertinoIcons.eye_slash,
            color: DebugTheme.textMuted,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            captureEnabled ? 'WAITING FOR PREVIEW' : 'SCREEN CAPTURE OFF',
            style: const TextStyle(
              color: DebugTheme.textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ObservedFlowEdgeLabel extends StatelessWidget {
  const _ObservedFlowEdgeLabel({
    required this.label,
    required this.size,
    required this.onTap,
  });

  final String label;
  final Size size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: size.height),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: DebugTheme.backgroundDark,
          borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
          border: Border.all(color: DebugTheme.borderDark),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: DebugTheme.textPrimary,
            fontSize: 8,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

final _observedNodeFlowTheme = createNavigationNodeFlowTheme(
  connectionColor: _ObservedFlowColors.edge,
  selectedColor: _ObservedFlowColors.selected,
  endPoint: ConnectionEndPoint.triangle,
);

final class _ObservedNodeData {
  const _ObservedNodeData(this.id);

  final Object id;
}

final class _ObservedNodeFlowModel {
  const _ObservedNodeFlowModel({
    required this.nodes,
    required this.connections,
    required this.flowIds,
    required this.signature,
  });

  static const _nodeWidth = 180.0;
  static const _nodeHeight = 142.0;
  static const _horizontalGap = 38.0;
  static const _verticalGap = 82.0;
  static const _padding = 52.0;

  factory _ObservedNodeFlowModel.calculate(
    NavigationGraph<Object> graph,
    NavigationFlowRecorder<Object> flow, {
    Map<Object, Offset> previousPositions = const {},
  }) {
    final depths = <Object, int>{};
    final entryId = flow.entryNodeId;
    if (entryId != null) depths[entryId] = 0;
    for (final edge in flow.edges) {
      depths.putIfAbsent(edge.fromId, () => 0);
      depths.putIfAbsent(edge.toId, () => (depths[edge.fromId] ?? 0) + 1);
    }

    final orderedFlowNodes = flow.nodes.values.toList(growable: false)
      ..sort(
        (left, right) =>
            left.firstSeenRevision.compareTo(right.firstSeenRevision),
      );
    final columns = <int, List<NavigationFlowNode<Object>>>{};
    for (final node in orderedFlowNodes) {
      columns.putIfAbsent(depths[node.id] ?? 0, () => []).add(node);
    }

    final positions = <Object, Offset>{};
    for (final entry in columns.entries) {
      for (var column = 0; column < entry.value.length; column += 1) {
        final flowNode = entry.value[column];
        final graphNode = graph.nodes[flowNode.id];
        if (graphNode == null) continue;
        final center = Offset(
          _padding + _nodeWidth / 2 + column * (_nodeWidth + _horizontalGap),
          _padding + _nodeHeight / 2 + entry.key * (_nodeHeight + _verticalGap),
        );
        positions[flowNode.id] = Offset(
          center.dx - _nodeWidth / 2,
          center.dy - _nodeHeight / 2,
        );
      }
    }

    final flowIds = <Object, String>{};
    var nodeIndex = 0;
    final nodes = <Node<_ObservedNodeData>>[];
    for (final flowNode in orderedFlowNodes) {
      if (!positions.containsKey(flowNode.id)) continue;
      final id = 'observed-node-${nodeIndex++}';
      flowIds[flowNode.id] = id;
      final isCurrent = graph.activeRouteId == flowNode.id;
      nodes.add(
        Node<_ObservedNodeData>(
          id: id,
          type: 'screen',
          position: previousPositions[flowNode.id] ?? positions[flowNode.id]!,
          size: const Size(_nodeWidth, _nodeHeight),
          data: _ObservedNodeData(flowNode.id),
          ports: createNavigationNodeFlowPorts(
            const Size(_nodeWidth, _nodeHeight),
          ),
          theme: _observedNodeFlowTheme.nodeTheme.copyWith(
            backgroundColor: isCurrent
                ? _ObservedFlowColors.activeBackground
                : DebugTheme.backgroundLight,
            borderColor: isCurrent
                ? _ObservedFlowColors.active
                : DebugTheme.border,
            borderWidth: isCurrent ? 1.5 : 1,
          ),
        ),
      );
    }

    final connections = <Connection<Object?>>[];
    var connectionIndex = 0;
    for (final edge in flow.edges) {
      final sourceId = flowIds[edge.fromId];
      final targetId = flowIds[edge.toId];
      if (sourceId == null || targetId == null) continue;
      connections.add(
        Connection<Object?>(
          id: 'observed-edge-${connectionIndex++}',
          sourceNodeId: sourceId,
          sourcePortId: nodeFlowOutputPortId,
          targetNodeId: targetId,
          targetPortId: nodeFlowInputPortId,
          label: ConnectionLabel.center(
            text: '${edge.displayLabel} ×${edge.count}',
          ),
          color: _ObservedFlowColors.edge,
          selectedColor: _ObservedFlowColors.selected,
          strokeWidth: 1.6,
          selectedStrokeWidth: 2,
          startPoint: ConnectionEndPoint.none,
          endPoint: ConnectionEndPoint.triangle,
          locked: true,
        ),
      );
    }

    return _ObservedNodeFlowModel(
      nodes: List.unmodifiable(nodes),
      connections: List.unmodifiable(connections),
      flowIds: Map.unmodifiable(flowIds),
      signature: Object.hashAll([
        graph.activeRouteId,
        for (final node in orderedFlowNodes) ...[
          node.id,
          node.firstSeenRevision,
        ],
        for (final edge in flow.edges) ...[
          edge.fromId,
          edge.toId,
          edge.count,
          edge.displayLabel,
        ],
      ]),
    );
  }

  final List<Node<_ObservedNodeData>> nodes;
  final List<Connection<Object?>> connections;
  final Map<Object, String> flowIds;
  final int signature;
}

abstract final class _ObservedFlowColors {
  static const active = Color(0xFF34D399);
  static const activeBackground = Color(0xFF0C2E25);
  static const selected = Color(0xFF60A5FA);
  static const edge = Color(0xFFA78BFA);
}
