import 'package:flutter/widgets.dart';

import 'debug_theme.dart';

// =============================================================================
// STATUS BADGES
// =============================================================================

/// A badge indicating the "active" status of a path or route.
class ActiveBadge extends StatelessWidget {
  const ActiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: DebugTheme.fontSizeXs,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// A badge indicating a layout route.
class LayoutBadge extends StatelessWidget {
  const LayoutBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF9C27B0).withAlpha(100),
        borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
      ),
      child: const Text(
        'LAYOUT',
        style: TextStyle(
          color: Color(0xFF9C27B0),
          fontSize: DebugTheme.fontSizeXs,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// A small indicator dot showing active status.
class ActiveIndicator extends StatelessWidget {
  const ActiveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A small indicator dot showing connection status.
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key, this.isConnected = true});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A badge that shows a count on top of an icon.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFF44336),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
