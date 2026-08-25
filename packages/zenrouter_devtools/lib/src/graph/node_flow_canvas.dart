import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' hide DebugTheme;

import '../widgets/debug_theme.dart';

const nodeFlowInputPortId = 'input';
const nodeFlowOutputPortId = 'output';
const nodeFlowReturnOutPortId = 'return-out';
const nodeFlowReturnInPortId = 'return-in';

class NavigationNodeFlowAutoFit extends StatefulWidget {
  const NavigationNodeFlowAutoFit({
    super.key,
    required this.onFit,
    required this.child,
  });

  final VoidCallback onFit;
  final Widget child;

  @override
  State<NavigationNodeFlowAutoFit> createState() =>
      _NavigationNodeFlowAutoFitState();
}

class _NavigationNodeFlowAutoFitState extends State<NavigationNodeFlowAutoFit> {
  static const _settleDelay = Duration(milliseconds: 120);
  static const _fitDelta = 32.0;

  Size? _layoutSize;
  Size? _frozenSize;
  Size? _pendingSize;
  Timer? _commitTimer;
  bool _fitScheduled = false;

  @override
  void dispose() {
    _commitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.isFinite || size.isEmpty) {
          return widget.child;
        }
        _observeSize(size);
        final childSize = _frozenSize ?? size;
        return FittedBox(
          fit: BoxFit.fill,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: childSize.width,
            height: childSize.height,
            child: widget.child,
          ),
        );
      },
    );
  }

  void _observeSize(Size size) {
    final layoutSize = _layoutSize;
    if (layoutSize == null) {
      _layoutSize = size;
      return;
    }
    if (size == layoutSize) {
      return;
    }
    _frozenSize ??= layoutSize;
    if (_pendingSize == size) {
      return;
    }
    _pendingSize = size;
    _commitTimer?.cancel();
    _commitTimer = Timer(_settleDelay, _commitSize);
  }

  void _commitSize() {
    if (!mounted) return;
    final previousSize = _layoutSize;
    final nextSize = _pendingSize ?? previousSize;
    setState(() {
      _layoutSize = nextSize;
      _frozenSize = null;
      _pendingSize = null;
    });
    if (previousSize != null &&
        nextSize != null &&
        ((nextSize.width - previousSize.width).abs() >= _fitDelta ||
            (nextSize.height - previousSize.height).abs() >= _fitDelta)) {
      _scheduleFit();
    }
  }

  void _scheduleFit() {
    if (_fitScheduled) return;
    _fitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitScheduled = false;
      if (mounted) widget.onFit();
    });
  }
}

NodeFlowConfig createNavigationNodeFlowConfig({
  MinimapThumbnailBuilder? minimapThumbnailBuilder,
}) => NodeFlowConfig(
  minZoom: 0.45,
  maxZoom: 2.5,
  showAttribution: false,
  plugins: [
    MinimapPlugin(
      visible: true,
      interactive: true,
      position: MinimapPosition.bottomRight,
      size: const Size(96, 64),
      margin: 8,
      theme: MinimapTheme.dark.copyWith(
        backgroundColor: DebugTheme.backgroundDark,
        nodeColor: DebugTheme.textMuted,
        viewportColor: const Color(0xFF60A5FA),
        viewportFillOpacity: 0.08,
        viewportBorderOpacity: 0.7,
        borderColor: DebugTheme.border,
        borderRadius: DebugTheme.radiusMd,
        padding: const EdgeInsets.all(5),
        nodeBorderRadius: DebugTheme.radiusSm,
      ),
      thumbnailBuilder: minimapThumbnailBuilder,
    ),
  ],
);

