import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

import '../coordinator_debug.dart';
import '../widgets/badges.dart';
import '../widgets/buttons.dart';
import '../widgets/debug_theme.dart';

class PathListView<T extends RouteUnique> extends StatelessWidget {
  const PathListView({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  Widget build(BuildContext context) {
    final groupedPaths = <Coordinator?, List<StackPath>>{};
    for (final path in coordinator.paths) {
      final key = path.proxyCoordinator;
      if (!groupedPaths.containsKey(key)) {
        groupedPaths[key] = [];
      }
      groupedPaths[key]!.add(path);
    }

    // Sort to ensure root (null) or specific order if needed.
    // Putting null (Root) first usually makes sense.
    final sortedKeys =
        groupedPaths.keys.toList()..sort((a, b) {
          if (a == null) return -1;
          if (b == null) return 1;
          return a.runtimeType.toString().compareTo(b.runtimeType.toString());
        });

    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        return _PathTabs<T>(
          coordinator: coordinator,
          groupedPaths: groupedPaths,
          sortedKeys: sortedKeys,
        );
      },
    );
  }
}

class _PathTabs<T extends RouteUnique> extends StatefulWidget {
  const _PathTabs({
    required this.coordinator,
    required this.groupedPaths,
    required this.sortedKeys,
  });

  final CoordinatorDebug<T> coordinator;
  final Map<Coordinator?, List<StackPath>> groupedPaths;
  final List<Coordinator?> sortedKeys;

  @override
  State<_PathTabs<T>> createState() => _PathTabsState<T>();
}

class _PathTabsState<T extends RouteUnique> extends State<_PathTabs<T>> {
  late PageController _pageController;
  int _selectedIndex = 0;
  StackPath? _lastActivePath;
  List<GlobalKey> _tabKeys = [];

