import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraph<Object> graph;
  final NavigationFlowRecorder<Object> flow;
  final bool captureEnabled;
  final ValueChanged<bool> onCaptureChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onNavigate;
  final ValueChanged<String>? onCopy;

  @override
  State<ObservedNavigationFlowView> createState() =>
      _ObservedNavigationFlowViewState();
}

class _ObservedNavigationFlowViewState
    extends State<ObservedNavigationFlowView> {
  late final NodeFlowController<_ObservedNodeData, Object?> _controller;
  late _ObservedNodeFlowModel _model;
  Object? _selectedNodeId;
  Object? _zoomedNodeId;
  bool _showEdgeLabels = true;

  @override
  void initState() {
    super.initState();
    _model = _ObservedNodeFlowModel.calculate(
      widget.graph,
      widget.flow,
      showLabels: _showEdgeLabels,
    );
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
      showLabels: _showEdgeLabels,
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

  void _toggleEdgeLabels() {
    setState(() {
      _showEdgeLabels = !_showEdgeLabels;
      final selectedNodeIds = <Object>{
        for (final node in _controller.nodes.values)
          if (_controller.isNodeSelected(node.id)) node.data.id,
      };
      _model = _ObservedNodeFlowModel.calculate(
        widget.graph,
        widget.flow,
        previousPositions: {
          for (final node in _controller.nodes.values)
            node.data.id: node.position.value,
        },
        showLabels: _showEdgeLabels,
      );
      _controller.loadGraph(
        NodeGraph<_ObservedNodeData, Object?>(
          nodes: _model.nodes,
          connections: _model.connections,
          viewport: _controller.viewport,
        ),
      );
      _restoreSelection(selectedNodeIds);
    });
  }

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
    setState(() {
      _selectedNodeId = null;
      _zoomedNodeId = null;
    });
    widget.onClear();
  }

  void _openZoomModal(Object nodeId) {
    setState(() {
      _zoomedNodeId = nodeId;
    });
  }

  void _closeZoomModal() {
    setState(() {
      _zoomedNodeId = null;
    });
  }

  void _autoLayout() {
    final selectedNodeIds = <Object>{
      for (final node in _controller.nodes.values)
        if (_controller.isNodeSelected(node.id)) node.data.id,
    };
    _model = _ObservedNodeFlowModel.calculate(
      widget.graph,
      widget.flow,
      showLabels: _showEdgeLabels,
    );
    _controller.loadGraph(
      NodeGraph<_ObservedNodeData, Object?>(
        nodes: _model.nodes,
        connections: _model.connections,
        viewport: _controller.viewport,
      ),
    );
    _restoreSelection(selectedNodeIds);
    _controller.fitToView();
  }

  @override
  Widget build(BuildContext context) {
    final currentId = widget.graph.activeRouteId;
    final inspectedId = _selectedNodeId ?? currentId;
    final inspectedNode = inspectedId == null
        ? null
        : widget.graph.nodes[inspectedId];

    final zoomedId = _zoomedNodeId;
    final zoomedGraphNode =
        zoomedId == null ? null : widget.graph.nodes[zoomedId];
    final zoomedFlowNode =
        zoomedId == null ? null : widget.flow.nodes[zoomedId];

    return Stack(
      children: [
        Column(
          children: [
            _FlowHeader(
              flow: widget.flow,
              inspectedNode: inspectedNode,
              isSelected: _selectedNodeId != null,
              captureEnabled: widget.captureEnabled,
              showLabels: _showEdgeLabels,
              onCaptureChanged: widget.onCaptureChanged,
              onToggleLabels: _toggleEdgeLabels,
              onAutoLayout: _autoLayout,
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
                            onDoubleTap: (node) => _openZoomModal(node.data.id),
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
                            onZoom: () => _openZoomModal(id),
                            onNavigate: widget.onNavigate != null
                                ? () => widget.onNavigate!(
                                    flowNode.lastUri.toString(),
                                  )
                                : null,
                            onCopy: widget.onCopy != null
                                ? () => widget.onCopy!(
                                    flowNode.lastUri.toString(),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        if (zoomedGraphNode != null && zoomedFlowNode != null)
          Positioned.fill(
            child: _ObservedScreenPreviewZoomModal(
              graphNode: zoomedGraphNode,
              flowNode: zoomedFlowNode,
              captureEnabled: widget.captureEnabled,
              onClose: _closeZoomModal,
              onNavigate: widget.onNavigate != null
                  ? () {
                      _closeZoomModal();
                      widget.onNavigate!(zoomedFlowNode.lastUri.toString());
                    }
                  : null,
              onCopy: widget.onCopy != null
                  ? () {
                      widget.onCopy!(zoomedFlowNode.lastUri.toString());
                    }
                  : null,
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
    required this.showLabels,
    required this.onCaptureChanged,
    required this.onToggleLabels,
    required this.onAutoLayout,
    required this.onReset,
    required this.onClear,
  });

  final NavigationFlowRecorder<Object> flow;
  final NavigationGraphNode<Object>? inspectedNode;
  final bool isSelected;
  final bool captureEnabled;
  final bool showLabels;
  final ValueChanged<bool> onCaptureChanged;
  final VoidCallback onToggleLabels;
  final VoidCallback onAutoLayout;
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
            key: const ValueKey('observed-toggle-labels'),
            semanticsLabel: showLabels
                ? 'Hide connection labels'
                : 'Show connection labels',
            icon: showLabels
                ? CupertinoIcons.tag_fill
                : CupertinoIcons.tag,
            color: showLabels
                ? _ObservedFlowColors.selected
                : DebugTheme.textSecondary,
            onTap: onToggleLabels,
          ),
          _HeaderAction(
            key: const ValueKey('observed-auto-layout'),
            semanticsLabel: 'Auto layout observed flow',
            icon: CupertinoIcons.sparkles,
            color: _ObservedFlowColors.selected,
            onTap: onAutoLayout,
          ),
          _HeaderAction(
            key: const ValueKey('observed-reset-view'),
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
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: 28,
            height: 32,
            child: Icon(icon, size: 13.5, color: color),
          ),
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
    required this.onZoom,
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final bool isCurrent;
  final bool isSelected;
  final bool captureEnabled;
  final VoidCallback onZoom;
  final VoidCallback? onNavigate;
  final VoidCallback? onCopy;

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
        borderRadius: BorderRadius.circular(DebugTheme.radiusMd - 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onZoom,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ObservedScreenPreview(
                      key: ValueKey('observed-screen-preview-${graphNode.id}'),
                      preview: flowNode.screenPreview,
                      captureEnabled: captureEnabled,
                    ),
                    if (isCurrent)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _ObservedFlowColors.activeBackground,
                            borderRadius: BorderRadius.circular(
                              DebugTheme.radiusFull,
                            ),
                            border: Border.all(
                              color: _ObservedFlowColors.active.withValues(
                                alpha: 0.85,
                              ),
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
                                  color: _ObservedFlowColors.active,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: _ObservedFlowColors.active,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onZoom,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xCC000000),
                              borderRadius: BorderRadius.circular(
                                DebugTheme.radiusSm,
                              ),
                              border: Border.all(
                                color: DebugTheme.borderDark,
                                width: 0.6,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.viewfinder,
                              size: 11,
                              color: _ObservedFlowColors.selected,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              decoration: const BoxDecoration(
                color: DebugTheme.backgroundDark,
                border: Border(
                  top: BorderSide(color: DebugTheme.borderDark),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.rectangle_stack_fill,
                        color: borderColor,
                        size: 11,
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
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _ObservedFlowColors.edge.withValues(
                            alpha: 0.14,
                          ),
                          borderRadius: BorderRadius.circular(
                            DebugTheme.radiusSm,
                          ),
                          border: Border.all(
                            color: _ObservedFlowColors.edge.withValues(
                              alpha: 0.3,
                            ),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          '×${flowNode.visitCount}',
                          style: const TextStyle(
                            color: _ObservedFlowColors.edge,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
                          ),
                        ),
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
                            fontSize: 8.5,
                            fontFamily: 'monospace',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onZoom,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              CupertinoIcons.viewfinder,
                              size: 11,
                              color: _ObservedFlowColors.selected,
                            ),
                          ),
                        ),
                      ),
                      if (onNavigate != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onNavigate,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                CupertinoIcons.compass,
                                size: 11,
                                color: DebugTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (onCopy != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onCopy,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                CupertinoIcons.doc_on_doc,
                                size: 11,
                                color: DebugTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
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
            fit: BoxFit.contain,
            alignment: Alignment.center,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (_, _, _) => _buildPlaceholder(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x04000000), Color(0x66000000)],
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
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            captureEnabled ? 'WAITING FOR PREVIEW' : 'SCREEN CAPTURE OFF',
            style: const TextStyle(
              color: DebugTheme.textMuted,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ObservedScreenPreviewZoomModal extends StatelessWidget {
  const _ObservedScreenPreviewZoomModal({
    required this.graphNode,
    required this.flowNode,
    required this.captureEnabled,
    required this.onClose,
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final bool captureEnabled;
  final VoidCallback onClose;
  final VoidCallback? onNavigate;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final preview = flowNode.screenPreview;
    final capturedTime = preview != null
        ? '${preview.capturedAt.toLocal().hour.toString().padLeft(2, '0')}:${preview.capturedAt.toLocal().minute.toString().padLeft(2, '0')}:${preview.capturedAt.toLocal().second.toString().padLeft(2, '0')}'
        : null;

    final mediaSize = MediaQuery.sizeOf(context);
    final previewAspect = preview?.aspectRatio ?? (9.0 / 16.0);
    final modalWidth = previewAspect >= 1.0
        ? math.min(mediaSize.width * 0.85, 480.0)
        : math.min(mediaSize.width * 0.85, 340.0);

    return Stack(
      children: [
        // Backdrop scrim
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Container(
              color: const Color(0xB3000000),
            ),
          ),
        ),
        // Modal Container
        Center(
          child: Container(
            width: modalWidth,
            constraints: BoxConstraints(
              maxHeight: mediaSize.height * 0.85,
            ),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DebugTheme.backgroundDark,
              borderRadius: BorderRadius.circular(DebugTheme.radiusLg),
              border: Border.all(color: DebugTheme.border, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xCC000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DebugTheme.radiusLg - 1.2),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: DebugTheme.background,
                        border: Border(
                          bottom: BorderSide(color: DebugTheme.borderDark),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.rectangle_stack_fill,
                            color: _ObservedFlowColors.selected,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  graphNode.label,
                                  style: const TextStyle(
                                    color: DebugTheme.textPrimary,
                                    fontSize: DebugTheme.fontSizeMd,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  flowNode.lastUri.toString(),
                                  style: const TextStyle(
                                    color: DebugTheme.textSecondary,
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onClose,
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: DebugTheme.textMuted,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        color: DebugTheme.background,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DebugTheme.radiusMd,
                          ),
                          child: preview != null
                              ? Image.memory(
                                  preview.bytes,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                )
                              : Container(
                                  height: 180,
                                  color: DebugTheme.backgroundDark,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'No Preview Available',
                                    style: TextStyle(
                                      color: DebugTheme.textDisabled,
                                      fontSize: DebugTheme.fontSizeSm,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: DebugTheme.backgroundLight,
                        border: Border(
                          top: BorderSide(color: DebugTheme.borderDark),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Visited ${flowNode.visitCount} times',
                                style: const TextStyle(
                                  color: DebugTheme.textSecondary,
                                  fontSize: 9,
                                ),
                              ),
                              if (capturedTime != null)
                                Text(
                                  'Captured at $capturedTime',
                                  style: const TextStyle(
                                    color: DebugTheme.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (onNavigate != null)
                                Expanded(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    color: _ObservedFlowColors.active,
                                    borderRadius: BorderRadius.circular(
                                      DebugTheme.radiusSm,
                                    ),
                                    onPressed: onNavigate,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.compass,
                                          size: 13,
                                          color: Color(0xFF0C2E25),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Navigate Here',
                                          style: TextStyle(
                                            color: Color(0xFF0C2E25),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (onCopy != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    color: DebugTheme.backgroundDark,
                                    borderRadius: BorderRadius.circular(
                                      DebugTheme.radiusSm,
                                    ),
                                    onPressed: onCopy,
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.doc_on_doc,
                                          size: 12,
                                          color: DebugTheme.textPrimary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Copy URI',
                                          style: TextStyle(
                                            color: DebugTheme.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            constraints: const BoxConstraints(minHeight: 16),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xEE0F172A),
              borderRadius: BorderRadius.circular(DebugTheme.radiusFull),
              border: Border.all(
                color: _ObservedFlowColors.edge.withValues(alpha: 0.45),
                width: 0.6,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DebugTheme.textPrimary,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                decoration: TextDecoration.none,
              ),
            ),
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

  factory _ObservedNodeFlowModel.calculate(
    NavigationGraph<Object> graph,
    NavigationFlowRecorder<Object> flow, {
    Map<Object, Offset> previousPositions = const {},
    bool showLabels = true,
  }) {
    // 1. Detect dominant aspect ratio from captured previews
    double? detectedAspectRatio;
    for (final node in flow.nodes.values) {
      final preview = node.screenPreview;
      if (preview?.aspectRatio != null) {
        detectedAspectRatio = preview!.aspectRatio;
        break;
      }
    }
    // Default to mobile portrait (9:16 = 0.5625)
    final aspectRatio = (detectedAspectRatio ?? (9.0 / 16.0)).clamp(0.35, 2.5);
    final isLandscape = aspectRatio >= 1.0;

    final double nodeWidth;
    final double previewHeight;
    const footerHeight = 56.0;

    if (isLandscape) {
      nodeWidth = 200.0;
      previewHeight = (nodeWidth / aspectRatio).clamp(110.0, 160.0);
    } else {
      // Mobile Portrait: standard phone mockup ratio
      nodeWidth = 142.0;
      previewHeight = (nodeWidth / aspectRatio).clamp(200.0, 280.0);
    }

    final nodeHeight = previewHeight + footerHeight;
    final nodeSize = Size(nodeWidth, nodeHeight);
    final horizontalGap = isLandscape ? 96.0 : 84.0;
    final verticalGap = isLandscape ? 36.0 : 28.0;
    const padding = 28.0;

    // 2. Build Storyboard Discovery Tree (Hierarchical User Journey)
    final discoveryChildren = <Object, List<Object>>{};
    final discoveryParent = <Object, Object?>{};
    final treeRoots = <Object>[];

    for (final node in flow.nodes.values) {
      discoveryChildren[node.id] = [];
    }

    final entryId = flow.entryNodeId;
    if (entryId != null && flow.nodes.containsKey(entryId)) {
      treeRoots.add(entryId);
    }

    // Xây dựng cây khám phá dựa trên lần đầu tiên một màn hình được mở
    for (final transition in flow.transitions) {
      final fromId = transition.fromId;
      final toId = transition.toId;
      if (fromId != toId &&
          flow.nodes.containsKey(fromId) &&
          flow.nodes.containsKey(toId)) {
        if (!discoveryParent.containsKey(toId) && toId != entryId) {
          discoveryParent[toId] = fromId;
          discoveryChildren[fromId]?.add(toId);
        }
      }
    }

    // Bất kỳ node nào chưa có cha trong cây sẽ trở thành Root
    for (final node in flow.nodes.values) {
      if (node.id != entryId && !discoveryParent.containsKey(node.id)) {
        treeRoots.add(node.id);
      }
    }

    // Sắp xếp các nhánh theo thứ tự thời gian xuất hiện
    treeRoots.sort(
      (a, b) => flow.nodes[a]!.firstSeenRevision.compareTo(
        flow.nodes[b]!.firstSeenRevision,
      ),
    );
    for (final children in discoveryChildren.values) {
      children.sort(
        (a, b) => flow.nodes[a]!.firstSeenRevision.compareTo(
          flow.nodes[b]!.firstSeenRevision,
        ),
      );
    }

    // 3. Đo đạc chiều cao phân nhánh đệ quy (Recursive Subtree Height)
    final subtreeHeights = <Object, double>{};
    double measureTree(Object u) {
      final children = discoveryChildren[u] ?? const [];
      if (children.isEmpty) {
        subtreeHeights[u] = nodeHeight;
        return nodeHeight;
      }
      var totalChildHeight = 0.0;
      for (final c in children) {
        totalChildHeight += measureTree(c);
      }
      totalChildHeight += verticalGap * (children.length - 1);
      final h = math.max(nodeHeight, totalChildHeight);
      subtreeHeights[u] = h;
      return h;
    }

    for (final rootId in treeRoots) {
      measureTree(rootId);
    }

    // 4. Định vị các Node theo Storyboard Flow (Trái sang Phải)
    final positions = <Object, Offset>{};
    void placeTree(Object u, double left, double top) {
      final h = subtreeHeights[u]!;
      final y = top + (h - nodeHeight) / 2;
      positions[u] = Offset(left, y);

      final children = discoveryChildren[u] ?? const [];
      if (children.isEmpty) return;

      final childLeft = left + nodeWidth + horizontalGap;
      var childTop = top;
      for (final c in children) {
        placeTree(c, childLeft, childTop);
        childTop += subtreeHeights[c]! + verticalGap;
      }
    }

    var currentRootTop = padding;
    for (final rootId in treeRoots) {
      placeTree(rootId, padding, currentRootTop);
      currentRootTop += subtreeHeights[rootId]! + verticalGap;
    }

    final orderedFlowNodes = flow.nodes.values.toList(growable: false)
      ..sort(
        (left, right) =>
            left.firstSeenRevision.compareTo(right.firstSeenRevision),
      );

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
          size: nodeSize,
          data: _ObservedNodeData(flowNode.id),
          ports: createObservedNodeFlowPorts(nodeSize),
          theme: _observedNodeFlowTheme.nodeTheme.copyWith(
            backgroundColor: isCurrent
                ? _ObservedFlowColors.activeBackground
                : DebugTheme.backgroundLight,
            borderColor: isCurrent
                ? _ObservedFlowColors.active
                : DebugTheme.border,
            borderWidth: isCurrent ? 1.5 : 1,
            borderRadius: BorderRadius.circular(DebugTheme.radiusMd),
          ),
        ),
      );
    }

    final laneUsage = <String, int>{};
    final connections = <Connection<Object?>>[];
    var connectionIndex = 0;
    for (final edge in flow.edges) {
      final sourceId = flowIds[edge.fromId];
      final targetId = flowIds[edge.toId];
      if (sourceId == null || targetId == null) continue;

      final fromPos = positions[edge.fromId];
      final toPos = positions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      final isForward = toPos.dx > fromPos.dx;
      final isEdgeActive = graph.activeRouteId == edge.toId;
      final edgeColor = isEdgeActive
          ? _ObservedFlowColors.active
          : _ObservedFlowColors.edge;

      // Cạnh tiến: Xuất cổng Right -> Nhập cổng Left
      // Cạnh lùi (Back): Xuất cổng Bottom -> Nhập cổng Top
      final sourcePortId = isForward
          ? nodeFlowOutputPortId
          : nodeFlowReturnOutPortId;
      final targetPortId = isForward
          ? nodeFlowInputPortId
          : nodeFlowReturnInPortId;

      // Tính toán vị trí nhãn so le (Staggered Label Positioning) để chống đè chữ
      final fromStr = edge.fromId.toString();
      final toStr = edge.toId.toString();
      final laneKey = fromStr.compareTo(toStr) < 0
          ? '$fromStr-$toStr'
          : '$toStr-$fromStr';
      final laneIndex = laneUsage[laneKey] ?? 0;
      laneUsage[laneKey] = laneIndex + 1;

      // Tính anchor (vị trí dọc theo đường nối) và offset (độ lệch vuông góc)
      final double anchor;
      final double offset;
      if (isForward) {
        // Cạnh tiến: so le 36% và lệch lên trên
        anchor = laneIndex == 0
            ? 0.36
            : (0.32 + (laneIndex % 3) * 0.16).clamp(0.2, 0.8);
        offset = laneIndex.isEven ? -10.0 : -18.0;
      } else {
        // Cạnh lùi: so le 64% và lệch xuống dưới
        anchor = laneIndex == 0
            ? 0.64
            : (0.68 - (laneIndex % 3) * 0.16).clamp(0.2, 0.8);
        offset = laneIndex.isEven ? 10.0 : 18.0;
      }

      connections.add(
        Connection<Object?>(
          id: 'observed-edge-${connectionIndex++}',
          sourceNodeId: sourceId,
          sourcePortId: sourcePortId,
          targetNodeId: targetId,
          targetPortId: targetPortId,
          label: showLabels
              ? ConnectionLabel(
                  text: '${edge.displayLabel} ×${edge.count}',
                  anchor: anchor,
                  offset: offset,
                )
              : null,
          color: isForward ? edgeColor : edgeColor.withValues(alpha: 0.7),
          selectedColor: _ObservedFlowColors.selected,
          strokeWidth: isEdgeActive ? 2.2 : (isForward ? 1.8 : 1.4),
          selectedStrokeWidth: 2.4,
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
        nodeSize,
        showLabels,
        for (final node in orderedFlowNodes) ...[
          node.id,
          node.firstSeenRevision,
          node.screenPreview?.width,
          node.screenPreview?.height,
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
