import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart' hide DebugTheme;
import 'package:zenrouter/zenrouter.dart';

import '../widgets/debug_theme.dart';
import 'navigation_flow.dart';
import 'navigation_flow_player.dart';
import 'navigation_flow_session.dart';
import 'navigation_graph.dart';
import 'node_flow_canvas.dart';
import 'observed_replay_controls.dart';

enum _ObservedReplayMode { live, replayPaused, replayPlaying }

class ObservedNavigationFlowView extends StatefulWidget {
  const ObservedNavigationFlowView({
    super.key,
    required this.graph,
    required this.flow,
    required this.manifest,
    required this.acquireRecordingPause,
    required this.captureEnabled,
    required this.onCaptureChanged,
    required this.onClear,
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraph<Object> graph;
  final NavigationFlowRecorder<Object> flow;
  final RouteManifest<Object> manifest;
  final VoidCallback Function() acquireRecordingPause;
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
  static const _speeds = [0.5, 1.0, 2.0, 4.0];

  late final NodeFlowController<_ObservedNodeData, Object?> _controller;
  late _ObservedNodeFlowModel _model;
  Object? _selectedNodeId;
  Object? _zoomedNodeId;
  bool _isReadOnly = false;
  _ObservedReplayMode _mode = _ObservedReplayMode.live;
  NavigationFlowPlayer<Object>? _player;
  NavigationFlowRecorder<Object>? _hydrated;
  _ObservedNodeFlowModel? _frozenModel;
  Map<Object, NavigationFlowScreenPreview> _replayLatestPreviews = const {};
  bool _replayFromLiveExport = false;
  bool _importedUnmatched = false;
  double _speed = 1;
  VoidCallback _releaseRecordingPause = _noopRelease;

  static void _noopRelease() {}

  bool get _isLive => _mode == _ObservedReplayMode.live;

  NavigationFlowRecorder<Object> get _canvasFlow => _hydrated ?? widget.flow;

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
    _applyConnectionStyles();
  }

  @override
  void didUpdateWidget(ObservedNavigationFlowView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Live URI / recorder growth must not rebake the hydrated storyboard.
    if (!_isLive) return;
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
    _applyConnectionStyles();
  }

  @override
  void dispose() {
    _disposeReplaySession();
    _releaseRecordingPause();
    _controller.dispose();
    super.dispose();
  }

  void _resetView() => _controller.fitToView();

  void _setReadOnly(bool value) {
    setState(() {
      _isReadOnly = value;
      _controller.setBehavior(
        value ? NodeFlowBehavior.inspect : NodeFlowBehavior.preview,
      );
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
    final highlightId = _isLive ? widget.graph.activeRouteId : _player?.toId;
    final color = highlightId == data.id
        ? (_isLive ? _ObservedFlowColors.active : _ObservedFlowColors.selected)
        : defaultColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(DebugTheme.radiusSm)),
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
    if (!_isLive) {
      _exitReplay();
    }
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
    if (!_isLive) return;
    final selectedNodeIds = <Object>{
      for (final node in _controller.nodes.values)
        if (_controller.isNodeSelected(node.id)) node.data.id,
    };
    _model = _ObservedNodeFlowModel.calculate(widget.graph, widget.flow);
    _controller.loadGraph(
      NodeGraph<_ObservedNodeData, Object?>(
        nodes: _model.nodes,
        connections: _model.connections,
        viewport: _controller.viewport,
      ),
    );
    _restoreSelection(selectedNodeIds);
    _controller.fitToView();
    _applyConnectionStyles();
  }

  void _enterReplay({
    required NavigationFlowSession session,
    required int initialIndex,
    required bool play,
    required bool pauseLiveRecording,
  }) {
    _disposeReplaySession();
    _releaseRecordingPause();
    _releaseRecordingPause = _noopRelease;

    _hydrated = NavigationFlowRecorder.fromSession(widget.manifest, session);
    _replayLatestPreviews = pauseLiveRecording
        ? _copyLiveLatestPreviews()
        : const {};
    _player = NavigationFlowPlayer(
      transitions: _hydrated!.transitions,
      previewsByRevision: pauseLiveRecording
          ? _copyLivePreviewRefs()
          : const {},
      latestPreviewById: _replayLatestPreviews,
    );
    _player!.addListener(_onPlayerChanged);
    _player!.setSpeed(_speed);
    final previousPositions = <Object, Offset>{
      for (final node in _controller.nodes.values)
        node.data.id: node.position.value,
    };
    _frozenModel = _ObservedNodeFlowModel.calculate(
      widget.graph,
      _hydrated!,
      previousPositions: previousPositions,
    );
    _model = _frozenModel!;
    _replayFromLiveExport = pauseLiveRecording;
    _importedUnmatched =
        !pauseLiveRecording &&
        session.transitions.isNotEmpty &&
        _hydrated!.transitions.isEmpty;
    _mode = play
        ? _ObservedReplayMode.replayPlaying
        : _ObservedReplayMode.replayPaused;
    _controller.loadGraph(
      NodeGraph<_ObservedNodeData, Object?>(
        nodes: _model.nodes,
        connections: _model.connections,
        viewport: _controller.viewport,
      ),
    );
    if (pauseLiveRecording) {
      _releaseRecordingPause = widget.acquireRecordingPause();
    }
    if (_player!.length > 0) {
      _player!.seek(initialIndex);
      if (play) _player!.play();
    }
    _applyConnectionStyles();
    _centerOnPlayhead();
    setState(() {});
  }

  void _exitReplay() {
    _disposeReplaySession();
    _releaseRecordingPause();
    _releaseRecordingPause = _noopRelease;
    _mode = _ObservedReplayMode.live;
    _replayFromLiveExport = false;
    _importedUnmatched = false;
    if (!mounted) return;
    final previousPositions = <Object, Offset>{
      for (final node in _controller.nodes.values)
        node.data.id: node.position.value,
    };
    _model = _ObservedNodeFlowModel.calculate(
      widget.graph,
      widget.flow,
      previousPositions: previousPositions,
    );
    _controller.loadGraph(
      NodeGraph<_ObservedNodeData, Object?>(
        nodes: _model.nodes,
        connections: _model.connections,
        viewport: _controller.viewport,
      ),
    );
    _applyConnectionStyles();
    setState(() {});
  }

  void _disposeReplaySession() {
    _player?.removeListener(_onPlayerChanged);
    _player?.dispose();
    _player = null;
    _hydrated?.dispose();
    _hydrated = null;
    _frozenModel = null;
    _replayLatestPreviews = const {};
  }

  void _onPlayerChanged() {
    if (!mounted || _player == null) return;
    _mode = _player!.isPlaying
        ? _ObservedReplayMode.replayPlaying
        : _ObservedReplayMode.replayPaused;
    _applyConnectionStyles();
    _centerOnPlayhead();
    setState(() {});
  }

  void _centerOnPlayhead() {
    final toId = _player?.toId;
    if (toId == null) return;
    final flowId = _model.flowIds[toId];
    if (flowId == null) return;
    _controller.selectNode(flowId);
    _controller.centerOnNode(flowId);
  }

  void _applyConnectionStyles() {
    final routeByFlowId = <String, Object>{
      for (final entry in _model.flowIds.entries) entry.value: entry.key,
    };
    final playFrom = _isLive ? null : _player?.fromId;
    final playTo = _isLive ? null : _player?.toId;
    final liveActive = _isLive ? widget.graph.activeRouteId : null;
    for (final conn in _controller.connections) {
      final source = routeByFlowId[conn.sourceNodeId];
      final target = routeByFlowId[conn.targetNodeId];
      final isDownward = conn.sourcePortId == nodeFlowOutputPortId;
      final isReplayEdge =
          playFrom != null &&
          playTo != null &&
          ((source == playFrom && target == playTo) ||
              (source == playTo && target == playFrom));
      final isLiveEdge = liveActive != null && target == liveActive;
      if (isReplayEdge) {
        conn.color = _ObservedFlowColors.selected;
        conn.strokeWidth = 2.4;
      } else if (isLiveEdge) {
        final color = _ObservedFlowColors.active;
        conn.color = isDownward ? color : color.withValues(alpha: 0.7);
        conn.strokeWidth = 2.2;
      } else {
        final color = _ObservedFlowColors.edge;
        conn.color = isDownward ? color : color.withValues(alpha: 0.7);
        conn.strokeWidth = isDownward ? 1.8 : 1.4;
      }
    }
  }

  Map<int, NavigationFlowScreenPreview> _copyLivePreviewRefs() {
    final live = widget.flow;
    return {
      for (final transition in live.transitions)
        transition.revision: ?live.previewForRevision(transition.revision),
    };
  }

  Map<Object, NavigationFlowScreenPreview> _copyLiveLatestPreviews() {
    return {
      for (final node in widget.flow.nodes.values) node.id: ?node.screenPreview,
    };
  }

  void _playOrToggle() {
    if (_isLive) {
      _enterReplayFromLive(initialIndex: 0, play: true);
      return;
    }
    final player = _player;
    if (player == null) return;
    if (player.isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _stepBack() {
    if (_isLive) {
      final last = widget.flow.transitions.length - 1;
      if (last < 0) return;
      _enterReplayFromLive(initialIndex: last, play: false);
      return;
    }
    _player?.stepBack();
  }

  void _stepForward() {
    if (_isLive) {
      _enterReplayFromLive(initialIndex: 0, play: false);
      return;
    }
    _player?.stepForward();
  }

  void _jumpStart() {
    if (_isLive) {
      _enterReplayFromLive(initialIndex: 0, play: false);
      return;
    }
    _player?.seek(0);
  }

  void _jumpEnd() {
    if (_isLive) {
      final last = widget.flow.transitions.length - 1;
      if (last < 0) return;
      _enterReplayFromLive(initialIndex: last, play: false);
      return;
    }
    final player = _player;
    if (player == null || player.length == 0) return;
    player.seek(player.length - 1);
  }

  void _enterReplayFromLive({required int initialIndex, required bool play}) {
    if (widget.flow.transitions.isEmpty) return;
    _enterReplay(
      session: widget.flow.exportSession(),
      initialIndex: initialIndex,
      play: play,
      pauseLiveRecording: true,
    );
  }

  void _cycleSpeed() {
    final index = _speeds.indexOf(_speed);
    _speed = _speeds[(index + 1) % _speeds.length];
    _player?.setSpeed(_speed);
    setState(() {});
  }

  void _exportSession() {
    Clipboard.setData(
      ClipboardData(text: widget.flow.exportSession().encode()),
    );
  }

  Future<void> _importSession() async {
    final source = await showObservedSessionImportDialog(context);
    if (!mounted || source == null) return;
    try {
      final session = NavigationFlowSession.decode(source);
      _enterReplay(
        session: session,
        initialIndex: 0,
        play: false,
        pauseLiveRecording: false,
      );
    } on FormatException {
      // Invalid document stays on the current canvas.
    }
  }

  NavigationFlowScreenPreview? _previewFor(Object id) {
    if (!_isLive) {
      if (_player?.toId == id) return _player?.currentPreview;
      return _replayLatestPreviews[id];
    }
    return _canvasFlow.nodes[id]?.screenPreview;
  }

  String? get _replayBanner {
    if (_isLive) return null;
    if (_importedUnmatched) return observedReplayUnmatchedBanner;
    if (_replayFromLiveExport) return observedReplayLiveExportBanner;
    return observedReplayImportBanner;
  }

  String get _transitionLabel {
    if (_isLive) {
      return '${widget.flow.transitions.length} transitions';
    }
    final player = _player;
    if (player == null || player.length == 0) return 'REPLAY 0 / 0';
    final index = player.index < 0 ? 0 : player.index + 1;
    return 'REPLAY $index / ${player.length}';
  }

  @override
  Widget build(BuildContext context) {
    final canvasFlow = _canvasFlow;
    final currentId = widget.graph.activeRouteId;
    final playheadToId = _player?.toId;
    final playheadFromId = _player?.fromId;
    final inspectedId = _selectedNodeId ?? currentId;
    final inspectedNode = inspectedId == null
        ? null
        : widget.graph.nodes[inspectedId];

    final zoomedId = _zoomedNodeId;
    final zoomedGraphNode = zoomedId == null
        ? null
        : widget.graph.nodes[zoomedId];
    final zoomedFlowNode = zoomedId == null ? null : canvasFlow.nodes[zoomedId];
    final showTransport = !_isLive || widget.flow.transitions.isNotEmpty;

    return Stack(
      children: [
        Column(
          children: [
            _FlowHeader(
              flow: canvasFlow,
              transitionLabel: _transitionLabel,
              inspectedNode: inspectedNode,
              isSelected: _selectedNodeId != null,
              captureEnabled: widget.captureEnabled,
              onCaptureChanged: widget.onCaptureChanged,
              isReadOnly: _isReadOnly,
              onReadOnlyChanged: _setReadOnly,
              onAutoLayout: _isLive ? _autoLayout : null,
              onReset: _resetView,
              onClear: _clearFlow,
            ),
            if (showTransport)
              ObservedReplayTransport(
                isLive: _isLive,
                isPlaying: _mode == _ObservedReplayMode.replayPlaying,
                enabled: canvasFlow.transitions.isNotEmpty,
                speed: _speed,
                banner: _replayBanner,
                onJumpStart: _jumpStart,
                onStepBack: _stepBack,
                onPlayPause: _playOrToggle,
                onStepForward: _stepForward,
                onJumpEnd: _jumpEnd,
                onExit: _exitReplay,
                onCycleSpeed: _cycleSpeed,
                onExport: _exportSession,
                onImport: _importSession,
              ),
            Expanded(
              child: canvasFlow.edges.isEmpty
                  ? const _EmptyObservedFlow()
                  : NavigationNodeFlowAutoFit(
                      onFit: _controller.fitToView,
                      child: NodeFlowEditor<_ObservedNodeData, Object?>(
                        key: const ValueKey('observed-node-flow'),
                        controller: _controller,
                        theme: _observedNodeFlowTheme,
                        behavior: _isReadOnly
                            ? NodeFlowBehavior.inspect
                            : NodeFlowBehavior.preview,
                        events: NodeFlowEvents<_ObservedNodeData, Object?>(
                          onInit: _controller.fitToView,
                          node: NodeEvents<_ObservedNodeData>(
                            onTap: (node) => setState(() {
                              _selectedNodeId = node.data.id;
                            }),
                            onDoubleTap: (node) => _openZoomModal(node.data.id),
                          ),
                        ),
                        nodeBuilder: (context, node) {
                          final id = node.data.id;
                          final graphNode = widget.graph.nodes[id]!;
                          final flowNode = canvasFlow.nodes[id]!;
                          return _ObservedFlowNodeCard(
                            key: ValueKey('observed-flow-node-$id'),
                            graphNode: graphNode,
                            flowNode: flowNode,
                            preview: _previewFor(id),
                            isCurrent: _isLive && currentId == id,
                            isReplay: !_isLive && playheadToId == id,
                            isReplayFrom:
                                !_isLive &&
                                playheadFromId == id &&
                                playheadToId != id,
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
              preview: _previewFor(zoomedId!),
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
    required this.transitionLabel,
    required this.inspectedNode,
    required this.isSelected,
    required this.captureEnabled,
    required this.onCaptureChanged,
    required this.isReadOnly,
    required this.onReadOnlyChanged,
    required this.onAutoLayout,
    required this.onReset,
    required this.onClear,
  });

  final NavigationFlowRecorder<Object> flow;
  final String transitionLabel;
  final NavigationGraphNode<Object>? inspectedNode;
  final bool isSelected;
  final bool captureEnabled;
  final ValueChanged<bool> onCaptureChanged;
  final bool isReadOnly;
  final ValueChanged<bool> onReadOnlyChanged;
  final VoidCallback? onAutoLayout;
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
                  'paths  •  $transitionLabel'
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
            key: const ValueKey('observed-mode-toggle'),
            semanticsLabel: isReadOnly
                ? 'Switch to move mode (unlock nodes)'
                : 'Switch to readonly mode (lock nodes)',
            icon: isReadOnly
                ? CupertinoIcons.lock_fill
                : CupertinoIcons.lock_open,
            color: isReadOnly
                ? _ObservedFlowColors.selected
                : DebugTheme.textSecondary,
            onTap: () => onReadOnlyChanged(!isReadOnly),
          ),
          _HeaderAction(
            key: const ValueKey('observed-auto-layout'),
            semanticsLabel: 'Auto layout observed flow',
            icon: CupertinoIcons.sparkles,
            color: onAutoLayout == null
                ? DebugTheme.textDisabled
                : _ObservedFlowColors.selected,
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
  final VoidCallback? onTap;
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
    this.preview,
    required this.isCurrent,
    this.isReplay = false,
    this.isReplayFrom = false,
    required this.isSelected,
    required this.captureEnabled,
    required this.onZoom,
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final NavigationFlowScreenPreview? preview;
  final bool isCurrent;
  final bool isReplay;
  final bool isReplayFrom;
  final bool isSelected;
  final bool captureEnabled;
  final VoidCallback onZoom;
  final VoidCallback? onNavigate;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = isReplay || isCurrent || isSelected || isReplayFrom;
    final accent = isReplay || isReplayFrom
        ? _ObservedFlowColors.selected
        : isCurrent
        ? _ObservedFlowColors.active
        : _ObservedFlowColors.selected;
    final screenshotBorderColor = isHighlighted ? accent : DebugTheme.border;
    final infoBorderColor = isHighlighted
        ? accent.withValues(alpha: isReplayFrom ? 0.45 : 0.7)
        : DebugTheme.border;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${graphNode.label}, visited ${flowNode.visitCount} times',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: DebugTheme.backgroundDark,
                borderRadius: BorderRadius.circular(DebugTheme.radiusMd),
                border: Border.all(
                  color: screenshotBorderColor,
                  width: isHighlighted ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _ObservedFlowColors.selected.withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DebugTheme.radiusMd - 1.0),
                child: GestureDetector(
                  key: ValueKey('observed-screen-zoom-${graphNode.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onZoom,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ObservedScreenPreview(
                        key: ValueKey(
                          'observed-screen-preview-${graphNode.id}',
                        ),
                        preview: preview ?? flowNode.screenPreview,
                        captureEnabled: captureEnabled,
                      ),
                      if (isReplay || isCurrent)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: _ObservedNodeBadge(
                            label: isReplay ? 'REPLAY' : 'LIVE',
                            color: isReplay
                                ? _ObservedFlowColors.selected
                                : _ObservedFlowColors.active,
                            background: isReplay
                                ? const Color(0xFF0B1B33)
                                : _ObservedFlowColors.activeBackground,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            decoration: BoxDecoration(
              color: DebugTheme.backgroundDark,
              borderRadius: BorderRadius.circular(DebugTheme.radiusMd),
              border: Border.all(
                color: infoBorderColor,
                width: isHighlighted ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Row(
                  children: [
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
                        color: _ObservedFlowColors.edge.withValues(alpha: 0.14),
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
                  spacing: 4,
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
                    if (onNavigate != null) ...[
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
    );
  }
}

class _ObservedNodeBadge extends StatelessWidget {
  const _ObservedNodeBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DebugTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              decoration: TextDecoration.none,
            ),
          ),
        ],
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
      return Image.memory(
        screenPreview.bytes,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
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
    this.preview,
    required this.captureEnabled,
    required this.onClose,
    this.onNavigate,
    this.onCopy,
  });

  final NavigationGraphNode<Object> graphNode;
  final NavigationFlowNode<Object> flowNode;
  final NavigationFlowScreenPreview? preview;
  final bool captureEnabled;
  final VoidCallback onClose;
  final VoidCallback? onNavigate;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final preview = this.preview ?? flowNode.screenPreview;
    final capturedAt = preview?.capturedAt.toLocal();
    final capturedTime = capturedAt == null
        ? null
        : '${capturedAt.hour.toString().padLeft(2, '0')}:'
              '${capturedAt.minute.toString().padLeft(2, '0')}:'
              '${capturedAt.second.toString().padLeft(2, '0')}';
    final aspectRatio = preview?.aspectRatio ?? (9.0 / 16.0);
    const headerHeight = 44.0;
    const footerHeight = 88.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final imageSize = _fitObservedPreviewSize(
          viewport: viewport,
          aspectRatio: aspectRatio,
          chromeHeight: headerHeight + footerHeight,
        );
        final panelWidth = math.min(
          math.max(imageSize.width, 280.0),
          math.max(160.0, viewport.width - 24),
        );

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.78 * t)),
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: t,
                    child: Transform.scale(
                      scale: 0.94 + 0.06 * t,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          key: const ValueKey('observed-screen-preview-zoom'),
                          width: panelWidth,
                          decoration: BoxDecoration(
                            color: DebugTheme.backgroundDark,
                            borderRadius: BorderRadius.circular(
                              DebugTheme.radiusLg,
                            ),
                            border: Border.all(
                              color: DebugTheme.border,
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x99000000),
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              DebugTheme.radiusLg - 1,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: headerHeight,
                                  child: _ObservedZoomHeader(
                                    label: graphNode.label,
                                    uri: flowNode.lastUri.toString(),
                                    onClose: onClose,
                                  ),
                                ),
                                ColoredBox(
                                  color: const Color(0xFF050505),
                                  child: Center(
                                    child: ClipRect(
                                      child: SizedBox(
                                        width: imageSize.width,
                                        height: imageSize.height,
                                        child: preview == null
                                            ? _ObservedZoomPlaceholder(
                                                captureEnabled: captureEnabled,
                                              )
                                            : InteractiveViewer(
                                                minScale: 1,
                                                maxScale: 4,
                                                clipBehavior: Clip.none,
                                                child: Image.memory(
                                                  preview.bytes,
                                                  width: imageSize.width,
                                                  height: imageSize.height,
                                                  fit: BoxFit.contain,
                                                  alignment:
                                                      Alignment.topCenter,
                                                  gaplessPlayback: true,
                                                  filterQuality:
                                                      FilterQuality.high,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                                _ObservedZoomFooter(
                                  visitCount: flowNode.visitCount,
                                  capturedTime: capturedTime,
                                  onNavigate: onNavigate,
                                  onCopy: onCopy,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ObservedZoomHeader extends StatelessWidget {
  const _ObservedZoomHeader({
    required this.label,
    required this.uri,
    required this.onClose,
  });

  final String label;
  final String uri;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.rectangle_stack_fill,
            color: _ObservedFlowColors.selected,
            size: 13,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DebugTheme.textPrimary,
                    fontSize: DebugTheme.fontSizeMd,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                Text(
                  uri,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DebugTheme.textSecondary,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    decoration: TextDecoration.none,
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
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: DebugTheme.textMuted,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObservedZoomPlaceholder extends StatelessWidget {
  const _ObservedZoomPlaceholder({required this.captureEnabled});

  final bool captureEnabled;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: DebugTheme.backgroundDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              captureEnabled ? CupertinoIcons.camera : CupertinoIcons.eye_slash,
              color: DebugTheme.textMuted,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              captureEnabled ? 'Waiting for preview' : 'Screen capture off',
              style: const TextStyle(
                color: DebugTheme.textMuted,
                fontSize: DebugTheme.fontSizeSm,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservedZoomFooter extends StatelessWidget {
  const _ObservedZoomFooter({
    required this.visitCount,
    required this.capturedTime,
    this.onNavigate,
    this.onCopy,
  });

  final int visitCount;
  final String? capturedTime;
  final VoidCallback? onNavigate;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: DebugTheme.backgroundLight,
        border: Border(top: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Visited $visitCount times',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DebugTheme.textSecondary,
                    fontSize: 9,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (capturedTime != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    capturedTime!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: DebugTheme.textMuted,
                      fontSize: 9,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (onNavigate != null || onCopy != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onNavigate != null)
                  Expanded(
                    child: _ObservedZoomActionButton(
                      color: _ObservedFlowColors.active,
                      icon: CupertinoIcons.compass,
                      iconColor: const Color(0xFF0C2E25),
                      label: 'Navigate Here',
                      labelColor: const Color(0xFF0C2E25),
                      onPressed: onNavigate!,
                    ),
                  ),
                if (onNavigate != null && onCopy != null)
                  const SizedBox(width: 8),
                if (onCopy != null)
                  Expanded(
                    child: _ObservedZoomActionButton(
                      color: DebugTheme.backgroundDark,
                      icon: CupertinoIcons.doc_on_doc,
                      iconColor: DebugTheme.textPrimary,
                      label: 'Copy URI',
                      labelColor: DebugTheme.textPrimary,
                      onPressed: onCopy!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ObservedZoomActionButton extends StatelessWidget {
  const _ObservedZoomActionButton({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      minimumSize: Size.zero,
      color: color,
      borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
      onPressed: onPressed,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Size _fitObservedPreviewSize({
  required Size viewport,
  required double aspectRatio,
  required double chromeHeight,
}) {
  const horizontalInset = 32.0;
  const verticalInset = 32.0;
  final maxWidth = math.max(64.0, viewport.width - horizontalInset);
  final maxHeight = math.max(
    64.0,
    viewport.height - verticalInset - chromeHeight,
  );

  final double targetWidth;
  if (aspectRatio >= 1.0) {
    // Landscape: cap width up to 720 or maxWidth, max height to maxHeight
    final width = math.min(maxWidth, 720.0);
    final height = width / aspectRatio;
    if (height > maxHeight) {
      targetWidth = maxHeight * aspectRatio;
    } else {
      targetWidth = width;
    }
  } else {
    // Portrait: scale up comfortably to fill available height up to 640px or maxWidth up to 380px
    final targetHeight = math.min(maxHeight, 640.0);
    final width = targetHeight * aspectRatio;
    targetWidth = math.min(maxWidth, math.min(width, 380.0));
  }

  var width = targetWidth;
  var height = width / aspectRatio;
  if (height > maxHeight) {
    height = maxHeight;
    width = height * aspectRatio;
  }
  if (width > maxWidth) {
    width = maxWidth;
    height = width / aspectRatio;
  }
  return Size(width.clamp(48.0, maxWidth), height.clamp(48.0, maxHeight));
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
    const cardSpacing = 8.0;
    const infoCardHeight = 56.0;

    if (isLandscape) {
      nodeWidth = 240.0;
      previewHeight = (nodeWidth / aspectRatio).clamp(135.0, 190.0);
    } else {
      // Mobile Portrait: standard phone mockup ratio
      nodeWidth = 180.0;
      previewHeight = (nodeWidth / aspectRatio).clamp(240.0, 320.0);
    }

    final nodeHeight = previewHeight + cardSpacing + infoCardHeight;
    final nodeSize = Size(nodeWidth, nodeHeight);
    final flowGap = isLandscape ? 68.0 : 76.0;
    final siblingGap = isLandscape ? 52.0 : 44.0;
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

    // 3. Đo đạc chiều rộng phân nhánh đệ quy (Recursive Subtree Width)
    final subtreeWidths = <Object, double>{};
    double measureTree(Object u) {
      final children = discoveryChildren[u] ?? const [];
      if (children.isEmpty) {
        subtreeWidths[u] = nodeWidth;
        return nodeWidth;
      }
      var totalChildWidth = 0.0;
      for (final c in children) {
        totalChildWidth += measureTree(c);
      }
      totalChildWidth += siblingGap * (children.length - 1);
      final w = math.max(nodeWidth, totalChildWidth);
      subtreeWidths[u] = w;
      return w;
    }

    for (final rootId in treeRoots) {
      measureTree(rootId);
    }

    // 4. Định vị các Node theo Storyboard Flow (Trên xuống Dưới)
    final positions = <Object, Offset>{};
    void placeTree(Object u, double left, double top) {
      final w = subtreeWidths[u]!;
      final x = left + (w - nodeWidth) / 2;
      positions[u] = Offset(x, top);

      final children = discoveryChildren[u] ?? const [];
      if (children.isEmpty) return;

      final childTop = top + nodeHeight + flowGap;
      var childLeft = left;
      for (final c in children) {
        placeTree(c, childLeft, childTop);
        childLeft += subtreeWidths[c]! + siblingGap;
      }
    }

    var currentRootLeft = padding;
    for (final rootId in treeRoots) {
      placeTree(rootId, currentRootLeft, padding);
      currentRootLeft += subtreeWidths[rootId]! + siblingGap;
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
      if (!graph.nodes.containsKey(flowNode.id)) continue;
      if (!positions.containsKey(flowNode.id)) continue;
      final id = 'observed-node-${nodeIndex++}';
      flowIds[flowNode.id] = id;
      nodes.add(
        Node<_ObservedNodeData>(
          id: id,
          type: 'screen',
          position: previousPositions[flowNode.id] ?? positions[flowNode.id]!,
          size: nodeSize,
          data: _ObservedNodeData(flowNode.id),
          ports: createObservedNodeFlowPorts(nodeSize),
          theme: _observedNodeFlowTheme.nodeTheme.copyWith(
            backgroundColor: Colors.transparent,
            selectedBackgroundColor: Colors.transparent,
            highlightBackgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            selectedBorderColor: Colors.transparent,
            highlightBorderColor: Colors.transparent,
            borderWidth: 0,
            selectedBorderWidth: 0,
            borderRadius: BorderRadius.zero,
          ),
        ),
      );
    }

    final visiblePairKeys = <String>{};
    final connections = <Connection<Object?>>[];
    var connectionIndex = 0;
    for (final edge in flow.edges) {
      // Self-loop and the return of an already-drawn pair stay hidden.
      if (edge.fromId == edge.toId) continue;

      final sourceId = flowIds[edge.fromId];
      final targetId = flowIds[edge.toId];
      if (sourceId == null || targetId == null) continue;

      final fromPos = positions[edge.fromId];
      final toPos = positions[edge.toId];
      if (fromPos == null || toPos == null) continue;

      final fromStr = edge.fromId.toString();
      final toStr = edge.toId.toString();
      final pairKey = fromStr.compareTo(toStr) < 0
          ? '$fromStr|$toStr'
          : '$toStr|$fromStr';
      if (!visiblePairKeys.add(pairKey)) continue;

      final isDownward = toPos.dy > fromPos.dy;
      final edgeColor = _ObservedFlowColors.edge;

      // Cạnh tiến: Xuất cổng Bottom -> Nhập cổng Top
      // Cạnh ngang/lùi: Xuất cổng Right -> Nhập cổng Left
      final sourcePortId = isDownward
          ? nodeFlowOutputPortId
          : nodeFlowReturnOutPortId;
      final targetPortId = isDownward
          ? nodeFlowInputPortId
          : nodeFlowReturnInPortId;

      connections.add(
        Connection<Object?>(
          id: 'observed-edge-${connectionIndex++}',
          sourceNodeId: sourceId,
          sourcePortId: sourcePortId,
          targetNodeId: targetId,
          targetPortId: targetPortId,
          color: isDownward ? edgeColor : edgeColor.withValues(alpha: 0.7),
          selectedColor: _ObservedFlowColors.selected,
          strokeWidth: isDownward ? 1.8 : 1.4,
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
        nodeSize,
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
