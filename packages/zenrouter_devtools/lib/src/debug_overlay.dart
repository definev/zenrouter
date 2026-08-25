import 'dart:math' as math;
import 'dart:ui' as ui;

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
  static const _mobileBreakpoint = 600.0;
  static const _launcherMargin = DebugTheme.spacingLg;

  final TextEditingController _uriController = TextEditingController();
  final GlobalKey _collapsedViewportKey = GlobalKey();
  final GlobalKey _launcherKey = GlobalKey();

  _DebugTab _selectedTab = _DebugTab.problems;
  bool _panelMaximized = false;
  bool _uriExpanded = false;
  Alignment _launcherAlignment = Alignment.bottomRight;
  Alignment? _launcherDragStartAlignment;
  Offset? _launcherDragStartPointer;

  List<_DebugTab> get _availableTabs => [
    _DebugTab.problems,
    _DebugTab.inspect,
    _DebugTab.active,
    if (widget.coordinator.routeManifest.nodes.isNotEmpty) _DebugTab.graph,
    if (widget.coordinator.debugRoutes.isNotEmpty) _DebugTab.routes,
  ];

  bool _effectiveSeeThrough(BuildContext context) => widget.coordinator
      .debugPanelSeeThroughForWidth(MediaQuery.sizeOf(context).width);

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
    Widget content = !widget.coordinator.debugOverlayOpen
        ? _buildCollapsedView()
        : _buildExpandedView();

    if (HitScope.maybeOf(context) == null) {
      content = HitScope(child: content);
    }
    return HeroControllerScope.none(child: content);
  }

  // ===========================================================================
  // COLLAPSED VIEW
  // ===========================================================================

  Widget _buildCollapsedView() {
    final safeInsets = _overlaySafeInsets(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        safeInsets.left + _launcherMargin,
        safeInsets.top + _launcherMargin,
        safeInsets.right + _launcherMargin,
        safeInsets.bottom + _launcherMargin,
      ),
      child: SizedBox.expand(
        key: _collapsedViewportKey,
        child: Align(
          alignment: _launcherAlignment,
          child: _buildDraggableLauncher(),
        ),
      ),
    );
  }

  Widget _buildDraggableLauncher() {
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
          child: KeyedSubtree(
            key: _launcherKey,
            child: _DebugFab(
              key: const ValueKey('zenrouter-debug-launcher-button'),
              problems: widget.coordinator.problems,
            ),
          ),
        ),
      ),
    );
  }

  Size get _launcherSize {
    final renderObject = _launcherKey.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject.size : const Size(40, 40);
  }

  Alignment _alignmentFromOffset(Offset offset, Size freeSize) {
    final x = freeSize.width == 0 ? 0.0 : (offset.dx / freeSize.width) * 2 - 1;
    final y = freeSize.height == 0
        ? 0.0
        : (offset.dy / freeSize.height) * 2 - 1;
    return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
  }

  Offset _offsetFromAlignment(Alignment alignment, Size freeSize) {
    return Offset(
      (alignment.x + 1) / 2 * freeSize.width,
      (alignment.y + 1) / 2 * freeSize.height,
    );
  }

  Size? _collapsedViewportSize() {
    final renderObject = _collapsedViewportKey.currentContext
        ?.findRenderObject();
    return renderObject is RenderBox ? renderObject.size : null;
  }

  Size _freeLauncherSize(Size viewportSize, Size launcherSize) {
    return Size(
      math.max(0.0, viewportSize.width - launcherSize.width),
      math.max(0.0, viewportSize.height - launcherSize.height),
    );
  }

  void _startLauncherDrag(DragStartDetails details) {
    if (_collapsedViewportSize() == null) return;
    _launcherDragStartPointer = details.globalPosition;
    _launcherDragStartAlignment = _launcherAlignment;
  }

  void _updateLauncherDrag(DragUpdateDetails details) {
    final startPointer = _launcherDragStartPointer;
    final startAlignment = _launcherDragStartAlignment;
    final viewportSize = _collapsedViewportSize();
    if (startPointer == null ||
        startAlignment == null ||
        viewportSize == null) {
      return;
    }
    final freeSize = _freeLauncherSize(viewportSize, _launcherSize);
    final requested =
        _offsetFromAlignment(startAlignment, freeSize) +
        details.globalPosition -
        startPointer;
    setState(() {
      _launcherAlignment = _alignmentFromOffset(requested, freeSize);
    });
  }

  void _endLauncherDrag() {
    _launcherDragStartPointer = null;
    _launcherDragStartAlignment = null;
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
        final isMobile = viewportSize.width < _mobileBreakpoint;
        final safeInsets = _overlaySafeInsets(context);
        final panelMargin = switch ((isMobile, _panelMaximized)) {
          (_, true) => safeInsets,
          (true, false) => safeInsets,
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
        final isMobile = viewportSize.width < _mobileBreakpoint;
        final isHorizontal = direction == Axis.horizontal;
        final safeInsets = _overlaySafeInsets(context);
        // Flex layouts already share space with the app; only inset the panel
        // edges that can collide with the notch / home indicator / keyboard.
        final panelInsets = EdgeInsets.only(
          top: isHorizontal || _panelMaximized ? safeInsets.top : 0,
          left: isHorizontal ? 0 : safeInsets.left,
          right: safeInsets.right,
          bottom: safeInsets.bottom,
        );
        final availableSize = Size(
          math.max(0, viewportSize.width - panelInsets.horizontal),
          math.max(0, viewportSize.height - panelInsets.vertical),
        );

        final defaultDimension = isHorizontal
            ? (isMobile
                  ? availableSize.width
                  : math.min(
                      460.0,
                      math.max(340.0, availableSize.width * 0.45),
                    ))
            : (isMobile
                  ? _mobilePanelHeight
                  : math.min(
                      380.0,
                      math.max(240.0, availableSize.height * 0.45),
                    ));

        final panel = _ResizableFlexDebugPanel(
          direction: direction,
          availableSize: availableSize,
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

        Widget positioned = panel;
        if (isHorizontal && constraints.hasBoundedWidth) {
          positioned = Align(alignment: Alignment.centerRight, child: panel);
        } else if (!isHorizontal && constraints.hasBoundedHeight) {
          positioned = Align(alignment: Alignment.bottomCenter, child: panel);
        }

        if (panelInsets == EdgeInsets.zero) return positioned;
        return Padding(padding: panelInsets, child: positioned);
      },
    );
  }

  /// Notch / home-indicator / keyboard insets for the overlay chrome.
  ///
  /// Prefer [MediaQuery.viewPadding] so the home indicator is still respected
  /// while the keyboard is open ([MediaQuery.padding] bottom collapses to 0).
  EdgeInsets _overlaySafeInsets(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return EdgeInsets.only(
      top: viewPadding.top,
      left: viewPadding.left,
      right: viewPadding.right,
      bottom: viewInsets.bottom > 0 ? viewInsets.bottom : viewPadding.bottom,
    );
  }

  Widget _buildPanelContainer({
    required bool isFloating,
    required bool isMobile,
    BoxBorder? border,
  }) {
    final seeThrough = _effectiveSeeThrough(context);
    final compact = isMobile;
    final radius = BorderRadius.circular(
      isFloating && !isMobile && !_panelMaximized ? DebugTheme.radiusLg : 0,
    );
    final panel = Container(
      key: ValueKey('zenrouter-debug-panel-surface-$seeThrough'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DebugTheme.surface(
          DebugTheme.background,
          seeThrough: seeThrough,
        ),
        borderRadius: radius,
        border: border ?? Border.all(color: DebugTheme.border),
        boxShadow: isFloating
            ? [
                BoxShadow(
                  color: const Color(
                    0xFF000000,
                  ).withAlpha(seeThrough ? 28 : 50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: DebugPanelAppearance(
        seeThrough: seeThrough,
        child: Column(
          children: [
            _buildHeader(compact: compact),
            const _Divider(),
            _buildTabBar(compact: compact),
            const _Divider(),
            Expanded(
              child: ColoredBox(
                color: DebugTheme.surface(
                  DebugTheme.background,
                  seeThrough: seeThrough,
                ),
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
            ),
            const _Divider(),
            _buildInputArea(compact: compact),
          ],
        ),
      ),
    );

    if (!seeThrough) return panel;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: DebugTheme.seeThroughBlurSigma,
          sigmaY: DebugTheme.seeThroughBlurSigma,
        ),
        child: panel,
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader({required bool compact}) {
    final seeThrough = _effectiveSeeThrough(context);
    return Container(
      height: compact ? 36 : 40,
      color: DebugTheme.surface(
        DebugTheme.backgroundDark,
        seeThrough: seeThrough,
      ),
      child: Row(
        children: [
          SizedBox(width: compact ? DebugTheme.spacing : DebugTheme.spacingMd),
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
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
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Text(
              compact ? 'DevTools' : 'ZenRouter DevTools',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DebugTheme.textPrimary,
                fontSize: compact ? 12 : 12.5,
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

  Widget _buildTabBar({required bool compact}) {
    final seeThrough = _effectiveSeeThrough(context);
    return Container(
      key: ValueKey('zenrouter-debug-tab-bar-$compact'),
      height: compact ? 40 : 36,
      color: DebugTheme.surface(DebugTheme.background, seeThrough: seeThrough),
      child: Row(
        children: [
          for (var index = 0; index < _availableTabs.length; index++) ...[
            if (index > 0) const _VerticalDivider(),
            Expanded(
              child: TabButton(
                label: _availableTabs[index].label,
                icon: compact ? _availableTabs[index].icon : null,
                iconOnly: compact,
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

  Widget _buildInputArea({required bool compact}) {
    final seeThrough = _effectiveSeeThrough(context);
    final showExpanded = !compact || _uriExpanded;

    if (compact && !showExpanded) {
      return Container(
        key: const ValueKey('zenrouter-debug-uri-collapsed'),
        padding: const EdgeInsets.symmetric(
          horizontal: DebugTheme.spacing,
          vertical: DebugTheme.spacingSm,
        ),
        color: DebugTheme.surface(
          DebugTheme.background,
          seeThrough: seeThrough,
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.link, size: 13, color: DebugTheme.textMuted),
            const SizedBox(width: DebugTheme.spacingSm),
            Expanded(
              child: Text(
                _uriController.text.isEmpty ? '/' : _uriController.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DebugTheme.textSecondary,
                  fontSize: DebugTheme.fontSizeMd,
                  fontFamily: 'monospace',
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: DebugTheme.spacingSm),
            SizedBox(
              width: 82,
              child: ActionButton(
                key: const ValueKey('zenrouter-debug-uri-expand'),
                label: 'Go to…',
                icon: CupertinoIcons.chevron_up,
                color: DebugTheme.textPrimary,
                backgroundColor: const Color(0xFF222222),
                onTap: () => setState(() => _uriExpanded = true),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: ValueKey('zenrouter-debug-uri-expanded-$compact'),
      padding: EdgeInsets.all(
        compact ? DebugTheme.spacing : DebugTheme.spacingMd,
      ),
      color: DebugTheme.surface(DebugTheme.background, seeThrough: seeThrough),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Padding(
              padding: const EdgeInsets.only(bottom: DebugTheme.spacingSm),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Go to URI',
                      style: TextStyle(
                        color: DebugTheme.textMuted,
                        fontSize: DebugTheme.fontSizeSm,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    key: const ValueKey('zenrouter-debug-uri-collapse'),
                    onTap: () => setState(() => _uriExpanded = false),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: DebugTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: DebugTheme.surface(
                DebugTheme.backgroundDark,
                seeThrough: seeThrough,
              ),
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
                  label: compact ? 'Go' : 'Navigate',
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
                  label: compact ? 'Rep' : 'Replace',
                  icon: CupertinoIcons.arrow_swap,
                  color: DebugTheme.textPrimary,
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _replaceUri(_uriController.text),
                ),
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: ActionButton(
                  label: compact ? 'Rec' : 'Recover',
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
  problems('Problems', CupertinoIcons.exclamationmark_triangle),
  inspect('Inspect', CupertinoIcons.list_bullet),
  active('Active', CupertinoIcons.square_stack_3d_up),
  graph('Graph', CupertinoIcons.share_up),
  routes('Routes', CupertinoIcons.map);

  const _DebugTab(this.label, this.icon);

  final String label;
  final IconData icon;
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
  static const _headerDragHeight = 40.0;
  static const _headerActionsReserve = 120.0;

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
  Offset? _customTopLeft;
  bool _resizingPanel = false;
  bool _draggingPanel = false;
  Offset? _resizeStartPosition;
  Size? _resizeStartSize;
  Offset? _resizeStartTopLeft;
  Offset? _dragStartPointer;
  Offset? _dragStartTopLeft;

  @override
  void didUpdateWidget(_ResizableDebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maximized) {
      _resizingPanel = false;
      _draggingPanel = false;
      _resizeStartPosition = null;
      _resizeStartSize = null;
      _resizeStartTopLeft = null;
      _dragStartPointer = null;
      _dragStartTopLeft = null;
    }
    if (_customTopLeft != null) {
      _customTopLeft = _clampTopLeft(_customTopLeft!);
    }
  }

  Size get _panelSize {
    if (widget.maximized) return widget.availableSize;
    return _clampPanelSize(
      _customPanelSize ?? widget.defaultSize,
      widget.availableSize,
    );
  }

  Size get _freeSize {
    final panelSize = _panelSize;
    return Size(
      math.max(0.0, widget.availableSize.width - panelSize.width),
      math.max(0.0, widget.availableSize.height - panelSize.height),
    );
  }

  Offset get _topLeft {
    final free = _freeSize;
    // Default to bottom-right when the user has not dragged yet.
    return _clampTopLeft(_customTopLeft ?? Offset(free.width, free.height));
  }

  Offset _clampTopLeft(Offset requested) {
    final free = _freeSize;
    return Offset(
      requested.dx.clamp(0.0, free.width),
      requested.dy.clamp(0.0, free.height),
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
    // Pin the current origin so size changes keep the opposite corner fixed
    // instead of re-anchoring to bottom-right on every frame.
    _customTopLeft = _topLeft;
    _resizeStartPosition = details.globalPosition;
    _resizeStartSize = _panelSize;
    _resizeStartTopLeft = _customTopLeft;
    setState(() => _resizingPanel = true);
  }

  void _updatePanelResize(DragUpdateDetails details) {
    final startPosition = _resizeStartPosition;
    final startSize = _resizeStartSize;
    final startTopLeft = _resizeStartTopLeft;
    if (startPosition == null || startSize == null || startTopLeft == null) {
      return;
    }
    final delta = details.globalPosition - startPosition;
    final newSize = _clampPanelSize(
      Size(startSize.width - delta.dx, startSize.height - delta.dy),
      widget.availableSize,
    );
    // Top-left handle: keep the bottom-right corner fixed.
    final newTopLeft = Offset(
      startTopLeft.dx + startSize.width - newSize.width,
      startTopLeft.dy + startSize.height - newSize.height,
    );
    setState(() {
      _customPanelSize = newSize;
      _customTopLeft = _clampTopLeft(newTopLeft);
    });
  }

  void _endPanelResize() {
    if (!_resizingPanel) return;
    setState(() {
      _resizingPanel = false;
      _resizeStartPosition = null;
      _resizeStartSize = null;
      _resizeStartTopLeft = null;
    });
  }

  void _startPanelDrag(DragStartDetails details) {
    if (widget.maximized) return;
    _dragStartPointer = details.globalPosition;
    _dragStartTopLeft = _topLeft;
    setState(() => _draggingPanel = true);
  }

  void _updatePanelDrag(DragUpdateDetails details) {
    final startPointer = _dragStartPointer;
    final startTopLeft = _dragStartTopLeft;
    if (startPointer == null || startTopLeft == null) return;
    setState(() {
      _customTopLeft = _clampTopLeft(
        startTopLeft + (details.globalPosition - startPointer),
      );
    });
  }

  void _endPanelDrag() {
    if (!_draggingPanel) return;
    setState(() {
      _draggingPanel = false;
      _dragStartPointer = null;
      _dragStartTopLeft = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final panelSize = _panelSize;
    final topLeft = _topLeft;
    final animating = !_resizingPanel && !_draggingPanel;

    return Padding(
      padding: widget.margin,
      child: SizedBox(
        width: widget.availableSize.width,
        height: widget.availableSize.height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: topLeft.dx,
              top: topLeft.dy,
              width: panelSize.width,
              height: panelSize.height,
              child: AnimatedContainer(
                key: const ValueKey('zenrouter-debug-panel'),
                duration: animating
                    ? const Duration(milliseconds: 180)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                width: panelSize.width,
                height: panelSize.height,
                child: Stack(
                  children: [
                    Positioned.fill(child: widget.child),
                    if (!widget.maximized) ...[
                      Positioned(
                        // Leave the top-left resize grip exclusive hit target.
                        left: 32,
                        top: 0,
                        right: _ResizableDebugPanel._headerActionsReserve,
                        height: _ResizableDebugPanel._headerDragHeight,
                        child: _PanelDragHandle(
                          onPanStart: _startPanelDrag,
                          onPanUpdate: _updatePanelDrag,
                          onPanEnd: (_) => _endPanelDrag(),
                          onPanCancel: _endPanelDrag,
                        ),
                      ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelDragHandle extends StatelessWidget {
  const _PanelDragHandle({
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
    return Semantics(
      label: 'Move debug panel',
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: GestureDetector(
          key: const ValueKey('zenrouter-debug-panel-drag-handle'),
          dragStartBehavior: DragStartBehavior.down,
          behavior: HitTestBehavior.translucent,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          onPanCancel: onPanCancel,
          child: const SizedBox.expand(),
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

class _DebugFab extends StatelessWidget {
  const _DebugFab({super.key, required this.problems});

  final int problems;

  @override
  Widget build(BuildContext context) {
    return HitLayer(
      alignment: Alignment.center,
      hitChild: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: const SizedBox(width: 52, height: 52),
      ),
      paintChild: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: CountBadge(
          count: problems,
          child: Icon(
            CupertinoIcons.ant,
            color: const Color(0xFFE2E8F0),
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
              child: const SizedBox(width: 36, height: 36),
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
                color: _isHovered
                    ? const Color(0xFF383838)
                    : const Color(0x00000000),
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

      canvas.drawLine(
        const Offset(3.5, 9.0),
        const Offset(9.0, 3.5),
        glowPaint,
      );
      canvas.drawLine(
        const Offset(5.5, 14.0),
        const Offset(14.0, 5.5),
        glowPaint,
      );
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
                seeThrough: widget.coordinator.debugPanelSeeThroughForWidth(
                  MediaQuery.sizeOf(context).width,
                ),
                onSelectMode: (mode) {
                  _closeMenu();
                  if (mounted) setState(() {});
                  widget.coordinator.setDebugLayoutMode(mode);
                },
                onToggleSeeThrough: (enabled) {
                  _closeMenu();
                  if (mounted) setState(() {});
                  widget.coordinator.setDebugPanelSeeThrough(enabled);
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
    required this.seeThrough,
    required this.onSelectMode,
    required this.onToggleSeeThrough,
  });

  final DevToolsLayoutMode currentMode;
  final bool seeThrough;
  final ValueChanged<DevToolsLayoutMode> onSelectMode;
  final ValueChanged<bool> onToggleSeeThrough;

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
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                'APPEARANCE',
                style: TextStyle(
                  color: Color(0xFF737373),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            _ToolMenuItem(
              key: const ValueKey('zenrouter-debug-see-through'),
              icon: CupertinoIcons.circle_lefthalf_fill,
              label: 'See-through',
              isSelected: seeThrough,
              onTap: () => onToggleSeeThrough(!seeThrough),
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
                : (_isHovered
                      ? const Color(0xFF222222)
                      : const Color(0x00000000)),
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
