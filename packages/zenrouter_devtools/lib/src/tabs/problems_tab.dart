import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/src/widgets/debug_theme.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

class ProblemsTab<T extends RouteUnique> extends StatelessWidget {
  const ProblemsTab({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  Widget build(BuildContext context) {
    // 1. Get all paths known to coordinator (excluding root)
    final userPaths =
        coordinator.paths.where((p) => p != coordinator.root).toSet();

    // 2. Instantiate all registered layouts
    final layouts =
        coordinator.layoutParentConstructorTable.entries
            .map((entry) => entry.value(entry.key) as RouteLayout)
            .toList();

    // 3. Map paths to the layouts that claim them
    final pathLayoutMap = <StackPath, List<RouteLayout>>{};
    for (final layout in layouts) {
      final path = layout.resolvePath(coordinator);
      pathLayoutMap.putIfAbsent(path, () => []).add(layout);
    }

    final problems = <Widget>[];

    // CHECK 1: Duplicated Paths (Multiple layouts claim the same path)
    pathLayoutMap.forEach((path, layouts) {
      if (layouts.length > 1) {
        problems.add(
          _LayoutProblem(
            path: path,
            type: _LayoutProblemType.duplicatedPath,
            relatedLayouts: layouts,
            coordinator: coordinator,
          ),
        );
      }
    });

    // CHECK 2: Layout Missing (Path exists in coordinator but no layout claims it)
    for (final path in userPaths) {
      if (!pathLayoutMap.containsKey(path)) {
        problems.add(
          _LayoutProblem(
            path: path,
            type: _LayoutProblemType.missingLayout,
            coordinator: coordinator,
          ),
        );
      }
    }

    // CHECK 3: Unknown Path (Layout claims a path not in coordinator)
    for (final path in pathLayoutMap.keys) {
      if (!userPaths.contains(path) && path != coordinator.root) {
        problems.add(
          _LayoutProblem(
            path: path,
            type: _LayoutProblemType.unknownPath,
            coordinator: coordinator,
          ),
        );
      }
    }

    if (problems.isEmpty) {
      return const Center(
        child: Text(
          'No problems found.',
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
      itemCount: problems.length,
      itemBuilder: (context, index) {
        return problems[index];
      },
    );
  }
}

enum _LayoutProblemType { missingLayout, duplicatedPath, unknownPath }

class _LayoutProblem extends StatelessWidget {
  const _LayoutProblem({
    required this.path,
    required this.type,
    required this.coordinator,
    this.relatedLayouts = const [],
  });

  final StackPath path;
  final _LayoutProblemType type;
  final CoordinatorDebug coordinator;
  final List<RouteLayout> relatedLayouts;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color:
                type == _LayoutProblemType.duplicatedPath
                    ? const Color(0xFFEF5350) // Red for duplicate (critical)
                    : const Color(0xFFE85600), // Orange for others
            size: 16,
          ),
          const SizedBox(width: DebugTheme.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (type) {
                    _LayoutProblemType.missingLayout => 'Layout Missing',
                    _LayoutProblemType.duplicatedPath => 'Duplicated Layouts',
                    _LayoutProblemType.unknownPath => 'Unknown Path',
                  },
                  style: const TextStyle(
                    color: DebugTheme.textPrimary,
                    fontSize: DebugTheme.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                _buildMessage(),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    text: 'Path: ',
                    style: const TextStyle(
                      color: DebugTheme.textMuted,
                      fontSize: DebugTheme.fontSize,
                      decoration: TextDecoration.none,
                    ),
                    children: [_codeSpan(coordinator.debugLabel(path))],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    switch (type) {
      case _LayoutProblemType.missingLayout:
        return Text.rich(
          TextSpan(
            text: 'Forget to bind layout, you must use ',
            style: const TextStyle(
              color: DebugTheme.textSecondary,
              fontSize: DebugTheme.fontSize,
              decoration: TextDecoration.none,
            ),
            children: [
              _codeSpan('defineLayout'),
              const TextSpan(text: ' to define associated '),
              _codeSpan('RouteLayout'),
              const TextSpan(text: ' that owns '),
              _codeSpan(path.toString()),
            ],
          ),
        );
      case _LayoutProblemType.duplicatedPath:
        final layoutNames = relatedLayouts
            .map((l) => l.runtimeType.toString())
            .join(', ');
        return Text.rich(
          TextSpan(
            text: 'Multiple layouts are claiming the same path ',
            style: const TextStyle(
              color: DebugTheme.textSecondary,
              fontSize: DebugTheme.fontSize,
              decoration: TextDecoration.none,
            ),
            children: [
              _codeSpan(path.toString()),
              const TextSpan(text: '. Layouts found: '),
              _codeSpan(layoutNames),
            ],
          ),
        );
      case _LayoutProblemType.unknownPath:
        return Text.rich(
          TextSpan(
            text: 'Layout maps to path ',
            style: const TextStyle(
              color: DebugTheme.textSecondary,
              fontSize: DebugTheme.fontSize,
              decoration: TextDecoration.none,
            ),
            children: [
              _codeSpan(path.toString()),
              const TextSpan(text: ' but this path is not registered in '),
              _codeSpan('AppCoordinator.paths'),
            ],
          ),
        );
    }
  }

  TextSpan _codeSpan(String text) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        color: DebugTheme.textPrimary,
        backgroundColor: Color(0xFF333333),
        fontFamily: 'monospace',
      ),
    );
  }
}
