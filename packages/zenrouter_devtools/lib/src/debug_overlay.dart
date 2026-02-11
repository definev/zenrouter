import 'package:flutter/cupertino.dart';
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
  final TextEditingController _uriController = TextEditingController();

  // 0: Inspect, 1: Routes
  int _selectedTabIndex = 0;

  void _handleUriChanged() {
    final newPath = widget.coordinator.currentUri.toString();
    if (newPath != _uriController.text) {
      _uriController.text = newPath;
    }
  }

  @override
  void initState() {
    super.initState();
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
    return Align(
      alignment: Alignment.bottomRight,
      child: SafeArea(
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.all(DebugTheme.spacingLg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ListenableBuilder(
                  listenable: _uriController,
                  builder:
                      (context, child) => Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF000000).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(
                              DebugTheme.radiusFull,
                            ),
                          ),
                          height: 40,
                          margin: const EdgeInsets.only(
                            right: DebugTheme.spacingXs,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DebugTheme.spacingMd,
                          ),
                          child: Center(
                            child: Text(
                              _uriController.text,
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                decoration: TextDecoration.none,
                                fontWeight: FontWeight.normal,
                                fontSize: DebugTheme.fontSizeMd,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                ),
                _DebugFab(
                  problems: widget.coordinator.problems,
                  onTap: widget.coordinator.toggleDebugOverlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EXPANDED VIEW
  // ===========================================================================

  Widget _buildExpandedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final width = isMobile ? constraints.maxWidth : 420.0;
        final height = isMobile ? 400.0 : 500.0;
        final bottom = isMobile ? 0.0 : 16.0;
        final horizontal = isMobile ? 0.0 : 16.0;

        return Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: height,
            width: width,
            padding: EdgeInsets.only(
              bottom: bottom,
              right: horizontal,
              left: horizontal,
            ),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: DebugTheme.background,
                borderRadius: BorderRadius.circular(
                  isMobile ? 0 : DebugTheme.radiusLg,
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
                    child: switch (_selectedTabIndex) {
                      0 => ProblemsTab<T>(coordinator: widget.coordinator),
                      1 => PathListView<T>(coordinator: widget.coordinator),
                      2 => ActiveLayoutsListView<T>(
                        coordinator: widget.coordinator,
                      ),
                      _ => DebugRoutesListView<T>(
                        coordinator: widget.coordinator,
                      ),
                    },
                  ),
                  const _Divider(),
                  _buildInputArea(),
                ],
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              SizedBox(width: DebugTheme.spacing),
              ConnectionIndicator(),
              SizedBox(width: DebugTheme.spacing),
              Text(
                'ZenRouter Devtools',
                style: TextStyle(
                  color: DebugTheme.textPrimary,
                  fontSize: DebugTheme.fontSizeLg,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.coordinator.toggleDebugOverlay,
            child: Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              color: DebugTheme.backgroundDark,
              margin: EdgeInsets.only(right: DebugTheme.spacing),
              child: const Icon(
                CupertinoIcons.xmark,
                color: DebugTheme.textDisabled,
                size: 16,
              ),
            ),
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
          Expanded(
            child: TabButton(
              label: 'Problems',
              count: widget.coordinator.problems,
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: TabButton(
              label: 'Inspect',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: TabButton(
              label: 'Active',
              isSelected: _selectedTabIndex == 2,
              onTap: () => setState(() => _selectedTabIndex = 2),
            ),
          ),
          if (widget.coordinator.debugRoutes.isNotEmpty) ...[
            const _VerticalDivider(),
            Expanded(
              child: TabButton(
                label: 'Routes',
                isSelected: _selectedTabIndex == 3,
                onTap: () => setState(() => _selectedTabIndex = 3),
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

// =============================================================================
// DEBUG FAB (Custom, no Material)
// =============================================================================

class _DebugFab extends StatefulWidget {
  const _DebugFab({required this.problems, required this.onTap});

  final int problems;
  final VoidCallback onTap;

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                _isHovered ? const Color(0xFF222222) : const Color(0xFF000000),
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
