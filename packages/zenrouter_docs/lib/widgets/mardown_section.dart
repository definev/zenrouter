/// # Markdown Section Widget
///
/// A reusable widget for rendering markdown content with custom styling
/// and Table of Contents support.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

/// Controller for managing TOC state
class TocController extends ChangeNotifier {
  final List<TocItem> _items = [];
  TocItem? _activeItem;
  bool _isUserScrolling = false;
  bool _notificationScheduled = false;
  bool _disposed = false;
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
    if (_items.contains(tocItem)) return;

    _items.add(tocItem);
    if (_items.length == 1) {
      _activeItem = tocItem;
    }
    notifyListeners();
  }

  void removeItem(TocItem tocItem) {
    if (!_items.remove(tocItem)) return;
    if (_activeItem == tocItem) {
      _activeItem = _items.firstOrNull;
    }
    _notifyAfterFrame();
  }

  void clearItems() {
    if (_items.isEmpty && _activeItem == null) return;
    _items.clear();
    _activeItem = null;
    _notifyAfterFrame();
  }

  void _notifyAfterFrame() {
    if (_notificationScheduled || _disposed) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Updates the active item based on the current scroll position
  /// This is useful when the route is restored and scroll position is already set
  void updateActiveItemFromScrollPosition(
    double scrollPosition,
    double viewportHeight,
    double maxScrollExtent,
  ) {
    if (_items.isEmpty) return;

    if (scrollPosition >= maxScrollExtent - 50) {
      setActiveItem(_items.last, fromScroll: true);
      return;
    }

    TocItem? activeItem;
    double minDistance = double.infinity;

    for (final item in _items) {
      final context = item.key.currentContext;
      if (context == null) continue;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      // Get the position of the heading relative to the viewport
      final position = renderBox.localToGlobal(Offset.zero);

      // Calculate distance from top of viewport (with offset)
      final distance = (position.dy - 100).abs();

      // Only consider headings that are above or near the top of the viewport
      if (position.dy <= 200 && distance < minDistance) {
        minDistance = distance;
        activeItem = item;
      }
    }

    // If no item is near the top, use the first visible item
    if (activeItem == null) {
      for (final item in _items) {
        final context = item.key.currentContext;
        if (context == null) continue;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) continue;

        final position = renderBox.localToGlobal(Offset.zero);

        // Check if heading is visible in viewport
        if (position.dy >= 0 && position.dy <= viewportHeight) {
          activeItem = item;
          break;
        }
      }
    }

    // If still no item found and we're at the top, use first item
    if (activeItem == null && scrollPosition <= 50) {
      activeItem = _items.isNotEmpty ? _items.first : null;
    }

    // If still no item found, use last item (likely at bottom)
    if (activeItem == null && _items.isNotEmpty) {
      activeItem = _items.last;
    }

    if (activeItem != null) {
      setActiveItem(activeItem, fromScroll: true);
    }
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
    this.onOpenUri,
  });

  final String markdown;
  final TocController? tocController;
  final ValueChanged<Uri>? onOpenUri;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: markdown,
      selectable: true,
      onTapLink: onOpenUri == null
          ? null
          : (text, href, title) {
              final uri = href == null ? null : Uri.tryParse(href);
              if (uri != null) onOpenUri!(uri);
            },
      styleSheet: _buildMarkdownStyleSheet(),
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

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      // Heading styles
      h1: AppTypography.sans(
        fontSize: 42,
        fontWeight: FontWeight.w300,
        color: AppTheme.ink,
        height: 1.4,
      ),
      h2: AppTypography.sans(
        fontSize: 35,
        fontWeight: FontWeight.w300,
        color: AppTheme.primary,
        height: 1.4,
      ),
      h3: AppTypography.sans(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: AppTheme.ink,
        height: 1.4,
      ),
      h4: AppTypography.sans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
        height: 1.4,
      ),
      h5: AppTypography.sans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
        height: 1.4,
      ),
      h6: AppTypography.sans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
        height: 1.4,
      ),

      // Paragraph style
      p: AppTypography.serif(
        fontSize: 14,
        color: AppTheme.ink.withValues(alpha: 0.87),
        height: 1.72,
        letterSpacing: 0.15,
      ),

      codeblockDecoration: const BoxDecoration(
        color: AppTheme.codeBackground,
        borderRadius: BorderRadius.zero,
      ),

      // Blockquote style
      blockquote: AppTypography.serif(
        fontSize: 14,
        color: AppTheme.ink.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.primary, width: 4)),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),

      // Link style
      a: TextStyle(
        color: AppTheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: AppTheme.primary.withValues(alpha: 0.5),
      ),

      // List styles
      listBullet: AppTypography.sans(
        fontSize: 16,
        color: AppTheme.primary,
        fontWeight: FontWeight.bold,
      ),
      listIndent: 20,

      // Table styles
      tableHead: AppTypography.serif(
        fontWeight: FontWeight.bold,
        color: AppTheme.ink,
      ),
      tableBody: AppTypography.serif(
        color: AppTheme.ink.withValues(alpha: 0.87),
      ),
      tableBorder: TableBorder.all(
        color: AppTheme.divider.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      tableCellsPadding: const EdgeInsets.all(12),

      // Horizontal rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),

      // Text alignment
      textAlign: WrapAlignment.start,
      blockSpacing: 16,

      code: AppTypography.mono(fontSize: 16, color: AppTheme.primary),
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
    // The issue: Container is a block widget, causing line breaks.
    // Solution: Wrap the Container in a WidgetSpan inside Text.rich
    // This allows it to be placed inline with surrounding text
    return Text.rich(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF1F3),
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(top: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            element.textContent.trim(),
            style: AppTypography.mono(fontSize: 16, color: AppTheme.primary),
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
  late TocItem _item;
  TocController? _registeredController;

  @override
  void initState() {
    super.initState();
    _item = _createItem();
    _registerAfterLayout();
  }

  TocItem _createItem() => TocItem(
    title: widget.element.textContent,
    level: widget.type.index + 1,
    key: _key,
  );

  void _registerAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _registeredController != null) return;
      _registeredController = widget.tocController;
      _registeredController?.addItem(_item);
    });
  }

  void _unregister() {
    _registeredController?.removeItem(_item);
    _registeredController = null;
  }

  @override
  void didUpdateWidget(covariant _HeadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final itemChanged =
        oldWidget.type != widget.type ||
        oldWidget.element.textContent != widget.element.textContent;
    if (oldWidget.tocController == widget.tocController && !itemChanged) {
      return;
    }

    _unregister();
    if (itemChanged) _item = _createItem();
    _registerAfterLayout();
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = switch (widget.type) {
      HeadingType.h1 => AppTypography.sans(
        fontSize: 38,
        fontWeight: FontWeight.w300,
        color: AppTheme.primary,
      ),
      HeadingType.h2 => AppTypography.sans(
        fontSize: 31,
        fontWeight: FontWeight.w300,
        color: AppTheme.primary,
      ),
      HeadingType.h3 => AppTypography.sans(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppTheme.ink,
      ),
      HeadingType.h4 => AppTypography.sans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
      ),
      HeadingType.h5 => AppTypography.sans(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
      ),
      HeadingType.h6 => AppTypography.sans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.ink,
      ),
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
        onTap: () => widget.tocController?.scrollToItem(_item),
        child: Text(widget.element.textContent, key: _key, style: style),
      ),
    );
  }
}

enum HeadingType { h1, h2, h3, h4, h5, h6 }
