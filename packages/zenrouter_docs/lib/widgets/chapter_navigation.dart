library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/content/book_outline.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

class ChapterNavigation extends StatelessWidget {
  const ChapterNavigation({
    super.key,
    required this.chapter,
    required this.coordinator,
  });

  final BookChapter chapter;
  final DocsCoordinator coordinator;

  BookChapter? get previous {
    final index = bookChapters.indexOf(chapter);
    return index > 0 ? bookChapters[index - 1] : null;
  }

  BookChapter? get next {
    final index = bookChapters.indexOf(chapter);
    return index >= 0 && index < bookChapters.length - 1
        ? bookChapters[index + 1]
        : null;
  }

  Future<void> _open(BookChapter target) async {
    final route = await coordinator.parseRouteFromUri(
      Uri.parse(target.routePath),
    );
    if (route != null) await coordinator.navigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    final style = AppTypography.sans(
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w500,
      color: AppTheme.primary,
    );

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppTheme.paleBlue,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppTheme.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ChapterLink(
              label: previous == null || compact
                  ? '← Previous'
                  : '←  ${previous!.title}',
              style: style,
              alignment: Alignment.centerLeft,
              horizontalPadding: compact ? 16 : 24,
              onPress: previous == null ? null : () => _open(previous!),
            ),
          ),
          _ChapterLink(
            label: compact ? '§ Contents' : '§  Contents',
            style: style,
            alignment: Alignment.center,
            horizontalPadding: compact ? 8 : 16,
            onPress: coordinator.pushDocsIndex,
          ),
          Expanded(
            child: _ChapterLink(
              label: next == null || compact ? 'Next →' : '${next!.title}  →',
              style: style,
              alignment: Alignment.centerRight,
              horizontalPadding: compact ? 16 : 24,
              onPress: next == null ? null : () => _open(next!),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterLink extends StatelessWidget {
  const _ChapterLink({
    required this.label,
    required this.style,
    required this.alignment,
    required this.horizontalPadding,
    required this.onPress,
  });

  final String label;
  final TextStyle style;
  final Alignment alignment;
  final double horizontalPadding;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      semanticsLabel: label,
      onPress: onPress,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => ColoredBox(
        color: states.contains(FTappableVariant.hovered) && onPress != null
            ? AppTheme.primary.withValues(alpha: 0.06)
            : const Color(0x00000000),
        child: child!,
      ),
      child: Container(
        alignment: alignment,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 12,
        ),
        child: Text(
          label,
          style: onPress == null
              ? style.copyWith(color: AppTheme.ink.withValues(alpha: 0.28))
              : style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
