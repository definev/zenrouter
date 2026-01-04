/// # Markdown Section Widget
///
/// A reusable widget for rendering markdown content with custom styling
/// and Table of Contents support.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:google_fonts/google_fonts.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

/// Controller for managing TOC state
class TocController extends ChangeNotifier {
  final List<TocItem> _items = [];
  TocItem? _activeItem;
  bool _isUserScrolling = false;
  DateTime? _lastManualScroll;

  List<TocItem> get items => List.unmodifiable(_items);
  TocItem? get activeItem => _activeItem;

  void setActiveItem(TocItem? item, {bool fromScroll = false}) {
    if (_activeItem != item) {
      // If this is from scroll listener, check if we should ignore it
      if (fromScroll && _isUserScrolling) {
        // Ignore scroll updates for 500ms after manual scroll
        final timeSinceManual = _lastManualScroll != null
            ? DateTime.now().difference(_lastManualScroll!)
            : null;
        if (timeSinceManual != null && timeSinceManual.inMilliseconds < 500) {
          return;
        }
        _isUserScrolling = false;
      }

      _activeItem = item;
      notifyListeners();
    }
  }

  void scrollToItem(TocItem item) {
    final context = item.key.currentContext;
    if (context != null) {
      _isUserScrolling = true;
      _lastManualScroll = DateTime.now();

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
    if (_items.length == 1) {
      setActiveItem(tocItem);
    }
    notifyListeners();
  }

  void clearItems() {
    _items.clear();
    notifyListeners();
  }
}

/// A heading item extracted from markdown for TOC
class TocItem {
  const TocItem({required this.title, required this.level, required this.key});

  final String title;
  final int level;
  final GlobalKey key;
}

/// A widget that renders markdown content with custom styling
class MarkdownSection extends StatelessWidget {
  const MarkdownSection({
    super.key,
    required this.markdown,
    this.tocController,
  });

  final String markdown;
  final TocController? tocController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MarkdownBody(
      data: markdown,
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
          tocController: tocController,
        ),
        'h2': HeadingBuilder(
          type: HeadingType.h2,
          tocController: tocController,
        ),
        'h3': HeadingBuilder(
          type: HeadingType.h3,
          tocController: tocController,
        ),
        'h4': HeadingBuilder(
          type: HeadingType.h4,
          tocController: tocController,
        ),
        'h5': HeadingBuilder(
          type: HeadingType.h5,
          tocController: tocController,
        ),
        'h6': HeadingBuilder(
          type: HeadingType.h6,
          tocController: tocController,
        ),
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(
    BuildContext context,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final docs = theme.docs;

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

      codeblockDecoration: BoxDecoration(
        color: docs.codeBackground,
        borderRadius: BorderRadius.circular(16),
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
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
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

class HeadingBuilder extends MarkdownElementBuilder {
  HeadingBuilder({required this.type, required this.tocController});

  final HeadingType type;
  final TocController? tocController;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
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
  final TocController? tocController;
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
      widget.tocController?.addItem(
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
        onTap: () => widget.tocController?.scrollToItem(_item!),
        child: Text('# ${widget.element.textContent}', key: _key, style: style),
      ),
    );
  }
}

enum HeadingType { h1, h2, h3, h4, h5, h6 }