  @override
  void initState() {
    super.initState();
    _updateTabKeys();
    _lastActivePath = widget.coordinator.activeLayoutPaths.lastOrNull;

    int initialIndex = 0;
    if (_lastActivePath != null) {
      final key = _lastActivePath!.proxyCoordinator;
      final index = widget.sortedKeys.indexOf(key);
      if (index != -1) initialIndex = index;
    }

    _selectedIndex = initialIndex;
    _pageController = PageController(initialPage: initialIndex);

    // Ensure initial tab is visible after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureTabVisible(initialIndex);
    });
  }

  @override
  void didUpdateWidget(_PathTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sortedKeys.length != oldWidget.sortedKeys.length) {
      _updateTabKeys();
    }

    final newActivePath = widget.coordinator.activeLayoutPaths.lastOrNull;
    if (newActivePath != _lastActivePath) {
      _lastActivePath = newActivePath;
      _syncWithActivePath();
    }
  }

  void _updateTabKeys() {
    if (_tabKeys.length != widget.sortedKeys.length) {
      _tabKeys = List.generate(widget.sortedKeys.length, (_) => GlobalKey());
    }
  }

  void _ensureTabVisible(int index) {
    if (index < 0 || index >= _tabKeys.length) return;

    final context = _tabKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5, // Center the tab
      );
    }
  }

  void _syncWithActivePath() {
    final activePath = _lastActivePath;
    if (activePath == null) return;

    final key = activePath.proxyCoordinator;
    final index = widget.sortedKeys.indexOf(key);

    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _ensureTabVisible(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sortedKeys.isEmpty) {
      return const Center(
        child: Text(
          'No paths found',
          style: TextStyle(color: DebugTheme.textDisabled),
        ),
      );
    }

    return Column(
      children: [
        LayoutBuilder(
          builder:
              (context, constraints) => Container(
                width: constraints.maxWidth,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: DebugTheme.borderDark),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < widget.sortedKeys.length; i++)
                        _TabButton(
                          key: _tabKeys[i],
                          label:
                              widget.sortedKeys[i]?.toString() ??
                              widget.coordinator.toString(),
                          isSelected: i == _selectedIndex,
                          onTap: () {
                            setState(() {
                              _selectedIndex = i;
                            });
                            _pageController.jumpToPage(i);
                            _ensureTabVisible(i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.sortedKeys.length,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _ensureTabVisible(index);
            },
            itemBuilder: (context, index) {
              final key = widget.sortedKeys[index];
              final paths = widget.groupedPaths[key]!;
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: paths.length,
                itemBuilder: (context, pathIndex) {
                  final path = paths[pathIndex];
                  final isActiveLayout = widget.coordinator.activeLayoutPaths
                      .contains(path);
                  final isActive =
                      path == widget.coordinator.activeLayoutPaths.last;

                  final isReadOnly = path is IndexedStackPath;

                  return _PathItemView<T>(
                    coordinator: widget.coordinator,
                    path: path,
                    isActiveLayout: isActiveLayout,
                    isActive: isActive,
                    isReadOnly: isReadOnly,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DebugTheme.spacingMd,
          vertical: DebugTheme.spacing,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isSelected ? DebugTheme.textPrimary : const Color(0x00000000),
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? DebugTheme.textPrimary : DebugTheme.textDisabled,
            fontSize: DebugTheme.fontSizeXs,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PathItemView<T extends RouteUnique> extends StatelessWidget {
  const _PathItemView({
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.isReadOnly,
    required this.isActiveLayout,
  });

  final CoordinatorDebug<T> coordinator;
  final StackPath path;
  final bool isActive;
  final bool isReadOnly;
  final bool isActiveLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPathHeader(),
          if (path.stack.isEmpty)
            Container(
              height: 52,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: DebugTheme.borderDark)),
              ),
              child: Center(
                child: Text(
                  'No active route in this path',
                  style: TextStyle(
                    color: DebugTheme.textDisabled,
                    fontSize: DebugTheme.fontSizeSm,
                  ),
                ),
              ),
            ),
          if (path.stack.isNotEmpty) ..._buildRouteItems(),
        ],
      ),
    );
  }

  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.only(
        left: DebugTheme.spacing,
        right: DebugTheme.spacing,
        top: DebugTheme.spacing,
        bottom: DebugTheme.spacing,
      ),
      color: isActive ? DebugTheme.backgroundLight : const Color(0x00000000),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coordinator.debugLabel(path),
                        style: TextStyle(
                          color:
                              isActive
                                  ? DebugTheme.textPrimary
                                  : DebugTheme.textMuted,
                          fontSize: DebugTheme.fontSizeMd,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      Text(
                        path.pathKey.key,
                        style: TextStyle(
                          color: DebugTheme.textMuted,
                          fontSize: DebugTheme.fontSizeSm,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.normal,
                          decoration: TextDecoration.none,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: DebugTheme.spacing),
                  const ActiveBadge(),
                ],
                const SizedBox(width: DebugTheme.spacing),
              ],
            ),
          ),
          // Only show pop button for non-read-only paths
          if (path.stack.isNotEmpty && path is NavigationPath)
            SmallIconButton(
              icon: CupertinoIcons.arrow_left,
              onTap:
                  path.stack.length > 1
                      ? () async {
                        await (path as NavigationPath).pop();
                      }
                      : null,
              color:
                  path.stack.length > 1
                      ? DebugTheme.textPrimary
                      : DebugTheme.textDisabled,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRouteItems() {
    if (isReadOnly && path is IndexedStackPath) {
      final indexedPath = path as IndexedStackPath;
      return path.stack.indexed.map((data) {
        final (routeIndex, route) = data;
        final isRouteActive =
            (isActive || isActiveLayout) &&
            routeIndex == indexedPath.activeIndex;

        return _ReadOnlyRouteItem(
          route: route as RouteUnique,
          routeIndex: routeIndex,
          isRouteActive: isRouteActive,
          readOnlyPath: indexedPath,
        );
      }).toList();
    }

    return path.stack.reversed.indexed.map((data) {
      final (index, route) = data;
      final isTop = index == 0;
      final isRouteActive = isActive && isTop;

      return _NavigationRouteItem(
        route: route as RouteUnique,
        isTop: isTop,
        isRouteActive: isRouteActive,
        path: path,
      );
    }).toList();
  }
}

