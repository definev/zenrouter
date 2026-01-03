import 'package:flutter/material.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

/// Tree node for navigation
class NavTreeNode {
  const NavTreeNode({required this.label, this.path, this.children = const []});

  final String label;
  final String? path;
  final List<NavTreeNode> children;

  bool get isLeaf => children.isEmpty;
}

/// Stateful wrapper to manage TOC controller
class DocsLayoutBuilder extends StatefulWidget {
  const DocsLayoutBuilder({
    super.key,
    required this.navTree,
    required this.currentPath,
    required this.onNavigate,
    required this.child,
  });

  final List<NavTreeNode> navTree;
  final String currentPath;
  final ValueChanged<String> onNavigate;
  final Widget child;

  @override
  State<DocsLayoutBuilder> createState() => _DocsLayoutContentState();
}

class _DocsLayoutContentState extends State<DocsLayoutBuilder> {
  late TocController _tocController;

  @override
  void initState() {
    super.initState();
    _tocController = TocController();
  }

  @override
  void dispose() {
    _tocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;

    return DocsTocScope(
      controller: _tocController,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1200;
            final isMedium = constraints.maxWidth >= 800;

            if (isWide) {
              // Wide: Left nav + Content + Right TOC
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Row(
                    children: [
                      _DocsTreeView(
                        navTree: widget.navTree,
                        currentPath: widget.currentPath,
                        onNavigate: widget.onNavigate,
                      ),
                      Expanded(child: child),
                      _DocsTocSidebar(controller: _tocController),
                    ],
                  ),
                ),
              );
            } else if (isMedium) {
              // Medium: Left nav + Content (TOC in end drawer)
              return Scaffold(
                endDrawer: Drawer(
                  child: SafeArea(
                    child: _DocsTocSidebar(
                      controller: _tocController,
                      isInDrawer: true,
                    ),
                  ),
                ),

                body: Row(
                  children: [
                    _DocsTreeView(
                      navTree: widget.navTree,
                      currentPath: widget.currentPath,
                      onNavigate: widget.onNavigate,
                    ),
                    Expanded(child: child),
                  ],
                ),
              );
            } else {
              // Narrow: Drawer nav + Content (TOC in end drawer)
              return Scaffold(
                appBar: AppBar(
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  actions: [],
                ),
                drawer: Drawer(
                  child: SafeArea(
                    child: _DocsTreeView(
                      navTree: widget.navTree,
                      currentPath: widget.currentPath,
                      onNavigate: (path) {
                        Navigator.of(context).pop();
                        widget.onNavigate(path);
                      },
                    ),
                  ),
                ),
                endDrawer: Drawer(
                  child: SafeArea(
                    child: _DocsTocSidebar(
                      controller: _tocController,
                      isInDrawer: true,
                    ),
                  ),
                ),
                body: child,
              );
            }
          },
        ),
      ),
    );
  }
}

/// Table of Contents sidebar
class _DocsTocSidebar extends StatefulWidget {
  const _DocsTocSidebar({required this.controller, this.isInDrawer = false});

  final TocController controller;
  final bool isInDrawer;

  @override
  State<_DocsTocSidebar> createState() => _DocsTocSidebarState();
}

class _DocsTocSidebarState extends State<_DocsTocSidebar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTocControllerChanged);
  }

  void _onTocControllerChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTocControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.controller.items;

    return Container(
      width: widget.isInDrawer ? null : 260,
      color: theme.colorScheme.surfaceContainerLow,
      child: items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 28, right: 16),
                  child: Text(
                    'Table of Contents',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // TOC items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.controller.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.controller.items[index];
                      final isActive = widget.controller.activeItem == item;

                      return _TocListItem(
                        item: item,
                        isActive: isActive,
                        onTap: () {
                          widget.controller.scrollToItem(item);
                          if (widget.isInDrawer) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Individual TOC list item
class _TocListItem extends StatelessWidget {
  const _TocListItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final TocItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
          left: 16 - 2,
          right: 16,
          top: 4,
          bottom: 4,
        ),
        child: Text(
          item.title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Tree view navigation sidebar
class _DocsTreeView extends StatefulWidget {
  const _DocsTreeView({
    required this.navTree,
    required this.currentPath,
    required this.onNavigate,
  });

  final List<NavTreeNode> navTree;
  final String currentPath;
  final ValueChanged<String> onNavigate;

  @override
  State<_DocsTreeView> createState() => _DocsTreeViewState();
}

class _DocsTreeViewState extends State<_DocsTreeView> {
  late Set<int> _expandedSections;

  @override
  void initState() {
    super.initState();
    _expandedSections = _findExpandedSections();
  }

  @override
  void didUpdateWidget(_DocsTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      final newExpanded = _findExpandedSections();
      _expandedSections = {..._expandedSections, ...newExpanded};
    }
  }

  Set<int> _findExpandedSections() {
    final expanded = <int>{};
    for (var i = 0; i < widget.navTree.length; i++) {
      final section = widget.navTree[i];
      for (final child in section.children) {
        if (child.path == widget.currentPath ||
            (widget.currentPath.contains('/examples') &&
                section.label == 'Examples')) {
          expanded.add(i);
          break;
        }
      }
    }
    return expanded;
  }

  void _toggleSection(int index) {
    setState(() {
      if (_expandedSections.contains(index)) {
        _expandedSections.remove(index);
      } else {
        _expandedSections.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.only(left: 16, top: 12),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                top: 16,
                right: 16,
                bottom: 8,
              ),
              child: Text(
                'Documentation',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: widget.navTree.length,
            itemBuilder: (context, index) {
              final section = widget.navTree[index];
              final isExpanded = _expandedSections.contains(index);

              return _TreeSection(
                section: section,
                isExpanded: isExpanded,
                currentPath: widget.currentPath,
                onToggle: () => _toggleSection(index),
                onNavigate: widget.onNavigate,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A collapsible section in the tree view
class _TreeSection extends StatelessWidget {
  const _TreeSection({
    required this.section,
    required this.isExpanded,
    required this.currentPath,
    required this.onToggle,
    required this.onNavigate,
  });

  final NavTreeNode section;
  final bool isExpanded;
  final String currentPath;
  final VoidCallback onToggle;
  final ValueChanged<String> onNavigate;

  bool get _hasSelectedChild {
    for (final child in section.children) {
      if (child.path == currentPath) return true;
      if (currentPath.startsWith('/examples') && section.label == 'Examples') {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              section.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: _hasSelectedChild
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: _hasSelectedChild
                    ? sectionColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
        ),

        // Children
        switch (isExpanded) {
          true => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              for (final child in section.children)
                _TreeLeaf(
                  node: child,
                  isSelected:
                      child.path == currentPath ||
                      (currentPath.startsWith(child.path ?? '') &&
                          child.path != null &&
                          child.path!.contains('/examples/')),
                  sectionColor: sectionColor,
                  onTap: () {
                    if (child.path != null) {
                      onNavigate(child.path!);
                    }
                  },
                ),
            ],
          ),
          false => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// A leaf node (actual page) in the tree view
class _TreeLeaf extends StatelessWidget {
  const _TreeLeaf({
    required this.node,
    required this.isSelected,
    required this.sectionColor,
    required this.onTap,
  });

  final NavTreeNode node;
  final bool isSelected;
  final Color sectionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.only(left: 8, right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          node.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? sectionColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// InheritedWidget to provide TOC controller to child routes
class DocsTocScope extends InheritedWidget {
  const DocsTocScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final TocController controller;

  static TocController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DocsTocScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(DocsTocScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
