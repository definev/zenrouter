/// # Documentation Page Widget
///
/// A comprehensive widget for rendering markdown documentation
/// with automatic Table of Contents extraction.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

import 'package:zenrouter_docs/widgets/mardown_section.dart';

/// A documentation page that renders markdown with TOC support
class DocPage extends StatefulWidget {
  const DocPage({
    super.key,
    required this.markdown,
    required this.title,
    this.subtitle,
    this.tocController,
    this.bottomWidget,
  });

  final String markdown;
  final String title;
  final String? subtitle;
  final TocController? tocController;
  final Widget? bottomWidget;

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  late TocController _tocController;
  late ScrollController _scrollController;

  void _resetTocController() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _tocController.clearItems();
    });
  }

  void _onScroll() {
    if (_tocController.items.isEmpty) return;

    // Check if scrolled to bottom - if so, activate the last item
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isAtBottom = currentScroll >= maxScroll - 50; // 50px threshold

    if (isAtBottom) {
      _tocController.setActiveItem(_tocController.items.last, fromScroll: true);
      return;
    }

    // Find the heading that's closest to the top of the viewport
    TocItem? activeItem;
    double minDistance = double.infinity;

    for (final item in _tocController.items) {
      final context = item.key.currentContext;
      if (context == null) continue;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      // Get the position of the heading relative to the viewport
      final position = renderBox.localToGlobal(Offset.zero);

      // Calculate distance from top of viewport
      // We use a small offset (100px) to activate items slightly before they reach the top
      final distance = (position.dy - 100).abs();

      // Only consider headings that are above or near the top of the viewport
      if (position.dy <= 200 && distance < minDistance) {
        minDistance = distance;
        activeItem = item;
      }
    }

    // If no item is near the top, use the first visible item
    if (activeItem == null) {
      for (final item in _tocController.items) {
        final context = item.key.currentContext;
        if (context == null) continue;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) continue;

        final position = renderBox.localToGlobal(Offset.zero);

        // Check if heading is visible in viewport
        if (position.dy >= 0 &&
            position.dy <= MediaQuery.of(context).size.height) {
          activeItem = item;
          break;
        }
      }
    }

    if (activeItem != null) {
      _tocController.setActiveItem(activeItem, fromScroll: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _tocController = widget.tocController ?? TocController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _resetTocController();
  }

  @override
  void didUpdateWidget(DocPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown) {
      _resetTocController();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SelectionArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: docs.contentPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.libreBaskerville(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.subtitle!,
                              style: GoogleFonts.libreBaskerville(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final size = MediaQuery.sizeOf(context);
                        final isWide = size.width >= 1200;
                        final isMedium = size.width >= 800;

                        return Row(
                          children: [
                            if (!isMedium && !isWide)
                              IconButton(
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                                tooltip: 'Show documentation sidebar',
                                icon: const Icon(Icons.article),
                              ),
                            if (!isWide)
                              IconButton(
                                onPressed: () =>
                                    Scaffold.of(context).openEndDrawer(),
                                tooltip: 'Show table of contents',
                                icon: const Icon(Icons.menu_book_rounded),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Markdown content
                MarkdownSection(
                  markdown: widget.markdown,
                  tocController: _tocController,
                ),

                ?widget.bottomWidget,
                // Extra padding at bottom to allow last sections to scroll to top
                SizedBox(height: MediaQuery.of(context).size.height * 0.7),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