NodeFlowTheme createNavigationNodeFlowTheme({
  required Color connectionColor,
  required Color selectedColor,
  required ConnectionEndPoint endPoint,
  Color? backgroundColor,
}) => NodeFlowTheme.dark.copyWith(
  backgroundColor: backgroundColor ?? DebugTheme.background,
  nodeTheme: NodeTheme.dark.copyWith(
    backgroundColor: DebugTheme.backgroundLight,
    selectedBackgroundColor: const Color(0xFF112A46),
    highlightBackgroundColor: DebugTheme.backgroundLight,
    borderColor: DebugTheme.border,
    selectedBorderColor: selectedColor,
    highlightBorderColor: selectedColor,
    borderWidth: 1,
    selectedBorderWidth: 1.5,
    borderRadius: BorderRadius.circular(DebugTheme.radiusMd),
  ),
  connectionTheme: ConnectionTheme.dark.copyWith(
    style: ConnectionStyles.bezier,
    color: connectionColor,
    selectedColor: selectedColor,
    highlightColor: selectedColor,
    highlightBorderColor: selectedColor,
    strokeWidth: 1.8,
    selectedStrokeWidth: 2.2,
    startPoint: ConnectionEndPoint.none,
    endPoint: endPoint,
    endpointColor: connectionColor,
    endpointBorderColor: connectionColor,
    endpointBorderWidth: 0,
    portExtension: 16,
    backEdgeGap: 38,
  ),
  portTheme: PortTheme.dark.copyWith(
    size: const Size(6, 6),
    color: connectionColor,
    connectedColor: connectionColor,
    highlightColor: selectedColor,
    highlightBorderColor: selectedColor,
    borderColor: backgroundColor ?? DebugTheme.background,
    borderWidth: 1,
  ),
  labelTheme: LabelTheme.dark.copyWith(
    textStyle: const TextStyle(
      color: DebugTheme.textPrimary,
      fontSize: 8.5,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    ),
    backgroundColor: DebugTheme.backgroundDark,
    border: const Border.fromBorderSide(
      BorderSide(color: DebugTheme.borderDark),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
    maxWidth: 130,
    maxLines: 1,
  ),
  gridTheme: GridTheme.dark.copyWith(
    color: DebugTheme.borderDark,
    size: 24,
    thickness: 0.8,
  ),
);

/// Canvas fill that stays opaque normally, or clears in see-through mode.
Color navigationNodeFlowBackgroundColor(BuildContext context) {
  return DebugPanelAppearance.seeThroughOf(context)
      ? const Color(0x00000000)
      : DebugTheme.background;
}

List<Port> createNavigationNodeFlowPorts(
  Size nodeSize, {
  bool includeInput = true,
  bool includeOutput = true,
  PortPosition inputPosition = PortPosition.top,
  PortPosition outputPosition = PortPosition.bottom,
}) => [
  if (includeInput)
    Port(
      id: nodeFlowInputPortId,
      name: 'Input',
      type: PortType.input,
      position: inputPosition,
      offset: switch (inputPosition) {
        PortPosition.top => Offset(nodeSize.width / 2, -2),
        PortPosition.bottom => Offset(nodeSize.width / 2, 2),
        PortPosition.left => Offset(-2, nodeSize.height / 2),
        PortPosition.right => Offset(2, nodeSize.height / 2),
      },
      multiConnections: true,
      isConnectable: false,
    ),
  if (includeOutput)
    Port(
      id: nodeFlowOutputPortId,
      name: 'Output',
      type: PortType.output,
      position: outputPosition,
      offset: switch (outputPosition) {
        PortPosition.top => Offset(nodeSize.width / 2, -2),
        PortPosition.bottom => Offset(nodeSize.width / 2, 2),
        PortPosition.left => Offset(-2, nodeSize.height / 2),
        PortPosition.right => Offset(2, nodeSize.height / 2),
      },
      multiConnections: true,
      isConnectable: false,
    ),
];

List<Port> createObservedNodeFlowPorts(Size nodeSize) => [
  ...createNavigationNodeFlowPorts(nodeSize),
  Port(
    id: nodeFlowReturnOutPortId,
    name: 'Return Out',
    type: PortType.output,
    position: PortPosition.right,
    offset: Offset(2, nodeSize.height / 2),
    multiConnections: true,
    isConnectable: false,
  ),
  Port(
    id: nodeFlowReturnInPortId,
    name: 'Return In',
    type: PortType.input,
    position: PortPosition.left,
    offset: Offset(-2, nodeSize.height / 2),
    multiConnections: true,
    isConnectable: false,
  ),
];
