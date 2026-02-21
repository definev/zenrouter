import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

import '../coordinator_debug.dart';
import '../widgets/badges.dart';
import '../widgets/debug_theme.dart';

class ActiveLayoutsListView<T extends RouteUnique> extends StatelessWidget {
  const ActiveLayoutsListView({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final activeLayouts = coordinator.activeLayouts;
        final activeLayoutPaths = coordinator.activePaths;

        if (activeLayouts.isEmpty) {
          return const Center(
            child: Text(
              'No active layouts.\nRoot path is the current active path.',
              style: TextStyle(
                color: DebugTheme.textDisabled,
                fontSize: DebugTheme.fontSizeMd,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: DebugTheme.spacingXs),
          itemCount: activeLayouts.length,
          itemBuilder: (context, index) {
            final layout = activeLayouts[index];
            // activeLayoutPaths[0] is root, so layout at index 0 corresponds to path at index 1
            final path = activeLayoutPaths[index + 1];
            final isDeepest = index == activeLayouts.length - 1;

            return ActiveLayoutItem(
              layout: layout,
              path: path,
              depth: index,
              isDeepest: isDeepest,
            );
          },
        );
      },
    );
  }
}

class ActiveLayoutItem extends StatelessWidget {
  const ActiveLayoutItem({
    super.key,
    required this.layout,
    required this.path,
    required this.depth,
    required this.isDeepest,
  });

  final RouteLayout layout;
  final StackPath path;
  final int depth;
  final bool isDeepest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingMd,
        vertical: DebugTheme.spacing,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Layout info row
          Row(
            children: [
              // Depth indicator
              ...List.generate(
                depth,
                (_) => Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.only(right: DebugTheme.spacing),
                  color: DebugTheme.border,
                ),
              ),
              Icon(
                isDeepest
                    ? CupertinoIcons.layers_alt_fill
                    : CupertinoIcons.layers_alt,
                color:
                    isDeepest
                        ? const Color(0xFF2196F3)
                        : DebugTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: DebugTheme.spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          layout.runtimeType.toString(),
                          style: TextStyle(
                            color:
                                isDeepest
                                    ? DebugTheme.textPrimary
                                    : DebugTheme.textSecondary,
                            fontSize: DebugTheme.fontSizeMd,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (isDeepest) ...[
                          const SizedBox(width: DebugTheme.spacing),
                          const ActiveBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Path: ${path.runtimeType}',
                      style: const TextStyle(
                        color: DebugTheme.textMuted,
                        fontSize: DebugTheme.fontSize,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Active route in this path
          if (path.activeRoute != null)
            Padding(
              padding: EdgeInsets.only(
                left: (depth * (2 + DebugTheme.spacing)) + 24,
                top: DebugTheme.spacingSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_turn_down_right,
                    color: DebugTheme.textDisabled,
                    size: 12,
                  ),
                  const SizedBox(width: DebugTheme.spacingXs),
                  Expanded(
                    child: Text(
                      path.activeRoute.toString(),
                      style: const TextStyle(
                        color: DebugTheme.textSecondary,
                        fontSize: DebugTheme.fontSize,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
