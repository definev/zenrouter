library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

/// A syntax-highlighted code block with a Forui copy control.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.language = 'dart',
    this.title,
    this.showLineNumbers = false,
    this.highlightedLines = const [],
  });

  final String code;
  final String language;
  final String? title;
  final bool showLineNumbers;
  final List<int> highlightedLines;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  Future<Highlighter>? _highlighter;

  @override
  void initState() {
    super.initState();
    _highlighter = _SyntaxHighlighters.forLanguage(widget.language);
  }

  @override
  void didUpdateWidget(covariant CodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.language != widget.language) {
      _highlighter = _SyntaxHighlighters.forLanguage(widget.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = context.docsTheme;

    return FutureBuilder<Highlighter>(
      future: _highlighter,
      builder: (context, snapshot) {
        final highlightedCode =
            snapshot.data?.highlight(widget.code) ??
            TextSpan(text: widget.code);

        return Container(
          constraints: BoxConstraints(maxWidth: docs.proseMaxWidth + 100),
          decoration: const BoxDecoration(
            color: AppTheme.codeBackground,
            border: Border.fromBorderSide(BorderSide(color: AppTheme.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.title != null)
                _CodeHeader(
                  title: widget.title!,
                  code: widget.code,
                  language: widget.language,
                ),
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
                        style: AppTypography.mono(
                          fontSize: 13,
                          height: 1.45,
                          color: AppTheme.ink,
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
}

/// Shares grammar and theme work across every code block on the page.
///
/// Unsupported languages render as plain text immediately instead of leaving
/// a permanent blank placeholder.
abstract final class _SyntaxHighlighters {
  static const _supported = {'dart', 'json', 'yaml'};
  static final Map<String, Future<Highlighter>> _cache = {};
  static Future<HighlighterTheme>? _theme;

  static Future<Highlighter>? forLanguage(String language) {
    if (!_supported.contains(language)) return null;
    return _cache.putIfAbsent(language, () => _create(language));
  }

  static Future<Highlighter> _create(String language) async {
    final theme = await (_theme ??= HighlighterTheme.loadLightTheme());
    await Highlighter.initialize([language]);
    return Highlighter(language: language, theme: theme);
  }
}

class _CodeHeader extends StatelessWidget {
  const _CodeHeader({
    required this.title,
    required this.code,
    required this.language,
  });

  final String title;
  final String code;
  final String language;

  IconData get _languageIcon => switch (language) {
    'shell' => FLucideIcons.terminal,
    'yaml' || 'json' => FLucideIcons.braces,
    _ => FLucideIcons.code2,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Icon(_languageIcon, size: 15, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTypography.mono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.mutedInk,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _CopyButton(code: code),
        ],
      ),
    );
  }
}

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
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      semanticsLabel: _copied ? 'Copied' : 'Copy code',
      variant: FButtonVariant.ghost,
      size: FButtonSizeVariant.xs,
      onPress: _copyToClipboard,
      child: Icon(
        _copied ? FLucideIcons.check : FLucideIcons.copy,
        size: 16,
        color: _copied ? AppTheme.success : AppTheme.mutedInk,
      ),
    );
  }
}

class InlineCode extends StatelessWidget {
  const InlineCode(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.codeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: AppTypography.mono(fontSize: 14, color: AppTheme.primary),
      ),
    );
  }
}
