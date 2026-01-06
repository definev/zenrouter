/// A breadcrumb navigation widget for displaying hierarchical navigation paths.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';

/// Represents a single breadcrumb item in the navigation path.
class BreadcrumbItem {
  const BreadcrumbItem({required this.label, this.route});

  /// The display label for this breadcrumb segment
  final String label;

  /// Optional route to navigate to when clicked. If null, segment is not clickable.
  final DocsRoute? route;
}

/// A breadcrumb navigation widget that displays a hierarchical path.
///
/// Shows clickable segments separated by '/' characters. Non-clickable segments
/// (those without a route) are displayed in a muted color.
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.items});

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final coordinator = DocsCoordinatorProvider.of(context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _BreadcrumbSegment(
            item: items[i],
            coordinator: coordinator,
            isLast: i == items.length - 1,
          ),
          if (i < items.length - 1)
            Text(
              '/',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ],
    );
  }
}

/// A single segment in the breadcrumb navigation.
class _BreadcrumbSegment extends StatefulWidget {
  const _BreadcrumbSegment({
    required this.item,
    required this.coordinator,
    required this.isLast,
  });

  final BreadcrumbItem item;
  final DocsCoordinator coordinator;
  final bool isLast;

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClickable = widget.item.route != null && !widget.isLast;

    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: widget.isLast
          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
          : _isHovered && isClickable
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withValues(alpha: 0.8),
      fontWeight: widget.isLast ? FontWeight.normal : FontWeight.w500,
    );

    if (!isClickable) {
      return Text(widget.item.label, style: textStyle);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.item.route != null) {
            widget.coordinator.navigate(widget.item.route!);
          }
        },
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: textStyle ?? const TextStyle(),
          child: Text(widget.item.label),
        ),
      ),
    );
  }
}
