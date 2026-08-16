import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:zenrouter/zenrouter.dart';

import 'coordinator_debug.dart';
import 'tabs/tabs.dart';
import 'widgets/widgets.dart';

// =============================================================================
// DEBUG OVERLAY WIDGET
// =============================================================================

/// The main debug overlay widget that displays the debugging panel.
class DebugOverlay<T extends RouteUnique> extends StatefulWidget {
  /// Creates a debug overlay for the given [coordinator].
  const DebugOverlay({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  State<DebugOverlay<T>> createState() => _DebugOverlayState<T>();
}

class _DebugOverlayState<T extends RouteUnique> extends State<DebugOverlay<T>> {
  static const _desktopPanelSize = Size(420, 500);
  static const _mobilePanelHeight = 400.0;
  static const _launcherMargin = DebugTheme.spacingLg;

  final TextEditingController _uriController = TextEditingController();
  final GlobalKey _collapsedViewportKey = GlobalKey();
  final GlobalKey _launcherKey = GlobalKey();

  _DebugTab _selectedTab = _DebugTab.problems;
  bool _panelMaximized = false;
  Offset? _launcherPosition;
  Offset? _launcherDragStartPosition;
  Offset? _launcherDragStartPointer;
  Rect _launcherBounds = Rect.zero;

  List<_DebugTab> get _availableTabs => [
    _DebugTab.problems,
    _DebugTab.inspect,
    _DebugTab.active,
    if (widget.coordinator.routeManifest.nodes.isNotEmpty) _DebugTab.graph,
    if (widget.coordinator.debugRoutes.isNotEmpty) _DebugTab.routes,
  ];

  void _handleUriChanged() {
    final newPath = widget.coordinator.currentUri.toString();
    if (newPath != _uriController.text) {
      _uriController.text = newPath;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _handleUriChanged();
    widget.coordinator.addListener(_handleUriChanged);
  }

  @override
  void dispose() {
    _uriController.dispose();
    widget.coordinator.removeListener(_handleUriChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.coordinator.debugOverlayOpen) {
      return _buildCollapsedView();
    }
    return _buildExpandedView();
  }

  // ===========================================================================
  // COLLAPSED VIEW
  // ===========================================================================

  Widget _buildCollapsedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final viewportSize = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : mediaSize.width,
          constraints.hasBoundedHeight
              ? constraints.maxHeight
              : mediaSize.height,
        );
        final safePadding = MediaQuery.paddingOf(context);
        _launcherBounds = Rect.fromLTRB(
          safePadding.left + _launcherMargin,
          safePadding.top + _launcherMargin,
          math.max(
            safePadding.left + _launcherMargin,
            viewportSize.width - safePadding.right - _launcherMargin,
          ),
          math.max(
            safePadding.top + _launcherMargin,
            viewportSize.height - safePadding.bottom - _launcherMargin,
          ),
        );

        final launcher = _buildDraggableLauncher(
          math.max(40.0, _launcherBounds.width),
        );
        final launcherSize = _launcherSize;
        final resolvedPosition = _launcherPosition == null
            ? null
            : _clampLauncherPosition(
                _launcherPosition!,
                launcherSize,
                _launcherBounds,
              );

        return SizedBox.expand(
          key: _collapsedViewportKey,
          child: Stack(
            children: [
              if (resolvedPosition == null)
                Positioned(
                  right: safePadding.right + _launcherMargin,
                  bottom: safePadding.bottom + _launcherMargin,
                  child: launcher,
                )
              else
                Positioned(
                  left: resolvedPosition.dx,
                  top: resolvedPosition.dy,
                  child: launcher,
                ),
            ],
          ),
        );
      },
    );
  }

  Size get _launcherSize {
    final renderObject = _launcherKey.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject.size : const Size(40, 40);
  }

  Widget _buildDraggableLauncher(double maxWidth) {
    return MouseRegion(
      key: const ValueKey('zenrouter-debug-launcher'),
      cursor: SystemMouseCursors.move,
      child: Semantics(
        button: true,
        label: 'Open ZenRouter devtools',
        child: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          behavior: HitTestBehavior.opaque,
          onTap: widget.coordinator.toggleDebugOverlay,
          onPanStart: _startLauncherDrag,
          onPanUpdate: _updateLauncherDrag,
          onPanEnd: (_) => _endLauncherDrag(),
          onPanCancel: _endLauncherDrag,
          child: ListenableBuilder(
            listenable: _uriController,
            builder: (context, child) {
              const fabFootprint = 40.0 + DebugTheme.spacingXs;
              final maximumPillWidth = math.max(0.0, maxWidth - fabFootprint);
              final textPainter = TextPainter(
                text: TextSpan(
                  text: _uriController.text,
                  style: const TextStyle(fontSize: DebugTheme.fontSizeMd),
                ),
                textDirection: TextDirection.ltr,
                maxLines: 1,
              )..layout(maxWidth: maximumPillWidth);
              final pillWidth = math.min(
                maximumPillWidth,
                math.max(80.0, textPainter.width + DebugTheme.spacingMd * 2),
              );

              return SizedBox(
                key: _launcherKey,
                width: pillWidth + fabFootprint,
                child: Row(
                  children: [
                    SizedBox(
                      width: pillWidth,
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.only(
                          right: DebugTheme.spacingXs,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: DebugTheme.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000000).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(
                            DebugTheme.radiusFull,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _uriController.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.normal,
                            fontSize: DebugTheme.fontSizeMd,
                          ),
                        ),
                      ),
                    ),
                    _DebugFab(
                      key: const ValueKey('zenrouter-debug-launcher-button'),
                      problems: widget.coordinator.problems,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Offset _clampLauncherPosition(Offset requested, Size size, Rect bounds) {
    final maximumLeft = math.max(bounds.left, bounds.right - size.width);
    final maximumTop = math.max(bounds.top, bounds.bottom - size.height);
    return Offset(
      requested.dx.clamp(bounds.left, maximumLeft).toDouble(),
      requested.dy.clamp(bounds.top, maximumTop).toDouble(),
    );
  }

  void _startLauncherDrag(DragStartDetails details) {
    final launcherBox = _launcherKey.currentContext?.findRenderObject();
    final viewportBox = _collapsedViewportKey.currentContext
        ?.findRenderObject();
    if (launcherBox is! RenderBox || viewportBox is! RenderBox) return;
    _launcherDragStartPointer = details.globalPosition;
    _launcherDragStartPosition = viewportBox.globalToLocal(
      launcherBox.localToGlobal(Offset.zero),
    );
  }

  void _updateLauncherDrag(DragUpdateDetails details) {
    final startPointer = _launcherDragStartPointer;
    final startPosition = _launcherDragStartPosition;
    if (startPointer == null || startPosition == null) return;
    final requested = startPosition + details.globalPosition - startPointer;
    setState(() {
      _launcherPosition = _clampLauncherPosition(
        requested,
        _launcherSize,
        _launcherBounds,
      );
    });
  }

  void _endLauncherDrag() {
    _launcherDragStartPointer = null;
    _launcherDragStartPosition = null;
  }

  // ===========================================================================
  // EXPANDED VIEW
  // ===========================================================================

  Widget _buildExpandedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final viewportSize = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : mediaSize.width,
          constraints.hasBoundedHeight
              ? constraints.maxHeight
              : mediaSize.height,
        );
        final isMobile = viewportSize.width < 600;
        final panelMargin = switch ((isMobile, _panelMaximized)) {
          (_, true) => EdgeInsets.zero,
          (true, false) => EdgeInsets.zero,
          (false, false) => const EdgeInsets.all(DebugTheme.spacingLg),
        };
        final availableSize = Size(
          math.max(0, viewportSize.width - panelMargin.horizontal),
          math.max(0, viewportSize.height - panelMargin.vertical),
        );
        final defaultSize = Size(
          isMobile ? availableSize.width : _desktopPanelSize.width,
          isMobile ? _mobilePanelHeight : _desktopPanelSize.height,
        );

        return _ResizableDebugPanel(
          availableSize: availableSize,
          defaultSize: defaultSize,
          margin: panelMargin,
          maximized: _panelMaximized,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: DebugTheme.background,
              borderRadius: BorderRadius.circular(
                isMobile || _panelMaximized ? 0 : DebugTheme.radiusLg,
              ),
              border: Border.all(color: DebugTheme.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withAlpha(50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                const _Divider(),
                _buildTabBar(),
                const _Divider(),
                Expanded(
                  child: switch (_selectedTab) {
                    _DebugTab.problems => ProblemsTab<T>(
                      coordinator: widget.coordinator,
                    ),
                    _DebugTab.inspect => PathListView<T>(
                      coordinator: widget.coordinator,
                    ),
                    _DebugTab.active => ActiveLayoutsListView<T>(
                      coordinator: widget.coordinator,
                    ),
                    _DebugTab.graph => NavigationGraphTab<T>(
                      coordinator: widget.coordinator,
                    ),
                    _DebugTab.routes => DebugRoutesListView<T>(
                      coordinator: widget.coordinator,
                    ),
                  },
                ),
                const _Divider(),
                _buildInputArea(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      height: 40,
      color: DebugTheme.backgroundDark,
      child: Row(
        children: [
          const SizedBox(width: 28),
          const ConnectionIndicator(),
          const SizedBox(width: DebugTheme.spacing),
          const Expanded(
            child: Text(
              'ZenRouter Devtools',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DebugTheme.textPrimary,
                fontSize: DebugTheme.fontSizeLg,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _HeaderIconButton(
            key: const ValueKey('zenrouter-debug-panel-maximize'),
            semanticsLabel: _panelMaximized
                ? 'Restore debug panel'
                : 'Maximize debug panel',
            icon: _panelMaximized
                ? CupertinoIcons.fullscreen_exit
                : CupertinoIcons.fullscreen,
            onTap: () => setState(() {
              _panelMaximized = !_panelMaximized;
            }),
          ),
          _HeaderIconButton(
            semanticsLabel: 'Close debug panel',
            icon: CupertinoIcons.xmark,
            onTap: widget.coordinator.toggleDebugOverlay,
            margin: const EdgeInsets.only(right: DebugTheme.spacingXs),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB BAR
  // ===========================================================================

  Widget _buildTabBar() {
    return Container(
      height: 36,
      color: DebugTheme.background,
      child: Row(
        children: [
          for (var index = 0; index < _availableTabs.length; index++) ...[
            if (index > 0) const _VerticalDivider(),
            Expanded(
              child: TabButton(
                label: _availableTabs[index].label,
                count: _availableTabs[index] == _DebugTab.problems
                    ? widget.coordinator.problems
                    : 0,
                isSelected: _selectedTab == _availableTabs[index],
                onTap: () => setState(() {
                  _selectedTab = _availableTabs[index];
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // INPUT AREA
  // ===========================================================================

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(DebugTheme.spacingMd),
      color: DebugTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: DebugTheme.backgroundDark,
              borderRadius: BorderRadius.circular(DebugTheme.radius),
              border: Border.all(color: DebugTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _uriController,
                    style: const TextStyle(
                      color: DebugTheme.textPrimary,
                      fontSize: DebugTheme.fontSizeLg,
                    ),
                    cursorColor: DebugTheme.textPrimary,
                    placeholder: 'Current path',
                    placeholderStyle: const TextStyle(
                      color: DebugTheme.textPlaceholder,
                    ),
                    decoration: const BoxDecoration(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DebugTheme.spacingMd,
                      vertical: 10,
                    ),
                    onSubmitted: _navigateUri,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DebugTheme.spacing),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Navigate',
                  icon: CupertinoIcons.arrow_right,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _navigateUri(_uriController.text),
                ),
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: ActionButton(
                  label: 'Push',
                  icon: CupertinoIcons.arrow_up,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _pushUri(_uriController.text),
                ),
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: ActionButton(
                  label: 'Replace',
                  icon: CupertinoIcons.arrow_swap,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _replaceUri(_uriController.text),
                ),
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: ActionButton(
                  label: 'Recover',
                  icon: CupertinoIcons.link,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _recoverUri(_uriController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // URI NAVIGATION METHODS
  // ===========================================================================

  void _navigateUri(String uriString) async {
    if (uriString.isEmpty) return;
    final uri = Uri.parse(uriString);
    final route = await widget.coordinator.parseRouteFromUri(uri);
    widget.coordinator.navigate(route!);
  }

  void _pushUri(String uriString) async {
    if (uriString.isEmpty) return;
    final uri = Uri.parse(uriString);
    final route = await widget.coordinator.parseRouteFromUri(uri);
    widget.coordinator.push(route!);
  }

  void _replaceUri(String uriString) async {
    if (uriString.isEmpty) return;
    final uri = Uri.parse(uriString);
    final route = await widget.coordinator.parseRouteFromUri(uri);
    widget.coordinator.replace(route!);
  }

  void _recoverUri(String uriString) async {
    if (uriString.isEmpty) return;
    final uri = Uri.parse(uriString);
    final route = await widget.coordinator.parseRouteFromUri(uri);
    widget.coordinator.recover(route!);
  }
}

enum _DebugTab {
  problems('Problems'),
  inspect('Inspect'),
  active('Active'),
  graph('Graph'),
  routes('Routes');

  const _DebugTab(this.label);

  final String label;
}

class _ResizableDebugPanel extends StatefulWidget {
  const _ResizableDebugPanel({
    required this.availableSize,
    required this.defaultSize,
    required this.margin,
    required this.maximized,
    required this.child,
  });

  static const _minimumPanelSize = Size(340, 320);

  final Size availableSize;
  final Size defaultSize;
  final EdgeInsets margin;
  final bool maximized;
  final Widget child;

  @override
  State<_ResizableDebugPanel> createState() => _ResizableDebugPanelState();
}

class _ResizableDebugPanelState extends State<_ResizableDebugPanel> {
  Size? _customPanelSize;
  bool _resizingPanel = false;
  Offset? _resizeStartPosition;
  Size? _resizeStartSize;

  @override
  void didUpdateWidget(_ResizableDebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maximized) {
      _resizingPanel = false;
      _resizeStartPosition = null;
      _resizeStartSize = null;
    }
  }

  Size get _panelSize {
    if (widget.maximized) return widget.availableSize;
    return _clampPanelSize(
      _customPanelSize ?? widget.defaultSize,
      widget.availableSize,
    );
  }

  Size _clampPanelSize(Size requested, Size available) {
    final minimumWidth = math.min(
      _ResizableDebugPanel._minimumPanelSize.width,
      available.width,
    );
    final minimumHeight = math.min(
      _ResizableDebugPanel._minimumPanelSize.height,
      available.height,
    );
    return Size(
      requested.width.clamp(minimumWidth, available.width).toDouble(),
      requested.height.clamp(minimumHeight, available.height).toDouble(),
    );
  }

  void _startPanelResize(DragStartDetails details) {
    _resizeStartPosition = details.globalPosition;
    _resizeStartSize = _panelSize;
    setState(() => _resizingPanel = true);
  }

  void _updatePanelResize(DragUpdateDetails details) {
    final startPosition = _resizeStartPosition;
    final startSize = _resizeStartSize;
    if (startPosition == null || startSize == null) return;
    final delta = details.globalPosition - startPosition;
    setState(() {
      _customPanelSize = _clampPanelSize(
        Size(startSize.width - delta.dx, startSize.height - delta.dy),
        widget.availableSize,
      );
    });
  }

  void _endPanelResize() {
    if (!_resizingPanel) return;
    setState(() {
      _resizingPanel = false;
      _resizeStartPosition = null;
      _resizeStartSize = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final panelSize = _panelSize;
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: widget.margin,
        child: AnimatedContainer(
          key: const ValueKey('zenrouter-debug-panel'),
          duration: _resizingPanel
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: panelSize.width,
          height: panelSize.height,
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (!widget.maximized)
                Positioned(
                  left: 0,
                  top: 0,
                  child: _PanelResizeHandle(
                    onPanStart: _startPanelResize,
                    onPanUpdate: _updatePanelResize,
                    onPanEnd: (_) => _endPanelResize(),
                    onPanCancel: _endPanelResize,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DEBUG FAB (Custom, no Material)
// =============================================================================

class _DebugFab extends StatefulWidget {
  const _DebugFab({super.key, required this.problems});

  final int problems;

  @override
  State<_DebugFab> createState() => _DebugFabState();
}

class _DebugFabState extends State<_DebugFab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF222222) : const Color(0xFF000000),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x3DFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withAlpha(100),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CountBadge(
          count: widget.problems,
          child: const Icon(
            CupertinoIcons.ant,
            color: Color(0xFFFFFFFF),
            size: 20,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: DebugTheme.border);
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: DebugTheme.border);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          margin: margin,
          alignment: Alignment.center,
          child: Icon(icon, color: DebugTheme.textDisabled, size: 15),
        ),
      ),
    );
  }
}

class _PanelResizeHandle extends StatelessWidget {
  const _PanelResizeHandle({
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: Semantics(
        label: 'Resize debug panel',
        child: GestureDetector(
          key: const ValueKey('zenrouter-debug-panel-resize-handle'),
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onPanCancel: onPanCancel,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  CupertinoIcons.resize,
                  color: DebugTheme.textMuted,
                  size: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
