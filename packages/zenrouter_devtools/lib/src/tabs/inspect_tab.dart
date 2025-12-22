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
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: coordinator.paths.length,
          itemBuilder: (context, index) {
            final path = coordinator.paths[index];
            final isActive = path == coordinator.activeLayoutPaths.last;
            final isReadOnly = path is IndexedStackPath;

            return _PathItemView<T>(
              coordinator: coordinator,
              path: path,
              isActive: isActive,
              isReadOnly: isReadOnly,
            );
          },
        );
      },
    );
  }
}

class _PathItemView<T extends RouteUnique> extends StatelessWidget {
  const _PathItemView({
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.isReadOnly,
  });

  final CoordinatorDebug<T> coordinator;
  final StackPath path;
  final bool isActive;
  final bool isReadOnly;

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
          if (path.stack.isNotEmpty) ..._buildRouteItems(),
        ],
      ),
    );
  }

  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.only(
        left: DebugTheme.spacingMd,
        right: DebugTheme.spacing,
        top: DebugTheme.spacing,
        bottom: DebugTheme.spacing,
      ),
      color: isActive ? DebugTheme.backgroundLight : const Color(0x00000000),
      child: Row(
        children: [
          Icon(
            isReadOnly ? CupertinoIcons.lock : CupertinoIcons.folder_open,
            color: isActive ? DebugTheme.textPrimary : DebugTheme.textDisabled,
            size: 14,
          ),
          const SizedBox(width: DebugTheme.spacing),
          Expanded(
            child: Row(
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
                if (isActive) ...[
                  const SizedBox(width: DebugTheme.spacing),
                  const ActiveBadge(),
                ],
                if (isReadOnly) ...[const Spacer(), const StatefulBadge()],
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
        final isRouteActive = isActive && routeIndex == indexedPath.activeIndex;

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
            left: 34,
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
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
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
                    ),
                    if (widget.isRouteActive) ...[
                      const SizedBox(width: DebugTheme.spacing),
                      const ActiveIndicator(),
                    ],
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
        left: 34,
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
                Flexible(
                  child: Text(
                    route.toString(),
                    style: TextStyle(
                      color:
                          isTop
                              ? DebugTheme.textPrimary
                              : DebugTheme.textSecondary,
                      fontSize: DebugTheme.fontSize,
                      fontFamily: 'monospace',
                      fontWeight: isTop ? FontWeight.w600 : FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRouteActive) ...[
                  const SizedBox(width: DebugTheme.spacing),
                  const ActiveIndicator(),
                ],
              ],
            ),
          ),
          if (path is NavigationPath)
            SmallIconButton(
              icon: CupertinoIcons.xmark,
              onTap:
                  path.stack.length > 1
                      ? () {
                        (path as NavigationPath).remove(route);
                      }
                      : null,
              color: const Color(0xFFEF9A9A),
            ),
        ],
      ),
    );
  }
}
