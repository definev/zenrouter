library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/content/book_outline.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part 'index.g.dart';

@ZenRoute()
class IndexRoute extends _$IndexRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 720;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 52,
        56,
        compact ? 24 : 52,
        96,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(compact: compact, coordinator: coordinator),
              const SizedBox(height: 56),
              const _SectionHeading(
                eyebrow: 'LEARN THE MODEL',
                title: 'One path from first route to production graph',
                description:
                    'Each chapter answers one decision you will make while building a real Flutter app. Start at the beginning or jump to the seam you need today.',
              ),
              const SizedBox(height: 24),
              _LearningGrid(coordinator: coordinator),
              const SizedBox(height: 56),
              _QuickStartCard(coordinator: coordinator),
              const SizedBox(height: 56),
              const _SectionHeading(
                eyebrow: 'REFERENCE',
                title: 'Keep the contracts close',
                description:
                    'The same site also gives you the generated route graph, package boundaries, and runnable examples to verify a detail when the tutorial is not enough.',
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ReferenceChip(
                    icon: FLucideIcons.bookOpen,
                    label: 'Browse all chapters',
                    onPress: coordinator.pushDocsIndex,
                  ),
                  const _ReferenceChip(
                    icon: FLucideIcons.box,
                    label: 'Packages: zenrouter · core · devtools',
                  ),
                  const _ReferenceChip(
                    icon: FLucideIcons.flaskConical,
                    label: 'Examples and tested contracts',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.compact, required this.coordinator});

  final bool compact;
  final DocsCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.bookBlack,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bookBlack.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 24 : 48,
          compact ? 28 : 42,
          compact ? 24 : 48,
          compact ? 26 : 42,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppTheme.gold,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'ZENROUTER  ·  FLUTTER NAVIGATION',
                  style: AppTypography.sans(
                    color: const Color(0xFF8ED9F5),
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Navigation as\na typed graph.',
              style: AppTypography.sans(
                color: AppTheme.primaryForeground,
                fontSize: compact ? 38 : 58,
                height: 1.02,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 630),
              child: Text(
                'Keep screens, layouts, URLs, and browser history aligned through one typed graph. Start small, then grow the graph without string drift.',
                style: AppTypography.serif(
                  color: AppTheme.primaryForeground.withValues(alpha: 0.78),
                  fontSize: compact ? 14 : 16,
                  height: 1.75,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FButton(
                  onPress: () => coordinator.pushChapterSlug(slug: 'chapter-1'),
                  child: const Text('Start reading'),
                ),
                FButton(
                  variant: FButtonVariant.outline,
                  onPress: coordinator.pushDocsIndex,
                  child: const Text('View contents'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'RouteManifest  →  match  →  RouteBinding  →  StackPath  →  commit',
              style: AppTypography.mono(
                color: const Color(0xFF8ED9F5).withValues(alpha: 0.82),
                fontSize: compact ? 10 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTypography.sans(
            color: AppTheme.primary,
            fontSize: 11,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTypography.sans(
            color: AppTheme.ink,
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            description,
            style: AppTypography.serif(
              color: AppTheme.mutedInk,
              fontSize: 14,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningGrid extends StatelessWidget {
  const _LearningGrid({required this.coordinator});

  final DocsCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _LearningCardData(
        number: '01',
        title: 'Orient',
        body: 'Choose a model and understand the route graph in one screen.',
        chapter: bookChapters[0],
        icon: FLucideIcons.compass,
      ),
      _LearningCardData(
        number: '02',
        title: 'Build',
        body:
            'Create a typed home route, a parameterized detail route, and a URL contract.',
        chapter: bookChapters[3],
        icon: FLucideIcons.hammer,
      ),
      _LearningCardData(
        number: '03',
        title: 'Scale',
        body: 'Model tabs, policies, restoration, modules, and testable seams.',
        chapter: bookChapters[6],
        icon: FLucideIcons.network,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 700;
        Widget cardAt(int index) => _LearningCard(
          data: cards[index],
          onPress: () => coordinator.pushChapterSlug(
            slug: cards[index].chapter.routePath.split('/').last,
          ),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                cardAt(index),
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(width: 12),
                Expanded(child: cardAt(index)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LearningCardData {
  const _LearningCardData({
    required this.number,
    required this.title,
    required this.body,
    required this.chapter,
    required this.icon,
  });

  final String number;
  final String title;
  final String body;
  final BookChapter chapter;
  final IconData icon;
}

class _LearningCard extends StatelessWidget {
  const _LearningCard({required this.data, required this.onPress});

  final _LearningCardData data;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      semanticsLabel: 'Open ${data.title}: ${data.chapter.title}',
      onPress: onPress,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: states.contains(FTappableVariant.hovered)
              ? AppTheme.paleBlue
              : AppTheme.codeBackground,
          border: Border.all(
            color: states.contains(FTappableVariant.hovered)
                ? AppTheme.primary.withValues(alpha: 0.55)
                : AppTheme.divider,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 20, color: AppTheme.primary),
              const Spacer(),
              Text(
                data.number,
                style: AppTypography.mono(
                  fontSize: 11,
                  color: AppTheme.mutedInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            data.title,
            style: AppTypography.sans(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.body,
            style: AppTypography.sans(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.mutedInk,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Read chapter  →',
            style: AppTypography.sans(
              fontSize: 13,
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({required this.coordinator});

  final DocsCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.paleBlue,
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 650;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THE FASTEST FIRST WIN',
                style: AppTypography.sans(
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Get a URL-aware route on screen in 20 minutes.',
                style: AppTypography.sans(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add ZenRouter, define a manifest, bind a typed target, then open `/articles/42` directly in your browser.',
                style: AppTypography.serif(
                  fontSize: 13,
                  height: 1.7,
                  color: AppTheme.mutedInk,
                ),
              ),
              const SizedBox(height: 18),
              FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: () => coordinator.pushChapterSlug(slug: 'chapter-4'),
                child: const Text('Open the install guide'),
              ),
            ],
          );
          final code = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.bookBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "dependencies:\n  zenrouter: ^3.0.0-beta.1\n\nfinal uri =\n  coordinator.location.article('42');",
              style: AppTypography.mono(
                fontSize: 12,
                height: 1.55,
                color: const Color(0xFFB6E7F8),
              ),
            ),
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 24), code],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: copy),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: code),
            ],
          );
        },
      ),
    );
  }
}

class _ReferenceChip extends StatelessWidget {
  const _ReferenceChip({required this.icon, required this.label, this.onPress});

  final IconData icon;
  final String label;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 9),
          Text(
            label,
            style: AppTypography.sans(
              fontSize: 13,
              color: onPress == null ? AppTheme.mutedInk : AppTheme.primary,
              fontWeight: onPress == null ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onPress == null) return content;
    return FTappable.static(
      semanticsLabel: label,
      onPress: onPress,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => Opacity(
        opacity: states.contains(FTappableVariant.hovered) ? 0.75 : 1,
        child: child!,
      ),
      child: content,
    );
  }
}
