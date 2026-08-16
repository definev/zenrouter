import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:hit/hit.dart';
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
    final Widget content = !widget.coordinator.debugOverlayOpen
        ? _buildCollapsedView()
        : _buildExpandedView();

    if (HitScope.maybeOf(context) == null) {
      return HitScope(child: content);
    }
    return content;
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
    return switch (widget.coordinator.debugLayoutMode) {
      DevToolsLayoutMode.stack => _buildStackExpandedView(),
      DevToolsLayoutMode.row => _buildFlexExpandedView(Axis.horizontal),
      DevToolsLayoutMode.column => _buildFlexExpandedView(Axis.vertical),
    };
  }

  Widget _buildStackExpandedView() {
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
          child: _buildPanelContainer(isFloating: true, isMobile: isMobile),
        );
      },
    );
  }

  Widget _buildFlexExpandedView(Axis direction) {
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
        final isHorizontal = direction == Axis.horizontal;

        final defaultDimension = isHorizontal
            ? (isMobile
                  ? viewportSize.width
                  : math.min(460.0, math.max(340.0, viewportSize.width * 0.45)))
            : (isMobile
                  ? _mobilePanelHeight
                  : math.min(
                      380.0,
                      math.max(240.0, viewportSize.height * 0.45),
                    ));

        final panel = _ResizableFlexDebugPanel(
          direction: direction,
          availableSize: viewportSize,
          defaultDimension: defaultDimension,
          maximized: _panelMaximized,
          child: _buildPanelContainer(
            isFloating: false,
            isMobile: isMobile,
            border: isHorizontal
                ? const Border(left: BorderSide(color: DebugTheme.border))
                : const Border(top: BorderSide(color: DebugTheme.border)),
          ),
        );

        if (isHorizontal && constraints.hasBoundedWidth) {
          return Align(alignment: Alignment.centerRight, child: panel);
        } else if (!isHorizontal && constraints.hasBoundedHeight) {
          return Align(alignment: Alignment.bottomCenter, child: panel);
        }
        return panel;
      },
    );
  }

  Widget _buildPanelContainer({
    required bool isFloating,
    required bool isMobile,
    BoxBorder? border,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DebugTheme.background,
        borderRadius: BorderRadius.circular(
          isFloating && !isMobile && !_panelMaximized ? DebugTheme.radiusLg : 0,
        ),
        border: border ?? Border.all(color: DebugTheme.border),
        boxShadow: isFloating
            ? [
                BoxShadow(
                  color: const Color(0xFF000000).withAlpha(50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
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
          const SizedBox(width: DebugTheme.spacingMd),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x6610B981),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ZenRouter DevTools',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DebugTheme.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _ToolMenuButton(coordinator: widget.coordinator),
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

class _ResizableFlexDebugPanel extends StatefulWidget {
  const _ResizableFlexDebugPanel({
    required this.direction,
    required this.availableSize,
    required this.defaultDimension,
    required this.maximized,
    required this.child,
  });

  static const _minimumWidth = 320.0;
  static const _minimumHeight = 220.0;

  final Axis direction;
  final Size availableSize;
  final double defaultDimension;
  final bool maximized;
  final Widget child;

  @override
  State<_ResizableFlexDebugPanel> createState() =>
      _ResizableFlexDebugPanelState();
}

class _ResizableFlexDebugPanelState extends State<_ResizableFlexDebugPanel> {
  double? _customDimension;
  bool _resizing = false;
  double? _resizeStartPointer;
  double? _resizeStartDimension;

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  @override
  void didUpdateWidget(_ResizableFlexDebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maximized) {
      _resizing = false;
      _resizeStartPointer = null;
      _resizeStartDimension = null;
    }
  }

  double get _panelDimension {
    final available = _isHorizontal
        ? widget.availableSize.width
        : widget.availableSize.height;
    if (widget.maximized) return available;
    return _clampDimension(
      _customDimension ?? widget.defaultDimension,
      available,
    );
  }

  double _clampDimension(double requested, double available) {
    final minDim = math.min(
      _isHorizontal
          ? _ResizableFlexDebugPanel._minimumWidth
          : _ResizableFlexDebugPanel._minimumHeight,
      available,
    );
    return requested.clamp(minDim, available).toDouble();
  }

  void _startResize(DragStartDetails details) {
    _resizeStartPointer = _isHorizontal
        ? details.globalPosition.dx
        : details.globalPosition.dy;
    _resizeStartDimension = _panelDimension;
    setState(() => _resizing = true);
  }

  void _updateResize(DragUpdateDetails details) {
    final startPos = _resizeStartPointer;
    final startDim = _resizeStartDimension;
    if (startPos == null || startDim == null) return;
    final delta =
        (_isHorizontal
            ? details.globalPosition.dx
            : details.globalPosition.dy) -
        startPos;
    final requested = startDim - delta;
    final available = _isHorizontal
        ? widget.availableSize.width
        : widget.availableSize.height;
    setState(() {
      _customDimension = _clampDimension(requested, available);
    });
  }

  void _endResize() {
    if (!_resizing) return;
    setState(() {
      _resizing = false;
      _resizeStartPointer = null;
      _resizeStartDimension = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dim = _panelDimension;
    return AnimatedContainer(
      key: const ValueKey('zenrouter-debug-panel'),
      duration: _resizing ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: _isHorizontal ? dim : widget.availableSize.width,
      height: _isHorizontal ? widget.availableSize.height : dim,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          if (!widget.maximized)
            Positioned(
              left: 0,
              top: 0,
              right: _isHorizontal ? null : 0,
              bottom: _isHorizontal ? 0 : null,
              child: _FlexPanelResizeHandle(
                direction: widget.direction,
                onPanStart: _startResize,
                onPanUpdate: _updateResize,
                onPanEnd: (_) => _endResize(),
                onPanCancel: _endResize,
              ),
            ),
        ],
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
    return HitLayer(
      alignment: Alignment.center,
      hitChild: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: const SizedBox(
          width: 52,
          height: 52,
        ),
      ),
      paintChild: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isHovered
                ? const [Color(0xFF2E2E2E), Color(0xFF181818)]
                : const [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: _isHovered
                ? const Color(0x80FFFFFF)
                : const Color(0x33FFFFFF),
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? const Color(0x663B82F6)
                  : const Color(0x99000000),
              blurRadius: _isHovered ? 14 : 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CountBadge(
          count: widget.problems,
          child: Icon(
            CupertinoIcons.ant,
            color: _isHovered ? const Color(0xFFFFFFFF) : const Color(0xFFE2E8F0),
            size: 19,
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

class _HeaderIconButton extends StatefulWidget {
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
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: Semantics(
        button: true,
        label: widget.semanticsLabel,
        child: HitLayer(
          alignment: Alignment.center,
          hitChild: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: const SizedBox(
                width: 36,
                height: 36,
              ),
            ),
          ),
          paintChild: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? const Color(0xFF242424)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
              border: Border.all(
                color: _isHovered ? const Color(0xFF383838) : const Color(0x00000000),
              ),
            ),
            child: Icon(
              widget.icon,
              color: _isHovered ? DebugTheme.textPrimary : DebugTheme.textMuted,
              size: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiagonalGripPainter extends CustomPainter {
  const _DiagonalGripPainter({
    required this.color,
    required this.glowColor,
    this.isHovered = false,
  });

  final Color color;
  final Color glowColor;
  final bool isHovered;

  @override
  void paint(Canvas canvas, Size size) {
    if (isHovered) {
      final glowPaint = Paint()
        ..color = glowColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(const Offset(3.5, 9.0), const Offset(9.0, 3.5), glowPaint);
      canvas.drawLine(const Offset(5.5, 14.0), const Offset(14.0, 5.5), glowPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Two crisp, parallel diagonal grip slashes (//) across the top-left corner
    canvas.drawLine(const Offset(3.5, 9.0), const Offset(9.0, 3.5), paint);
    canvas.drawLine(const Offset(5.5, 14.0), const Offset(14.0, 5.5), paint);
  }

  @override
  bool shouldRepaint(covariant _DiagonalGripPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.isHovered != isHovered;
  }
}

class _PanelResizeHandle extends StatefulWidget {
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
  State<_PanelResizeHandle> createState() => _PanelResizeHandleState();
}

class _PanelResizeHandleState extends State<_PanelResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isDragging;
    return Semantics(
      label: 'Resize debug panel',
      child: HitLayer(
        alignment: Alignment.topLeft,
        hitChild: MouseRegion(
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            key: const ValueKey('zenrouter-debug-panel-resize-handle'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() => _isDragging = true);
              widget.onPanStart(details);
            },
            onPanUpdate: widget.onPanUpdate,
            onPanEnd: (details) {
              setState(() => _isDragging = false);
              widget.onPanEnd(details);
            },
            onPanCancel: () {
              setState(() => _isDragging = false);
              widget.onPanCancel();
            },
            child: const SizedBox(width: 32, height: 32),
          ),
        ),
        paintChild: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isActive ? const Color(0x1A3B82F6) : const Color(0x00000000),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(6),
            ),
          ),
          child: CustomPaint(
            painter: _DiagonalGripPainter(
              color: isActive
                  ? const Color(0xFF60A5FA)
                  : DebugTheme.textMuted.withAlpha(140),
              glowColor: const Color(0x803B82F6),
              isHovered: isActive,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlexPanelResizeHandle extends StatefulWidget {
  const _FlexPanelResizeHandle({
    required this.direction,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  final Axis direction;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final VoidCallback onPanCancel;

  @override
  State<_FlexPanelResizeHandle> createState() => _FlexPanelResizeHandleState();
}

class _FlexPanelResizeHandleState extends State<_FlexPanelResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final cursor = _isHorizontal
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;

    return Semantics(
      label: _isHorizontal
          ? 'Resize debug panel width'
          : 'Resize debug panel height',
      child: HitLayer(
        alignment: Alignment.center,
        hitChild: MouseRegion(
          cursor: cursor,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            key: ValueKey(
              _isHorizontal
                  ? 'zenrouter-debug-panel-row-resize-handle'
                  : 'zenrouter-debug-panel-column-resize-handle',
            ),
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              setState(() => _isDragging = true);
              widget.onPanStart(details);
            },
            onPanUpdate: widget.onPanUpdate,
            onPanEnd: (details) {
              setState(() => _isDragging = false);
              widget.onPanEnd(details);
            },
            onPanCancel: () {
              setState(() => _isDragging = false);
              widget.onPanCancel();
            },
            child: SizedBox(
              width: _isHorizontal ? 24 : double.infinity,
              height: _isHorizontal ? double.infinity : 24,
            ),
          ),
        ),
        paintChild: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _isHovered || _isDragging ? 1.0 : 0.0,
          child: Container(
            width: _isHorizontal ? 2 : double.infinity,
            height: _isHorizontal ? double.infinity : 2,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              boxShadow: [
                BoxShadow(
                  color: Color(0x663B82F6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TOOL MENU
// =============================================================================

class _ToolMenuButton extends StatefulWidget {
  const _ToolMenuButton({required this.coordinator});

  final CoordinatorDebug coordinator;

  @override
  State<_ToolMenuButton> createState() => _ToolMenuButtonState();
}

class _ToolMenuButtonState extends State<_ToolMenuButton> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  void _closeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _closeMenu();
      setState(() {});
      return;
    }

    final overlayState = Overlay.of(context);
    final buttonBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    final buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final buttonSize = buttonBox.size;
    final mediaSize = MediaQuery.sizeOf(context);

    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _closeMenu();
                  if (mounted) setState(() {});
                },
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              top: buttonPosition.dy + buttonSize.height + 6,
              right: math.max(
                8.0,
                mediaSize.width - buttonPosition.dx - buttonSize.width,
              ),
              child: _ToolMenuPopup(
                key: const ValueKey('zenrouter-debug-tool-menu-popup'),
                currentMode: widget.coordinator.debugLayoutMode,
                onSelectMode: (mode) {
                  _closeMenu();
                  if (mounted) setState(() {});
                  widget.coordinator.setDebugLayoutMode(mode);
                },
              ),
            ),
          ],
        );
      },
    );

    _overlayEntry = entry;
    overlayState.insert(entry);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _overlayEntry != null;
    return Semantics(
      button: true,
      label: 'DevTools options and layout modes',
      child: HitLayer(
        alignment: Alignment.center,
        hitChild: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            key: _buttonKey,
            behavior: HitTestBehavior.opaque,
            onTap: _toggleMenu,
            child: const SizedBox(width: 36, height: 36),
          ),
        ),
        paintChild: AnimatedContainer(
          key: const ValueKey('zenrouter-debug-tool-menu-button'),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isOpen || _isHovered
                ? const Color(0xFF242424)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
            border: Border.all(
              color: isOpen || _isHovered
                  ? const Color(0xFF383838)
                  : const Color(0x00000000),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            CupertinoIcons.ellipsis_vertical,
            color: isOpen || _isHovered
                ? DebugTheme.textPrimary
                : DebugTheme.textMuted,
            size: 13,
          ),
        ),
      ),
    );
  }
}

class _ToolMenuPopup extends StatelessWidget {
  const _ToolMenuPopup({
    super.key,
    required this.currentMode,
    required this.onSelectMode,
  });

  final DevToolsLayoutMode currentMode;
  final ValueChanged<DevToolsLayoutMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: 'Inter',
        height: 1.4,
        color: DebugTheme.textPrimary,
        decoration: TextDecoration.none,
      ),
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(DebugTheme.radiusLg),
          border: Border.all(color: const Color(0xFF2E2E2E)),
          boxShadow: const [
            BoxShadow(
              color: Color(0xCC000000),
              blurRadius: 24,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 4, 10, 6),
              child: Text(
                'LAYOUT MODE',
                style: TextStyle(
                  color: Color(0xFF737373),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _ToolMenuItem(
              key: const ValueKey('zenrouter-debug-layout-stack'),
              icon: CupertinoIcons.layers,
              label: 'Floating Overlay',
              isSelected: currentMode == DevToolsLayoutMode.stack,
              onTap: () => onSelectMode(DevToolsLayoutMode.stack),
            ),
            _ToolMenuItem(
              key: const ValueKey('zenrouter-debug-layout-row'),
              icon: CupertinoIcons.sidebar_right,
              label: 'Dock to Right',
              isSelected: currentMode == DevToolsLayoutMode.row,
              onTap: () => onSelectMode(DevToolsLayoutMode.row),
            ),
            _ToolMenuItem(
              key: const ValueKey('zenrouter-debug-layout-column'),
              icon: CupertinoIcons.square_split_1x2,
              label: 'Dock to Bottom',
              isSelected: currentMode == DevToolsLayoutMode.column,
              onTap: () => onSelectMode(DevToolsLayoutMode.column),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolMenuItem extends StatefulWidget {
  const _ToolMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ToolMenuItem> createState() => _ToolMenuItemState();
}

class _ToolMenuItemState extends State<_ToolMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          height: 32,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF1E293B)
                : (_isHovered ? const Color(0xFF222222) : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(DebugTheme.radius),
            border: widget.isSelected
                ? Border.all(color: const Color(0xFF334155))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.isSelected
                    ? const Color(0xFF60A5FA)
                    : (_isHovered
                        ? DebugTheme.textPrimary
                        : DebugTheme.textSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isSelected
                        ? const Color(0xFFF1F5F9)
                        : (_isHovered
                            ? DebugTheme.textPrimary
                            : DebugTheme.textSecondary),
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(
                  CupertinoIcons.checkmark,
                  size: 12,
                  color: Color(0xFF60A5FA),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
