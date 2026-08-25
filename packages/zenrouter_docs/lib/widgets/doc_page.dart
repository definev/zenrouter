/// # Documentation Page Widget
///
/// A comprehensive widget for rendering markdown documentation
/// with automatic Table of Contents extraction.
library;

import 'package:flutter/widgets.dart';
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
    this.chapterNavigation,
    this.onOpenUri,
  });

  final String markdown;
  final String title;
  final String? subtitle;
  final TocController? tocController;
  final Widget? bottomWidget;
  final Widget? chapterNavigation;
  final ValueChanged<Uri>? onOpenUri;

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  late TocController _tocController;
  late final ScrollController _scrollController;
  late bool _ownsTocController;

  void _updateActiveItemFromScroll() {
    if (!_scrollController.hasClients) return;
    if (_tocController.items.isEmpty) return;

    final scrollPosition = _scrollController.position.pixels;
    final viewportHeight = MediaQuery.of(context).size.height;

    _tocController.updateActiveItemFromScrollPosition(
      scrollPosition,
      viewportHeight,
      _scrollController.position.maxScrollExtent,
    );
  }

  @override
  void initState() {
    super.initState();
    _ownsTocController = widget.tocController == null;
    _tocController = widget.tocController ?? TocController();
    _tocController.clearItems();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateActiveItemFromScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scrollController.hasClients &&
          _tocController.items.isNotEmpty) {
        // Wait a bit more for scroll restoration to complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _updateActiveItemFromScroll();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(DocPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tocController != widget.tocController) {
      if (_ownsTocController) _tocController.dispose();
      _ownsTocController = widget.tocController == null;
      _tocController = widget.tocController ?? TocController();
      _tocController.clearItems();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _updateActiveItemFromScroll();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateActiveItemFromScroll);
    _scrollController.dispose();
    if (_ownsTocController) _tocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docs = context.docsTheme;
    final compact = MediaQuery.sizeOf(context).width < 620;
    final horizontalPadding = compact ? 24.0 : docs.contentPadding.left;
    final hasChapterNavigation = widget.chapterNavigation != null;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasChapterNavigation) widget.chapterNavigation!,
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              hasChapterNavigation ? 64 : docs.contentPadding.top,
              compact ? 24 : docs.contentPadding.right,
              hasChapterNavigation ? 56 : 0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.sans(
                        fontSize: compact ? 46 : 60,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.ink,
                        height: 1,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle!,
                        style: AppTypography.sans(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    KeyedSubtree(
                      key: ValueKey((widget.markdown, _tocController)),
                      child: MarkdownSection(
                        markdown: widget.markdown,
                        tocController: _tocController,
                        onOpenUri: widget.onOpenUri,
                      ),
                    ),
                    if (widget.bottomWidget != null) widget.bottomWidget!,
                  ],
                ),
              ),
            ),
          ),
          if (hasChapterNavigation) widget.chapterNavigation!,
          SizedBox(height: 96 + docs.contentPadding.bottom),
        ],
      ),
    );
  }
}
