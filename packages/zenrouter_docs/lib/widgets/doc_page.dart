/// # Documentation Page Widget
///
/// A comprehensive widget for rendering markdown documentation
/// with automatic Table of Contents extraction.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

import 'package:zenrouter_docs/widgets/code_block.dart';

/// A heading item extracted from markdown for TOC
class TocItem {
  const TocItem({required this.title, required this.level, required this.key});

  final String title;
  final int level;
  final GlobalKey key;
}

/// Controller for managing TOC state
class TocController extends ChangeNotifier {
  final List<TocItem> _items = [];
  TocItem? _activeItem;

  List<TocItem> get items => List.unmodifiable(_items);
  TocItem? get activeItem => _activeItem;

  void setActiveItem(TocItem? item) {
    if (_activeItem != item) {
      _activeItem = item;
      notifyListeners();
    }
  }

  void scrollToItem(TocItem item) {
    final context = item.key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
        alignment: 0.1,
      );
      setActiveItem(item);
    }
  }

  void addItem(TocItem tocItem) {
    _items.add(tocItem);
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }
}

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

  @override
  void initState() {
    super.initState();
    _tocController = widget.tocController ?? TocController();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;
    final isDark = theme.brightness == Brightness.dark;

    return SelectionArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                Column(
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
                    const SizedBox(height: 32),
                  ],
                ),

                // Markdown content
                MarkdownBody(
                  data: widget.markdown,
                  styleSheet: _buildMarkdownStyleSheet(context, isDark),
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    <md.InlineSyntax>[
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                    ],
                  ),
                  builders: {
                    'pre': CodeBlockBuilder(),
                    'code': CodeTextBuilder(context: context),
                    'h1': HeadingBuilder(
                      type: HeadingType.h1,
                      tocController: _tocController,
                    ),
                    'h2': HeadingBuilder(
                      type: HeadingType.h2,
                      tocController: _tocController,
                    ),
                    'h3': HeadingBuilder(
                      type: HeadingType.h3,
                      tocController: _tocController,
                    ),
                    'h4': HeadingBuilder(
                      type: HeadingType.h4,
                      tocController: _tocController,
                    ),
                    'h5': HeadingBuilder(
                      type: HeadingType.h5,
                      tocController: _tocController,
                    ),
                    'h6': HeadingBuilder(
                      type: HeadingType.h6,
                      tocController: _tocController,
                    ),
                  },
                ),

                ?widget.bottomWidget,
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(
    BuildContext context,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return MarkdownStyleSheet(
      // Heading styles
      h1: GoogleFonts.libreBaskerville(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h2: GoogleFonts.libreBaskerville(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h3: GoogleFonts.libreBaskerville(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h4: GoogleFonts.libreBaskerville(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h5: GoogleFonts.libreBaskerville(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h6: GoogleFonts.libreBaskerville(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),

      // Paragraph style
      p: GoogleFonts.libreBaskerville(
        fontSize: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
        height: 1.7,
        letterSpacing: 0.15,
      ),

      // Blockquote style
      blockquote: GoogleFonts.libreBaskerville(
        fontSize: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),

      // Link style
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      ),

      // List styles
      listBullet: GoogleFonts.libreBaskerville(
        fontSize: 16,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      listIndent: 20,

      // Table styles
      tableHead: GoogleFonts.libreBaskerville(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      tableBody: GoogleFonts.libreBaskerville(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.87),
      ),
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      tableCellsPadding: const EdgeInsets.all(12),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),

      // Text alignment
      textAlign: WrapAlignment.start,
      blockSpacing: 16,

      code: GoogleFonts.ptMono(fontSize: 16, color: theme.colorScheme.primary),
    );
  }
}

/// Custom builder for code blocks that uses the CodeBlock widget
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Code blocks are wrapped in <pre><code> elements
    // Find the code element inside the pre element
    md.Element? codeElement;
    final children = element.children;
    if (children != null) {
      for (final child in children) {
        if (child is md.Element && child.tag == 'code') {
          codeElement = child;
          break;
        }
      }
    }

    if (codeElement == null) {
      return null; // Let default builder handle it
    }

    // Extract language from class attribute (e.g., "language-dart" -> "dart")
    final classAttr = codeElement.attributes['class'] ?? '';
    final language = classAttr.replaceAll('language-', '').trim();
    final code = codeElement.textContent.trim();

    if (code.isEmpty) {
      return const SizedBox.shrink();
    }

    return CodeBlock(
      title: language.isEmpty ? 'Code' : language,
      code: code,
      language: language.isEmpty ? 'dart' : language,
    );
  }
}

class CodeTextBuilder extends MarkdownElementBuilder {
  CodeTextBuilder({required this.context});

  final BuildContext context;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // The issue: Container is a block widget, causing line breaks.
    // Solution: Wrap the Container in a WidgetSpan inside Text.rich
    // This allows it to be placed inline with surrounding text
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEFF1F3),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(top: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            element.textContent.trim(),
            style: GoogleFonts.ptMono(
              fontSize: 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Table of Contents widget for the right sidebar
class TableOfContents extends StatelessWidget {
  const TableOfContents({
    super.key,
    required this.controller,
    this.title = 'On This Page',
  });

  final TocController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) {
                    final item = controller.items[index];
                    final isActive = controller.activeItem == item;

                    return _TocItem(
                      item: item,
                      isActive: isActive,
                      onTap: () => controller.scrollToItem(item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TocItem extends StatelessWidget {
  const _TocItem({
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

    // Calculate indentation based on heading level
    final indent = (item.level - 1) * 12.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.only(left: 8 + indent, right: 8, top: 6, bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 2,
              color: isActive ? theme.colorScheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          item.title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class HeadingBuilder extends MarkdownElementBuilder {
  HeadingBuilder({required this.type, required this.tocController});

  final HeadingType type;
  final TocController tocController;

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return _HeadingWidget(
      type: type,
      tocController: tocController,
      element: element,
    );
  }
}

class _HeadingWidget extends StatefulWidget {
  const _HeadingWidget({
    required this.type,
    required this.tocController,
    required this.element,
  });

  final HeadingType type;
  final TocController tocController;
  final md.Element element;

  @override
  State<_HeadingWidget> createState() => _HeadingWidgetState();
}

class _HeadingWidgetState extends State<_HeadingWidget> {
  final GlobalKey _key = GlobalKey();
  late final TocItem? _item;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.tocController.addItem(
        _item = TocItem(
          title: widget.element.textContent,
          level: widget.type.index + 1,
          key: _key,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = switch (widget.type) {
      HeadingType.h1 => theme.textTheme.headlineLarge,
      HeadingType.h2 => theme.textTheme.headlineMedium,
      HeadingType.h3 => theme.textTheme.headlineSmall,
      HeadingType.h4 => theme.textTheme.titleLarge,
      HeadingType.h5 => theme.textTheme.titleMedium,
      HeadingType.h6 => theme.textTheme.titleSmall,
    };
    final padTop = switch (widget.type) {
      HeadingType.h1 => 32,
      HeadingType.h2 => 24,
      HeadingType.h3 => 16,
      HeadingType.h4 => 12,
      HeadingType.h5 => 8,
      HeadingType.h6 => 4,
    }.toDouble();

    return Padding(
      padding: EdgeInsets.only(top: padTop),
      child: GestureDetector(
        onTap: () => widget.tocController.scrollToItem(_item!),
        child: Text('# ${widget.element.textContent}', key: _key, style: style),
      ),
    );
  }
}

enum HeadingType { h1, h2, h3, h4, h5, h6 }
