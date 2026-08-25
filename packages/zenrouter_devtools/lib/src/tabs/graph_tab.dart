import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
  bool _isTopologyReadOnly = false;

  void _resetView() => _topologyCanvasKey.currentState?.fitToView();

  Future<void> _navigateToPath(String path) async {
    if (path.isEmpty) return;
    try {
      final uri = Uri.parse(path);
      final route = await widget.coordinator.parseRouteFromUri(uri);
      if (route != null) {
        widget.coordinator.navigate(route);
      }
    } catch (_) {
      // Platform views or unresolvable path
    }
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
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
                    manifest: widget.coordinator.routeManifest,
                    acquireRecordingPause: widget
                        .coordinator
                        .acquireDebugNavigationFlowRecordingPause,
                    captureEnabled:
                        widget.coordinator.debugScreenCaptureEnabled,
                    onCaptureChanged:
                        widget.coordinator.setDebugScreenCaptureEnabled,
                    onClear: widget.coordinator.clearDebugNavigationFlow,
                    onNavigate: _navigateToPath,
                    onCopy: _copyToClipboard,
                    onDrive: widget.coordinator.debugDriveToUri,
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
          isReadOnly: _isTopologyReadOnly,
          onReadOnlyChanged: (val) => setState(() => _isTopologyReadOnly = val),
          onAutoLayout: _autoLayout,
          onReset: _resetView,
          onNavigate: (path) => _navigateToPath(path),
          onCopy: (text) => _copyToClipboard(text),
        ),
        Expanded(
          child: _TopologyNodeFlowCanvas(
            key: _topologyCanvasKey,
            graph: graph,
            selectedNodeId: _selectedNodeId,
            isReadOnly: _isTopologyReadOnly,
            onNodeSelected: (id) => setState(() {
              _selectedNodeId = id;
            }),
            onNavigate: _navigateToPath,
            onCopy: _copyToClipboard,
          ),
        ),
      ],
    );
  }

  void _autoLayout() => _topologyCanvasKey.currentState?.autoLayout();
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
    final seeThrough = DebugPanelAppearance.seeThroughOf(context);
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      color: DebugTheme.surface(DebugTheme.background, seeThrough: seeThrough),
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
    final seeThrough = DebugPanelAppearance.seeThroughOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? DebugTheme.surface(
                  DebugTheme.backgroundLight,
                  seeThrough: seeThrough,
                )
              : DebugTheme.surface(
                  DebugTheme.background,
                  seeThrough: seeThrough,
                ),
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
    required this.isReadOnly,
    required this.onReadOnlyChanged,
    required this.onAutoLayout,
    required this.onReset,
    required this.onNavigate,
    required this.onCopy,
  });

  final NavigationGraph<Object> graph;
  final NavigationGraphNode<Object>? selectedNode;
  final bool isReadOnly;
  final ValueChanged<bool> onReadOnlyChanged;
  final VoidCallback onAutoLayout;
  final VoidCallback onReset;
  final ValueChanged<String> onNavigate;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final activeNode = graph.activeRouteId == null
        ? null
        : graph.nodes[graph.activeRouteId];
    final inspectedNode = selectedNode ?? activeNode;
    final seeThrough = DebugPanelAppearance.seeThroughOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DebugTheme.spacingMd,
        DebugTheme.spacingSm,
        DebugTheme.spacingXs,
        DebugTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: DebugTheme.surface(
          DebugTheme.backgroundDark,
          seeThrough: seeThrough,
        ),
        border: const Border(bottom: BorderSide(color: DebugTheme.borderDark)),
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
          if (inspectedNode != null && inspectedNode.isRoute) ...[
            _HeaderIconButton(
              tooltip: 'Navigate to ${inspectedNode.path}',
              icon: CupertinoIcons.compass,
              color: _GraphColors.active,
              onTap: () => onNavigate(inspectedNode.path),
            ),
            _HeaderIconButton(
              tooltip: 'Copy URI path',
              icon: CupertinoIcons.doc_on_doc,
              color: DebugTheme.textSecondary,
              onTap: () => onCopy(inspectedNode.path),
            ),
          ],
          _HeaderIconButton(
            key: const ValueKey('topology-mode-toggle'),
            tooltip: isReadOnly
                ? 'Switch to move mode (unlock nodes)'
                : 'Switch to readonly mode (lock nodes)',
            icon: isReadOnly
                ? CupertinoIcons.lock_fill
                : CupertinoIcons.lock_open,
            color: isReadOnly
                ? _GraphColors.selected
                : DebugTheme.textSecondary,
            onTap: () => onReadOnlyChanged(!isReadOnly),
          ),
          _HeaderIconButton(
            key: const ValueKey('topology-auto-layout'),
            tooltip: 'Auto layout graph',
            icon: CupertinoIcons.sparkles,
            color: _GraphColors.selected,
            onTap: onAutoLayout,
          ),
          _HeaderIconButton(
            tooltip: 'Reset view',
            icon: CupertinoIcons.arrow_counterclockwise,
            color: DebugTheme.textSecondary,
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color = DebugTheme.textSecondary,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: color),
        ),
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
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraphNode<Object> node;
  final bool isActive;
  final bool isCurrent;
  final bool isSelected;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<String>? onCopy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${node.label}, ${node.path}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DebugTheme.textPrimary,
                      fontSize: DebugTheme.fontSizeSm,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: _GraphColors.activeBackground,
                      borderRadius: BorderRadius.circular(
                        DebugTheme.radiusFull,
                      ),
                      border: Border.all(
                        color: _GraphColors.active.withValues(alpha: 0.8),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: _GraphColors.active,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: _GraphColors.active,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Text(
              node.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DebugTheme.textSecondary,
                fontSize: 8.5,
                fontFamily: 'monospace',
                decoration: TextDecoration.underline,
              ),
            ),
            Row(
              children: [
                _NodeBadge(label: _kindLabel(node.kind)),
                if (node.branchIndex case final branchIndex?) ...[
                  const SizedBox(width: 3),
                  _NodeBadge(label: '#${branchIndex + 1}', branch: true),
                ],
                const Spacer(),
                if (node.isRoute && onNavigate != null)
                  GestureDetector(
                    onTap: () => onNavigate!(node.path),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: DebugTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(
                          DebugTheme.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.compass,
                        size: 11,
                        color: DebugTheme.textMuted,
                      ),
                    ),
                  ),
                if (node.isRoute && onCopy != null) ...[
                  const SizedBox(width: 3),
                  GestureDetector(
                    onTap: () => onCopy!(node.path),
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: DebugTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(
                          DebugTheme.radiusSm,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_on_doc,
                        size: 11,
                        color: DebugTheme.textMuted,
                      ),
                    ),
                  ),
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
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: layoutColor.withValues(alpha: 0.13),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DebugTheme.radiusMd),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: layoutColor.withValues(alpha: 0.24),
                  ),
                ),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Text(
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
                  _NodeBadge(label: _kindLabel(node.kind)),
                  if (node.branchIndex case final branchIndex?) ...[
                    _NodeBadge(label: '#${branchIndex + 1}', branch: true),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: branch
            ? _GraphColors.branch.withValues(alpha: 0.14)
            : DebugTheme.backgroundDark,
        borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
        border: Border.all(
          color: branch
              ? _GraphColors.branch.withValues(alpha: 0.3)
              : DebugTheme.borderDark,
          width: 0.6,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: branch ? _GraphColors.branch : DebugTheme.textMuted,
          fontSize: 7.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
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
    required this.isReadOnly,
    required this.onNodeSelected,
    required this.onNavigate,
    required this.onCopy,
  });

  final NavigationGraph<Object> graph;
  final Object? selectedNodeId;
  final bool isReadOnly;
  final ValueChanged<Object> onNodeSelected;
  final ValueChanged<String> onNavigate;
  final ValueChanged<String> onCopy;

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
    if (oldWidget.isReadOnly != widget.isReadOnly) {
      _controller.setBehavior(
        widget.isReadOnly ? NodeFlowBehavior.inspect : NodeFlowBehavior.preview,
      );
    }
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

  void autoLayout() {
    final selectedNodeIds = <Object>{
      for (final node in _controller.nodes.values)
        if (_controller.isNodeSelected(node.id)) node.data.id,
    };
    _model = _TopologyNodeFlowModel.calculate(widget.graph);
    _controller.loadGraph(
      NodeGraph<_TopologyNodeData, Object?>(
        nodes: _model.nodes,
        connections: _model.connections,
        viewport: _controller.viewport,
      ),
    );
    _restoreSelection(selectedNodeIds);
    _controller.fitToView();
  }

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
      RRect.fromRectAndRadius(bounds, Radius.circular(DebugTheme.radiusSm)),
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
    final canvasBackground = navigationNodeFlowBackgroundColor(context);
    return NavigationNodeFlowAutoFit(
      onFit: _controller.fitToView,
      child: NodeFlowEditor<_TopologyNodeData, Object?>(
        key: const ValueKey('topology-node-flow'),
        controller: _controller,
        theme: _topologyNodeFlowTheme.copyWith(
          backgroundColor: canvasBackground,
          portTheme: _topologyNodeFlowTheme.portTheme.copyWith(
            borderColor: canvasBackground,
          ),
        ),
        behavior: widget.isReadOnly
            ? NodeFlowBehavior.inspect
            : NodeFlowBehavior.preview,
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
            onNavigate: widget.onNavigate,
            onCopy: widget.onCopy,
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

final class _SubtreeMetrics {
  const _SubtreeMetrics({required this.width, required this.height});

  final double width;
  final double height;
}

final class _WrappedRow {
  const _WrappedRow({
    required this.ids,
    required this.width,
    required this.height,
  });

  final List<Object> ids;
  final double width;
  final double height;
}

final class _WrappedGrid {
  const _WrappedGrid({
    required this.rows,
    required this.width,
    required this.height,
  });

  static const empty = _WrappedGrid(rows: [], width: 0, height: 0);

  final List<_WrappedRow> rows;
  final double width;
  final double height;
}

final class _TopologyNodeFlowModel {
  const _TopologyNodeFlowModel({
    required this.nodes,
    required this.connections,
    required this.flowIds,
    required this.signature,
  });

  static const _nodeWidth = 152.0;
  static const _nodeHeight = 68.0;
  static const _horizontalGap = 16.0;
  static const _verticalGap = 16.0;
  static const _maxCardsPerRow = 4;
  static const _padding = 16.0;
  static const _groupPadding = EdgeInsets.fromLTRB(18, 48, 18, 18);

  static _WrappedGrid _wrapGrid(
    List<Object> ids,
    Map<Object, _SubtreeMetrics> metrics,
  ) {
    if (ids.isEmpty) return _WrappedGrid.empty;

    final rows = <_WrappedRow>[];
    var gridWidth = 0.0;
    var gridHeight = 0.0;
    for (var start = 0; start < ids.length; start += _maxCardsPerRow) {
      final end = math.min(start + _maxCardsPerRow, ids.length);
      var rowWidth = 0.0;
      var rowHeight = 0.0;
      for (var i = start; i < end; i++) {
        final size = metrics[ids[i]]!;
        if (i > start) rowWidth += _horizontalGap;
        rowWidth += size.width;
        rowHeight = math.max(rowHeight, size.height);
      }
      rows.add(
        _WrappedRow(
          ids: ids.sublist(start, end),
          width: rowWidth,
          height: rowHeight,
        ),
      );
      gridWidth = math.max(gridWidth, rowWidth);
      if (rows.length > 1) gridHeight += _verticalGap;
      gridHeight += rowHeight;
    }
    return _WrappedGrid(rows: rows, width: gridWidth, height: gridHeight);
  }

  static void _placeGrid(
    _WrappedGrid grid,
    Map<Object, _SubtreeMetrics> metrics, {
    required double left,
    required double top,
    required void Function(Object id, double left, double top) placeChild,
  }) {
    var y = top;
    for (var r = 0; r < grid.rows.length; r++) {
      final row = grid.rows[r];
      var x = left;
      for (final id in row.ids) {
        final size = metrics[id]!;
        placeChild(id, x, y + (row.height - size.height) / 2);
        x += size.width + _horizontalGap;
      }
      y += row.height;
      if (r < grid.rows.length - 1) y += _verticalGap;
    }
  }

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

    final subtreeMetrics = <Object, _SubtreeMetrics>{};

    _SubtreeMetrics measure(Object id) {
      final node = graph.nodes[id]!;
      if (node.childIds.isEmpty) {
        final size = node.isLayout
            ? Size(
                _nodeWidth + _groupPadding.horizontal,
                _nodeHeight + _groupPadding.vertical,
              )
            : const Size(_nodeWidth, _nodeHeight);
        final metrics = _SubtreeMetrics(width: size.width, height: size.height);
        subtreeMetrics[id] = metrics;
        return metrics;
      }

      for (final childId in node.childIds) {
        measure(childId);
      }

      final childRouteIds = node.childIds
          .where((childId) => graph.nodes[childId]!.isRoute)
          .toList(growable: false);
      final childLayoutIds = node.childIds
          .where((childId) => graph.nodes[childId]!.isLayout)
          .toList(growable: false);

      // 1. Route children wrap horizontally, 4 cards per row.
      final routesGrid = _wrapGrid(childRouteIds, subtreeMetrics);

      // 2. Nested layouts stack vertically.
      final layoutsWidth = childLayoutIds.isEmpty
          ? 0.0
          : childLayoutIds.fold<double>(
              0.0,
              (maxW, childId) => math.max(maxW, subtreeMetrics[childId]!.width),
            );
      final layoutsHeight = childLayoutIds.isEmpty
          ? 0.0
          : childLayoutIds.fold<double>(
                  0.0,
                  (sum, childId) => sum + subtreeMetrics[childId]!.height,
                ) +
                _verticalGap * (childLayoutIds.length - 1);

      final innerContentWidth = math.max(routesGrid.width, layoutsWidth);
      final innerContentHeight =
          routesGrid.height +
          layoutsHeight +
          (routesGrid.height > 0 && layoutsHeight > 0 ? _verticalGap : 0.0);

      double finalWidth;
      double finalHeight;

      if (node.isLayout) {
        finalWidth = math.max(
          innerContentWidth + _groupPadding.horizontal,
          _nodeWidth + _groupPadding.horizontal,
        );
        finalHeight = math.max(
          innerContentHeight + _groupPadding.vertical,
          _nodeHeight + _groupPadding.vertical,
        );
      } else {
        finalWidth = math.max(_nodeWidth, innerContentWidth);
        finalHeight =
            _nodeHeight +
            (innerContentHeight > 0 ? innerContentHeight + _verticalGap : 0.0);
      }

      final metrics = _SubtreeMetrics(width: finalWidth, height: finalHeight);
      subtreeMetrics[id] = metrics;
      return metrics;
    }

    void place(Object id, double left, double top) {
      final node = graph.nodes[id]!;
      final metrics = subtreeMetrics[id]!;

      final childRouteIds = node.childIds
          .where((childId) => graph.nodes[childId]!.isRoute)
          .toList(growable: false);
      final childLayoutIds = node.childIds
          .where((childId) => graph.nodes[childId]!.isLayout)
          .toList(growable: false);

      final routesGrid = _wrapGrid(childRouteIds, subtreeMetrics);
      final layoutsHeight = childLayoutIds.isEmpty
          ? 0.0
          : childLayoutIds.fold<double>(
                  0.0,
                  (sum, childId) => sum + subtreeMetrics[childId]!.height,
                ) +
                _verticalGap * (childLayoutIds.length - 1);

      if (node.isLayout) {
        positions[id] = Offset(left, top);
        if (node.childIds.isEmpty) return;

        final innerLeft = left + _groupPadding.left;
        final innerTop = top + _groupPadding.top;
        final availableWidth = metrics.width - _groupPadding.horizontal;
        final availableHeight = metrics.height - _groupPadding.vertical;
        final totalInnerContentHeight =
            routesGrid.height +
            layoutsHeight +
            (routesGrid.height > 0 && layoutsHeight > 0 ? _verticalGap : 0.0);

        var currentY =
            innerTop + (availableHeight - totalInnerContentHeight) / 2;

        if (routesGrid.rows.isNotEmpty) {
          _placeGrid(
            routesGrid,
            subtreeMetrics,
            left: innerLeft + (availableWidth - routesGrid.width) / 2,
            top: currentY,
            placeChild: place,
          );
          currentY += routesGrid.height + _verticalGap;
        }

        for (final layoutId in childLayoutIds) {
          final childM = subtreeMetrics[layoutId]!;
          final layoutX = innerLeft + (availableWidth - childM.width) / 2;
          place(layoutId, layoutX, currentY);
          currentY += childM.height + _verticalGap;
        }
      } else {
        positions[id] = Offset(left + (metrics.width - _nodeWidth) / 2, top);
        if (node.childIds.isEmpty) return;

        var currentY = top + _nodeHeight + _verticalGap;
        if (routesGrid.rows.isNotEmpty) {
          _placeGrid(
            routesGrid,
            subtreeMetrics,
            left: left + (metrics.width - routesGrid.width) / 2,
            top: currentY,
            placeChild: place,
          );
          currentY += routesGrid.height + _verticalGap;
        }
        for (final layoutId in childLayoutIds) {
          final childM = subtreeMetrics[layoutId]!;
          place(layoutId, left + (metrics.width - childM.width) / 2, currentY);
          currentY += childM.height + _verticalGap;
        }
      }
    }

    for (final rootId in graph.rootIds) {
      measure(rootId);
    }

    final rootLayoutIds = graph.rootIds
        .where((id) => graph.nodes[id]!.isLayout)
        .toList(growable: false);
    final rootRouteIds = graph.rootIds
        .where((id) => graph.nodes[id]!.isRoute)
        .toList(growable: false);

    final standaloneGrid = _wrapGrid(rootRouteIds, subtreeMetrics);

    var maxTotalWidth = standaloneGrid.width;
    for (final layoutId in rootLayoutIds) {
      final w = subtreeMetrics[layoutId]!.width;
      if (w > maxTotalWidth) maxTotalWidth = w;
    }

    var currentTop = _padding;

    if (standaloneGrid.rows.isNotEmpty) {
      _placeGrid(
        standaloneGrid,
        subtreeMetrics,
        left: _padding + (maxTotalWidth - standaloneGrid.width) / 2,
        top: currentTop,
        placeChild: place,
      );
      currentTop += standaloneGrid.height + _verticalGap;
    }

    // 2. Các Layout -> layout dọc từ trên xuống dưới
    for (final layoutId in rootLayoutIds) {
      final m = subtreeMetrics[layoutId]!;
      final layoutLeft = _padding + (maxTotalWidth - m.width) / 2;
      place(layoutId, layoutLeft, currentTop);
      currentTop += m.height + _verticalGap;
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
