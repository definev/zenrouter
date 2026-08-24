library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/content/book_outline.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part 'index.g.dart';

@ZenRoute()
class DocsIndexRoute extends _$DocsIndexRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return DocsIndexWidget(coordinator: coordinator);
  }
}

class DocsIndexWidget extends StatelessWidget {
  const DocsIndexWidget({super.key, required this.coordinator});

  final DocsCoordinator coordinator;

  Future<void> _open(BookChapter chapter) async {
    final route = await coordinator.parseRouteFromUri(
      Uri.parse(chapter.routePath),
    );
    if (route != null) await coordinator.navigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 620;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(narrow ? 24 : 40, 62, narrow ? 24 : 40, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contents',
                style: AppTypography.sans(
                  fontSize: narrow ? 46 : 60,
                  fontWeight: FontWeight.w300,
                  height: 1,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ZenRouter · a field guide to navigation in Flutter',
                style: AppTypography.sans(
                  fontSize: 16,
                  color: AppTheme.ink.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'A route graph is easier to learn when each chapter changes one thing. Follow the numbered path from the beginning, or jump to a field guide when you already know the model.',
                style: AppTypography.serif(
                  fontSize: 16,
                  height: 1.8,
                  color: AppTheme.ink.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 42),
              for (final part in bookParts)
                _PartContents(
                  part: part,
                  chapters: bookChapters
                      .where((chapter) => chapter.part == part)
                      .toList(),
                  onOpen: _open,
                ),
              const SizedBox(height: 38),
              const FDivider(),
              const SizedBox(height: 24),
              Text(
                'Reference and source',
                style: AppTypography.sans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'When you need a signature rather than a story, use the package API docs and the tested examples in the repository.',
                style: AppTypography.serif(
                  fontSize: 14,
                  height: 1.7,
                  color: AppTheme.ink.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartContents extends StatelessWidget {
  const _PartContents({
    required this.part,
    required this.chapters,
    required this.onOpen,
  });

  final String part;
  final List<BookChapter> chapters;
  final ValueChanged<BookChapter> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            part,
            style: AppTypography.sans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (final chapter in chapters)
            _ChapterRow(chapter: chapter, onOpen: () => onOpen(chapter)),
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.onOpen});

  final BookChapter chapter;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      semanticsLabel: 'Chapter ${chapter.number}: ${chapter.title}',
      onPress: onOpen,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => ColoredBox(
        color: states.contains(FTappableVariant.hovered)
            ? AppTheme.paleBlue
            : const Color(0x00000000),
        child: child!,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              child: Text(
                '${chapter.number}.',
                style: AppTypography.sans(
                  fontSize: 14,
                  color: AppTheme.ink.withValues(alpha: 0.48),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: AppTypography.serif(
                      fontSize: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter.outcome,
                    style: AppTypography.sans(
                      fontSize: 13,
                      height: 1.35,
                      color: AppTheme.ink.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
