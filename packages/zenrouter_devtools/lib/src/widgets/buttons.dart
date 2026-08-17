import 'package:flutter/widgets.dart';

import 'debug_theme.dart';

// =============================================================================
// SMALL ICON BUTTON
// =============================================================================

/// A small icon button used in the debug overlay for actions like
/// pop, remove, and navigation.
class SmallIconButton extends StatefulWidget {
  const SmallIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<SmallIconButton> createState() => _SmallIconButtonState();
}

class _SmallIconButtonState extends State<SmallIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: DebugTheme.border),
            borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
            color: _isHovered && widget.onTap != null
                ? DebugTheme.backgroundLight
                : DebugTheme.backgroundDark,
          ),
          child: Icon(
            widget.icon,
            size: 11,
            color: widget.onTap != null
                ? (widget.color ?? DebugTheme.textPrimary)
                : DebugTheme.textPlaceholder,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ACTION BUTTON
// =============================================================================

/// A styled action button used for Push, Replace, and Recover actions.
class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered
                ? DebugTheme.backgroundLight
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(DebugTheme.radius),
            border: Border.all(color: DebugTheme.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: DebugTheme.fontSize,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: DebugTheme.spacingXs),
                Icon(widget.icon, color: widget.color, size: 11),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB BUTTON
// =============================================================================

/// A tab button used in the debug overlay's tab bar.
class TabButton extends StatefulWidget {
  const TabButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count = 0,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  @override
  State<TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected || _isHovered
                ? DebugTheme.backgroundLight
                : const Color(0x00000000),
            border: widget.isSelected
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFFFFFFF), width: 2),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? DebugTheme.textPrimary
                      : DebugTheme.textDisabled,
                  fontSize: DebugTheme.fontSizeMd,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              if (widget.count > 0) ...[
                const SizedBox(width: DebugTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DebugTheme.spacingXs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withAlpha(150),
                    borderRadius: BorderRadius.circular(DebugTheme.radiusSm),
                  ),
                  child: Text(
                    widget.count.toString(),
                    style: const TextStyle(
                      color: Color(0xFFFFCDD2),
                      fontSize: DebugTheme.fontSizeSm,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
