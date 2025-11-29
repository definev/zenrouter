import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// Mixin to add debug capabilities to a [Coordinator].
///
/// This adds a floating debug button that opens an overlay showing:
/// - Current navigation stacks for all paths
/// - Ability to push routes by URI
/// - Ability to push pre-defined debug routes
mixin CoordinatorDebug<T extends RouteUnique> on Coordinator<T> {
  /// Override this to provide a list of routes that can be quickly pushed
  /// from the debug overlay.
  List<T> get debugRoutes => [];

  /// Override this to provide a custom label for a navigation path.
  String debugLabel(NavigationPath path) {
    if (path == root) return 'Root Path';
    return 'Path ${paths.indexOf(path) + 1}';
  }

  bool _debugOverlayOpen = false;

  void toggleDebugOverlay() {
    _debugOverlayOpen = !_debugOverlayOpen;
    notifyListeners();
  }

  @override
  Widget rootBuilder(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Stack(
            children: [
              super.rootBuilder(context),
              _DebugOverlay(coordinator: this),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebugOverlay<T extends RouteUnique> extends StatefulWidget {
  const _DebugOverlay({required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  State<_DebugOverlay<T>> createState() => _DebugOverlayState<T>();
}

class _DebugOverlayState<T extends RouteUnique>
    extends State<_DebugOverlay<T>> {
  final TextEditingController _uriController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.coordinator._debugOverlayOpen) {
      return Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
          onPressed: widget.coordinator.toggleDebugOverlay,
          child: const Icon(Icons.bug_report, size: 20),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final width = isMobile ? constraints.maxWidth : 420.0;
        final height = isMobile ? 400.0 : 500.0;
        final bottom = isMobile ? 0.0 : 16.0;
        final right = isMobile ? 0.0 : 16.0;

        return Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: height,
            width: width,
            padding: EdgeInsets.only(bottom: bottom, right: right),
            child: Material(
              color: Colors.transparent,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(isMobile ? 0 : 12),
                  border: Border.all(color: const Color(0xFF333333)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    const Divider(height: 1, color: Color(0xFF333333)),
                    _buildTabBar(),
                    const Divider(height: 1, color: Color(0xFF333333)),
                    Expanded(
                      child: _selectedTabIndex == 0
                          ? _buildPathList()
                          : _buildDebugRoutesList(),
                    ),
                    const Divider(height: 1, color: Color(0xFF333333)),
                    _buildInputArea(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF111111),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ZenRouter Debugger',
                style: TextStyle(
                  color: Color(0xFFEDEDED),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF666666), size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: widget.coordinator.toggleDebugOverlay,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 36,
      color: const Color(0xFF0A0A0A),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Inspect',
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFF333333)),
          Expanded(
            child: _TabButton(
              label: 'Routes',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathList() {
    return ListenableBuilder(
      listenable: widget.coordinator,
      builder: (context, _) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: widget.coordinator.paths.length,
          itemBuilder: (context, index) {
            final path = widget.coordinator.paths[index];
            final isActive = path == widget.coordinator.activePath;

            return Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF222222))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 8,
                      top: 8,
                      bottom: 8,
                    ),
                    color: isActive
                        ? const Color(0xFF1A1A1A)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_open,
                          color: isActive
                              ? const Color(0xFFEDEDED)
                              : const Color(0xFF666666),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                widget.coordinator.debugLabel(path),
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFFEDEDED)
                                      : const Color(0xFF888888),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (path.stack.isNotEmpty)
                          _SmallIconButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Pop Route',
                            onTap: path.stack.length > 1
                                ? () => path.pop()
                                : null,
                            color: path.stack.length > 1
                                ? const Color(0xFFEDEDED)
                                : const Color(0xFF666666),
                          ),
                      ],
                    ),
                  ),
                  if (path.stack.isNotEmpty)
                    ...path.stack.reversed.indexed.map((data) {
                      final (index, route) = data;
                      final isTop = index == 0;
                      final isRouteActive = isActive && isTop;

                      return Container(
                        padding: const EdgeInsets.only(
                          left: 34,
                          right: 8,
                          top: 6,
                          bottom: 6,
                        ),
                        color: isTop ? const Color(0xFF111111) : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      route.toString(),
                                      style: TextStyle(
                                        color: isTop
                                            ? const Color(0xFFEDEDED)
                                            : const Color(0xFF999999),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        fontWeight: isTop
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isRouteActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            _SmallIconButton(
                              icon: Icons.close,
                              tooltip: 'Remove Route',
                              onTap: path.stack.length > 1
                                  ? () => path.remove(route)
                                  : null,
                              color: Colors.red[200],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDebugRoutesList() {
    if (widget.coordinator.debugRoutes.isEmpty) {
      return const Center(
        child: Text(
          'No debug routes defined.\nOverride debugRoutes in your coordinator.',
          style: TextStyle(color: Color(0xFF666666), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: widget.coordinator.debugRoutes.length,
      itemBuilder: (context, index) {
        final route = widget.coordinator.debugRoutes[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF222222))),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.subdirectory_arrow_right,
                color: Color(0xFF444444),
                size: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: route.toString(),
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    children: [
                      TextSpan(
                        text:
                            ''' ${() {
                              try {
                                return route.toUri().toString();
                              } catch (e) {
                                return 'null';
                              }
                            }()}''',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _SmallIconButton(
                icon: Icons.add,
                tooltip: 'Push',
                onTap: () {
                  widget.coordinator.push(route);
                  _showToast('Pushed $route');
                },
              ),
              const SizedBox(width: 8),
              _SmallIconButton(
                icon: Icons.swap_horiz,
                tooltip: 'Replace',
                onTap: () {
                  widget.coordinator.replace(route);
                  _showToast('Replaced with $route');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _uriController,
                    style: const TextStyle(
                      color: Color(0xFFEDEDED),
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      hintText: '/path...',
                      hintStyle: TextStyle(color: Color(0xFF444444)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: _pushUri,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Push',
                  color: const Color(0xFFEDEDED),
                  backgroundColor: const Color(0xFF222222),
                  onTap: () => _pushUri(_uriController.text),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Replace',
                  color: const Color(0xFF888888),
                  backgroundColor: const Color(0xFF111111),
                  onTap: () => _replaceUri(_uriController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _pushUri(String uriString) {
    if (uriString.isEmpty) return;
    try {
      final uri = Uri.parse(uriString);
      widget.coordinator.recoverRouteFromUri(uri);
      _showToast('Navigated to $uriString');
    } catch (e) {
      _showToast('Error: $e', isError: true);
    }
  }

  void _replaceUri(String uriString) {
    if (uriString.isEmpty) return;
    try {
      final uri = Uri.parse(uriString);
      final route = widget.coordinator.parseRouteFromUri(uri);
      widget.coordinator.replace(route);
      _showToast('Replaced with $uriString');
    } catch (e) {
      _showToast('Error: $e', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? Colors.red[200] : const Color(0xFFEDEDED),
          ),
        ),
        backgroundColor: const Color(0xFF111111),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF333333)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
          border: isSelected
              ? const Border(bottom: BorderSide(color: Colors.white, width: 2))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFEDEDED)
                : const Color(0xFF666666),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF333333)),
            borderRadius: BorderRadius.circular(4),
            color: const Color(0xFF111111),
          ),
          child: Icon(
            icon,
            size: 12,
            color: onTap != null
                ? (color ?? const Color(0xFFEDEDED))
                : const Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF333333)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
