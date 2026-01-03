/// # Code Block Widget
///
/// Code examples are the bridge between theory and practice. They must
/// be readable, copyable, and visually distinct from prose. We use
/// syntax highlighting to aid comprehension and a monospace font to
/// preserve alignment.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

import 'package:zenrouter_docs/theme/app_theme.dart';

/// A syntax-highlighted code block with optional title and copy button.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.language = 'dart',
    this.title,
    this.showLineNumbers = false,
    this.highlightedLines = const [],
  });

  /// The source code to display
  final String code;

  /// The programming language for syntax highlighting
  final String language;

  /// Optional title shown above the code block
  final String? title;

  /// Whether to show line numbers
  final bool showLineNumbers;

  /// Lines to highlight (1-indexed)
  final List<int> highlightedLines;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool? _isDark;
  Future<Highlighter>? highlighter;

  Future<Highlighter> _initHighlighter(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlighterTheme = isDark
        ? await HighlighterTheme.loadDarkTheme()
        : await HighlighterTheme.loadLightTheme();
    await Highlighter.initialize([widget.language]);
    return Highlighter(language: widget.language, theme: highlighterTheme);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        highlighter = _initHighlighter(context);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;
    final isDark = theme.brightness == Brightness.dark;
    if (_isDark != isDark) {
      _isDark = isDark;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          highlighter = _initHighlighter(context);
          setState(() {});
        }
      });
    }

    if (highlighter == null) return const SizedBox();

    return FutureBuilder(
      key: ValueKey(highlighter),
      future: highlighter!,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final highlighter = snapshot.data!;
        final highlightedCode = highlighter.highlight(widget.code);

        return Container(
          constraints: BoxConstraints(maxWidth: docs.proseMaxWidth + 100),
          decoration: BoxDecoration(
            color: docs.codeBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with title and copy button
              if (widget.title != null) _buildHeader(context, isDark),

              // Code content - LayoutBuilder ensures full width when code is short
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text.rich(
                        highlightedCode,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(_getLanguageIcon(), size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title!,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _CopyButton(code: widget.code),
        ],
      ),
    );
  }

  IconData _getLanguageIcon() {
    return switch (widget.language) {
      'dart' => Icons.flutter_dash_rounded,
      'yaml' => Icons.settings,
      'bash' || 'shell' => Icons.terminal,
      'json' => Icons.data_object,
      _ => Icons.code,
    };
  }
}

/// A button to copy code to clipboard.
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code.trim()));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 18,
        color: _copied
            ? Colors.green
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onPressed: _copyToClipboard,
      tooltip: _copied ? 'Copied!' : 'Copy code',
      visualDensity: VisualDensity.compact,
    );
  }
}

/// An inline code span for use within prose.
class InlineCode extends StatelessWidget {
  const InlineCode(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: docs.codeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
