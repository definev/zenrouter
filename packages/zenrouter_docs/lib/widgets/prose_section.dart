/// # Prose Section Widget
///
/// For documentation that reads like literature, we need a widget
/// that presents text with proper typographic care - appropriate
/// line height, comfortable measure, and visual rhythm.
library;

import 'package:flutter/material.dart';

import 'package:zenrouter_docs/theme/app_theme.dart';

/// A section of prose text, styled for comfortable reading.
///
/// The measure (line length) is constrained to approximately 60-75
/// characters per line - the range that typographers have found
/// optimal for sustained reading.
class ProseSection extends StatelessWidget {
  const ProseSection({super.key, required this.content, this.style});

  /// The prose content to display
  final String content;

  /// Optional custom text style
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
      child: SelectableText(
        content.trim(),
        style: style ?? theme.textTheme.bodyLarge,
      ),
    );
  }
}

/// A prose section with a title, for structured documentation.
class TitledProseSection extends StatelessWidget {
  const TitledProseSection({
    super.key,
    required this.title,
    required this.content,
    this.titleStyle,
    this.contentStyle,
  });

  final String title;
  final String content;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            title,
            style: titleStyle ?? theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          SelectableText(
            content.trim(),
            style: contentStyle ?? theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// A blockquote for emphasized passages or citations.
class ProseBlockquote extends StatelessWidget {
  const ProseBlockquote({super.key, required this.content, this.attribution});

  final String content;
  final String? attribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 4),
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              content.trim(),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            if (attribution != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                '— $attribution',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