class _ReadOnlyRouteItem extends StatefulWidget {
  const _ReadOnlyRouteItem({
    required this.route,
    required this.routeIndex,
    required this.isRouteActive,
    required this.readOnlyPath,
  });

  final RouteUnique route;
  final int routeIndex;
  final bool isRouteActive;
  final IndexedStackPath readOnlyPath;

  @override
  State<_ReadOnlyRouteItem> createState() => _ReadOnlyRouteItemState();
}

class _ReadOnlyRouteItemState extends State<_ReadOnlyRouteItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          await widget.readOnlyPath.goToIndexed(widget.routeIndex);
        },
        child: Container(
          padding: const EdgeInsets.only(
            left: DebugTheme.spacing,
            right: DebugTheme.spacing,
            top: DebugTheme.spacingSm,
            bottom: DebugTheme.spacingSm,
          ),
          color:
              widget.isRouteActive || _isHovered
                  ? DebugTheme.backgroundDark
                  : const Color(0x00000000),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.route.toString(),
                      style: TextStyle(
                        color:
                            widget.isRouteActive
                                ? DebugTheme.textPrimary
                                : DebugTheme.textSecondary,
                        fontSize: DebugTheme.fontSize,
                        fontWeight:
                            widget.isRouteActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.route.toUri().toString(),
                      style: TextStyle(
                        color: DebugTheme.textMuted,
                        fontSize: DebugTheme.fontSizeSm,
                        fontFamily: 'monospace',
                        fontWeight:
                            widget.isRouteActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                widget.isRouteActive
                    ? CupertinoIcons.circle_fill
                    : CupertinoIcons.circle,
                size: 16,
                color:
                    widget.isRouteActive
                        ? const Color(0xFF2196F3)
                        : DebugTheme.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationRouteItem extends StatelessWidget {
  const _NavigationRouteItem({
    required this.route,
    required this.isTop,
    required this.isRouteActive,
    required this.path,
  });

  final RouteUnique route;
  final bool isTop;
  final bool isRouteActive;
  final StackPath path;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: DebugTheme.spacing,
        right: DebugTheme.spacing,
        top: DebugTheme.spacingSm,
        bottom: DebugTheme.spacingSm,
      ),
      color: isTop ? DebugTheme.backgroundDark : const Color(0x00000000),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.toString(),
                        style: TextStyle(
                          color:
                              isTop
                                  ? DebugTheme.textPrimary
                                  : DebugTheme.textSecondary,
                          fontSize: DebugTheme.fontSize,
                          fontFamily: 'monospace',
                          fontWeight:
                              isTop ? FontWeight.w600 : FontWeight.normal,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (route is! RouteLayout)
                        Text(
                          route.toUri().toString(),
                          style: TextStyle(
                            color: DebugTheme.textMuted,
                            fontSize: DebugTheme.fontSizeSm,
                            fontFamily: 'monospace',
                            fontWeight:
                                isTop ? FontWeight.w600 : FontWeight.normal,
                            decoration: TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (route is RouteLayout) ...[const LayoutBadge()],
                if (isRouteActive) ...[
                  const SizedBox(width: DebugTheme.spacing),
                  const ActiveIndicator(),
                ],
                const SizedBox(width: DebugTheme.spacing),
              ],
            ),
          ),
          if (path case StackMutatable path)
            SmallIconButton(
              icon: CupertinoIcons.xmark,
              onTap: path.stack.length > 1 ? () => path.remove(route) : null,
              color: const Color(0xFFEF9A9A),
            ),
        ],
      ),
    );
  }
}
