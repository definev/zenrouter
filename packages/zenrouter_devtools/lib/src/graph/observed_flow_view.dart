import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../widgets/debug_theme.dart';
import 'navigation_flow.dart';
import 'navigation_graph.dart';

class ObservedNavigationFlowView extends StatefulWidget {
  const ObservedNavigationFlowView({
    super.key,
    required this.graph,
    required this.flow,
    required this.onClear,
  });

  final NavigationGraph<Object> graph;
  final NavigationFlowRecorder<Object> flow;
  final VoidCallback onClear;

  @override
  State<ObservedNavigationFlowView> createState() =>
      _ObservedNavigationFlowViewState();
}

class _ObservedNavigationFlowViewState
    extends State<ObservedNavigationFlowView> {
  final TransformationController _transformationController =
      TransformationController();
  Object? _selectedNodeId;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value =
        _transformationController.value.clone()..setIdentity();
  }

  void _clearFlow() {
    setState(() => _selectedNodeId = null);
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    final currentId = widget.graph.activeRouteId;
    final inspectedId = _selectedNodeId ?? currentId;
    final inspectedNode =
        inspectedId == null ? null : widget.graph.nodes[inspectedId];
    final layout = _ObservedFlowLayout.calculate(widget.graph, widget.flow);

    return Column(
      children: [
        _FlowHeader(
          flow: widget.flow,
          inspectedNode: inspectedNode,
          isSelected: _selectedNodeId != null,
          onReset: _resetView,
          onClear: _clearFlow,
        ),
        Expanded(
          child:
              widget.flow.edges.isEmpty
                  ? const _EmptyObservedFlow()
                  : ClipRect(
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
                                painter: _ObservedFlowEdgePainter(layout.edges),
                              ),
                            ),
                            for (final edge in layout.edges)
                              Positioned(
                                left: edge.pointAt(0.5).dx - 60,
                                top: edge.pointAt(0.5).dy - 10,
                                width: 120,
                                height: 20,
                                child: _ObservedFlowEdgeLabel(
                                  label: edge.label,
                                ),
                              ),
                            for (final placedNode in layout.nodes)
                              Positioned(
                                left: placedNode.rect.left,
                                top: placedNode.rect.top,
                                width: placedNode.rect.width,
                                height: placedNode.rect.height,
                                child: _ObservedFlowNodeCard(
                                  graphNode: placedNode.graphNode,
                                  flowNode: placedNode.flowNode,
                                  isCurrent:
                                      currentId == placedNode.graphNode.id,
                                  isSelected:
                                      _selectedNodeId ==
                                      placedNode.graphNode.id,
                                  onTap:
                                      () => setState(() {
                                        _selectedNodeId =
                                            placedNode.graphNode.id;
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

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({
    required this.flow,
    required this.inspectedNode,
    required this.isSelected,
    required this.onReset,
    required this.onClear,
  });

  final NavigationFlowRecorder<Object> flow;
  final NavigationGraphNode<Object>? inspectedNode;
  final bool isSelected;
  final VoidCallback onReset;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final node = inspectedNode;
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
                    color:
                        isSelected
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
            icon: CupertinoIcons.arrow_counterclockwise,
            onTap: onReset,
          ),
          _HeaderAction(icon: CupertinoIcons.trash, onTap: onClear),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 32,
        child: Icon(icon, size: 14, color: DebugTheme.textSecondary),
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
    required this.graphNode,
    required this.flowNode,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isCurrent
            ? _ObservedFlowColors.active
            : isSelected
            ? _ObservedFlowColors.selected
            : DebugTheme.border;
    final background =
        isCurrent
            ? _ObservedFlowColors.activeBackground
            : isSelected
            ? _ObservedFlowColors.selectedBackground
            : DebugTheme.backgroundLight;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${graphNode.label}, visited ${flowNode.visitCount} times',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DebugTheme.spacing),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(DebugTheme.radius),
            border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
          ),
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
              const Spacer(),
              Text(
                flowNode.lastUri.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DebugTheme.textSecondary,
                  fontSize: DebugTheme.fontSizeSm,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'VISITED ${flowNode.visitCount}',
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
      ),
    );
  }
}

class _ObservedFlowEdgeLabel extends StatelessWidget {
  const _ObservedFlowEdgeLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: DebugTheme.backgroundDark,
            borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DebugTheme.textPrimary,
              fontSize: 8,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

final class _ObservedFlowLayout {
  const _ObservedFlowLayout({
    required this.nodes,
    required this.edges,
    required this.size,
  });

  static const _nodeWidth = 160.0;
  static const _nodeHeight = 72.0;
  static const _horizontalGap = 82.0;
  static const _verticalGap = 38.0;
  static const _padding = 52.0;

  factory _ObservedFlowLayout.calculate(
    NavigationGraph<Object> graph,
    NavigationFlowRecorder<Object> flow,
  ) {
    final depths = <Object, int>{};
    final entryId = flow.entryNodeId;
    if (entryId != null) depths[entryId] = 0;
    for (final edge in flow.edges) {
      depths.putIfAbsent(edge.fromId, () => 0);
      depths.putIfAbsent(edge.toId, () => (depths[edge.fromId] ?? 0) + 1);
    }

    final orderedFlowNodes = flow.nodes.values.toList(growable: false)..sort(
      (left, right) =>
          left.firstSeenRevision.compareTo(right.firstSeenRevision),
    );
    final columns = <int, List<NavigationFlowNode<Object>>>{};
    for (final node in orderedFlowNodes) {
      columns.putIfAbsent(depths[node.id] ?? 0, () => []).add(node);
    }

    final centers = <Object, Offset>{};
    final placedNodes = <_PlacedObservedFlowNode>[];
    var maxDepth = 0;
    var maxRows = 1;
    for (final entry in columns.entries) {
      maxDepth = math.max(maxDepth, entry.key);
      maxRows = math.max(maxRows, entry.value.length);
      for (var row = 0; row < entry.value.length; row += 1) {
        final flowNode = entry.value[row];
        final graphNode = graph.nodes[flowNode.id];
        if (graphNode == null) continue;
        final center = Offset(
          _padding + _nodeWidth / 2 + entry.key * (_nodeWidth + _horizontalGap),
          _padding + _nodeHeight / 2 + row * (_nodeHeight + _verticalGap),
        );
        centers[flowNode.id] = center;
        placedNodes.add(
          _PlacedObservedFlowNode(
            graphNode: graphNode,
            flowNode: flowNode,
            rect: Rect.fromCenter(
              center: center,
              width: _nodeWidth,
              height: _nodeHeight,
            ),
          ),
        );
      }
    }

    final placedEdges = <_PlacedObservedFlowEdge>[];
    for (final edge in flow.edges) {
      final from = centers[edge.fromId];
      final to = centers[edge.toId];
      if (from == null || to == null) continue;
      placedEdges.add(
        _PlacedObservedFlowEdge.fromCenters(
          from: from,
          to: to,
          nodeWidth: _nodeWidth,
          nodeHeight: _nodeHeight,
          label: '${edge.displayLabel} ×${edge.count}',
          isSelf: edge.fromId == edge.toId,
        ),
      );
    }

    return _ObservedFlowLayout(
      nodes: List.unmodifiable(placedNodes),
      edges: List.unmodifiable(placedEdges),
      size: Size(
        math.max(
          230,
          _padding * 2 +
              (maxDepth + 1) * _nodeWidth +
              maxDepth * _horizontalGap,
        ),
        math.max(
          220,
          _padding * 2 + maxRows * _nodeHeight + (maxRows - 1) * _verticalGap,
        ),
      ),
    );
  }

  final List<_PlacedObservedFlowNode> nodes;
  final List<_PlacedObservedFlowEdge> edges;
  final Size size;
}

final class _PlacedObservedFlowNode {
  const _PlacedObservedFlowNode({
    required this.graphNode,
    required this.flowNode,
    required this.rect,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final Rect rect;
}

final class _PlacedObservedFlowEdge {
  const _PlacedObservedFlowEdge({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
    required this.label,
  });

  factory _PlacedObservedFlowEdge.fromCenters({
    required Offset from,
    required Offset to,
    required double nodeWidth,
    required double nodeHeight,
    required String label,
    required bool isSelf,
  }) {
    if (isSelf) {
      final start = Offset(from.dx - 20, from.dy - nodeHeight / 2);
      final end = Offset(from.dx + 20, from.dy - nodeHeight / 2);
      return _PlacedObservedFlowEdge(
        start: start,
        control1: Offset(start.dx - 18, start.dy - 42),
        control2: Offset(end.dx + 18, end.dy - 42),
        end: end,
        label: label,
      );
    }

    if ((from.dx - to.dx).abs() < 1) {
      final start = Offset(from.dx + nodeWidth / 2, from.dy);
      final end = Offset(to.dx + nodeWidth / 2, to.dy);
      final bowX = math.max(start.dx, end.dx) + 46;
      return _PlacedObservedFlowEdge(
        start: start,
        control1: Offset(bowX, start.dy),
        control2: Offset(bowX, end.dy),
        end: end,
        label: label,
      );
    }

    final movesForward = to.dx > from.dx;
    final start = Offset(
      from.dx + (movesForward ? nodeWidth / 2 : -nodeWidth / 2),
      from.dy,
    );
    final end = Offset(
      to.dx + (movesForward ? -nodeWidth / 2 : nodeWidth / 2),
      to.dy,
    );
    final controlOffset = (end.dx - start.dx) * 0.5;
    return _PlacedObservedFlowEdge(
      start: start,
      control1: Offset(start.dx + controlOffset, start.dy),
      control2: Offset(end.dx - controlOffset, end.dy),
      end: end,
      label: label,
    );
  }

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;
  final String label;

  Offset pointAt(double t) {
    final inverse = 1 - t;
    return start * (inverse * inverse * inverse) +
        control1 * (3 * inverse * inverse * t) +
        control2 * (3 * inverse * t * t) +
        end * (t * t * t);
  }
}

class _ObservedFlowEdgePainter extends CustomPainter {
  const _ObservedFlowEdgePainter(this.edges);

  final List<_PlacedObservedFlowEdge> edges;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final path =
          Path()
            ..moveTo(edge.start.dx, edge.start.dy)
            ..cubicTo(
              edge.control1.dx,
              edge.control1.dy,
              edge.control2.dx,
              edge.control2.dy,
              edge.end.dx,
              edge.end.dy,
            );
      final paint =
          Paint()
            ..color = _ObservedFlowColors.edge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
      canvas.drawPath(path, paint);

      final tangent = edge.end - edge.control2;
      final angle = math.atan2(tangent.dy, tangent.dx);
      const arrowSize = 6.0;
      final arrow =
          Path()
            ..moveTo(edge.end.dx, edge.end.dy)
            ..lineTo(
              edge.end.dx - arrowSize * math.cos(angle - math.pi / 6),
              edge.end.dy - arrowSize * math.sin(angle - math.pi / 6),
            )
            ..lineTo(
              edge.end.dx - arrowSize * math.cos(angle + math.pi / 6),
              edge.end.dy - arrowSize * math.sin(angle + math.pi / 6),
            )
            ..close();
      canvas.drawPath(
        arrow,
        Paint()
          ..color = _ObservedFlowColors.edge
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ObservedFlowEdgePainter oldDelegate) =>
      oldDelegate.edges != edges;
}

abstract final class _ObservedFlowColors {
  static const active = Color(0xFF34D399);
  static const activeBackground = Color(0xFF0C2E25);
  static const selected = Color(0xFF60A5FA);
  static const selectedBackground = Color(0xFF112A46);
  static const edge = Color(0xFFA78BFA);
}
