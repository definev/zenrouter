/// # Section Layout Widget
///
/// Each major section of our documentation (Paradigms, Concepts, Patterns,
/// File Routing) shares a common layout: a navigation rail on the left
/// showing the pages within that section, and a content area on the right.
///
/// This widget provides that structure, while each section's `_layout.dart`
/// customizes it with the appropriate navigation items.
library;

import 'package:flutter/material.dart';


/// A navigation item within a documentation section.
class SectionNavItem {
  const SectionNavItem({
    required this.label,
    required this.icon,
    required this.path,
    this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String path;
}

/// The layout shell for a documentation section.
///
/// Provides a navigation rail and content area. The navigation rail
/// shows all pages within the section; the content area displays
/// the currently selected page.
class SectionLayout extends StatelessWidget {
  const SectionLayout({
    super.key,
    required this.sectionTitle,
    required this.items,
    required this.selectedPath,
    required this.onNavigate,
    required this.child,
    this.leading,
    this.trailing,
  });

  /// Title of this section, shown at the top of the nav rail
  final String sectionTitle;

  /// Navigation items within this section
  final List<SectionNavItem> items;

  /// Currently selected path
  final String selectedPath;

  /// Callback when a navigation item is tapped
  final ValueChanged<String> onNavigate;

  /// The content to display
  final Widget child;

  /// Optional widget above the navigation items
  final Widget? leading;

  /// Optional widget below the navigation items
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find current selection index
    final selectedIndex = items.indexWhere((item) => item.path == selectedPath);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: show rail on wide screens, drawer on narrow
        final isWide = constraints.maxWidth >= 800;

        if (isWide) {
          return Row(
            children: [
              // Navigation Rail
              _buildNavigationRail(context, theme, selectedIndex),

              // Vertical divider
              VerticalDivider(width: 1, color: theme.dividerColor),

              // Content area
              Expanded(
                child: child,
              ),
            ],
          );
        } else {
          // On narrow screens, use a drawer or bottom sheet
          return Scaffold(
            appBar: AppBar(
              title: Text(sectionTitle),
            ),
            drawer: _buildDrawer(context, theme, selectedIndex),
            body: child,
          );
        }
      },
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    ThemeData theme,
    int selectedIndex,
  ) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              sectionTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          if (leading != null) leading!,

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return _NavigationItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onNavigate(item.path),
                );
              },
            ),
          ),

          if (trailing != null) trailing!,

          // Back to home link
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () => onNavigate('/'),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    ThemeData theme,
    int selectedIndex,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                sectionTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return ListTile(
                    leading: Icon(
                      isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: Text(item.label),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate(item.path);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onNavigate('/');
                },
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single navigation item in the section rail.
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final SectionNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

