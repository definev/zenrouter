library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrouter_docs/content/book_outline.dart';
import 'package:zenrouter_docs/routes/docs/index.dart';
import 'package:zenrouter_docs/routes/index.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part '_layout.g.dart';

const _docsShellMaxWidth = 1400.0;

@ZenLayout(type: LayoutType.stack)
class RootLayout extends _$RootLayout {
  @override
  Type? get layout => null;

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return RootLayoutBuilder(child: buildPath(coordinator));
  }
}

/// The shared book chrome: a global header around one centered reading surface.
class RootLayoutBuilder extends StatelessWidget {
  const RootLayoutBuilder({super.key, required this.child});

  final Widget child;

  Future<void> _openGithub() =>
      launchUrl(Uri.parse('https://github.com/definev/zenrouter'));

  Future<void> _openChapter(
    DocsCoordinator coordinator,
    BookChapter chapter,
  ) async {
    final route = await coordinator.parseRouteFromUri(
      Uri.parse(chapter.routePath),
    );
    if (route != null) await coordinator.navigate(route);
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = DocsCoordinatorProvider.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return FScaffold(
      childPad: false,
      child: ColoredBox(
        color: AppTheme.canvas,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _DocsHeader(
                compact: width < 720,
                onHome: () => coordinator.navigate(IndexRoute()),
                onContents: () => coordinator.navigate(DocsIndexRoute()),
                onGithub: _openGithub,
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: coordinator,
                  child: child,
                  builder: (context, child) {
                    final currentPath = coordinator.currentUri.path;
                    final showSidebar =
                        width >= 960 &&
                        (currentPath == '/docs' ||
                            currentPath.startsWith('/docs/'));

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _docsShellMaxWidth,
                        ),
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppTheme.paper,
                            border: Border(
                              left: BorderSide(color: AppTheme.divider),
                              right: BorderSide(color: AppTheme.divider),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showSidebar)
                                _DocsSidebar(
                                  currentPath: currentPath,
                                  onOpen: (chapter) =>
                                      _openChapter(coordinator, chapter),
                                ),
                              Expanded(child: child!),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocsHeader extends StatelessWidget {
  const _DocsHeader({
    required this.compact,
    required this.onHome,
    required this.onContents,
    required this.onGithub,
  });

  final bool compact;
  final VoidCallback onHome;
  final VoidCallback onContents;
  final VoidCallback onGithub;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppTheme.paper,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _docsShellMaxWidth),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
              child: Row(
                children: [
                  _HeaderLink(
                    label: 'ZenRouter home',
                    onPress: onHome,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            FLucideIcons.gitBranch,
                            size: 17,
                            color: AppTheme.primaryForeground,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Zen',
                                style: AppTypography.sans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: 'Router',
                                style: AppTypography.sans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 24),
                    Container(width: 1, height: 24, color: AppTheme.divider),
                    const SizedBox(width: 18),
                    _HeaderLink(
                      label: 'Documentation contents',
                      onPress: onContents,
                      child: Text(
                        'Documentation',
                        style: AppTypography.sans(
                          fontSize: 14,
                          color: AppTheme.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  _HeaderLink(
                    label: 'GitHub repository',
                    onPress: onGithub,
                    child: Icon(
                      FLucideIcons.code2,
                      size: 20,
                      color: AppTheme.ink.withValues(alpha: 0.72),
                    ),
                  ),
                  if (compact) ...[
                    const SizedBox(width: 12),
                    _HeaderLink(
                      label: 'Documentation contents',
                      onPress: onContents,
                      child: const Icon(
                        FLucideIcons.menu,
                        size: 21,
                        color: AppTheme.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocsSidebar extends StatelessWidget {
  const _DocsSidebar({required this.currentPath, required this.onOpen});

  final String currentPath;
  final ValueChanged<BookChapter> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 272,
      decoration: const BoxDecoration(
        color: AppTheme.sidebar,
        border: Border(right: BorderSide(color: AppTheme.divider)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final part in bookParts)
              _SidebarPart(
                part: part,
                chapters: bookChapters
                    .where((chapter) => chapter.part == part)
                    .toList(),
                currentPath: currentPath,
                onOpen: onOpen,
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarPart extends StatelessWidget {
  const _SidebarPart({
    required this.part,
    required this.chapters,
    required this.currentPath,
    required this.onOpen,
  });

  final String part;
  final List<BookChapter> chapters;
  final String currentPath;
  final ValueChanged<BookChapter> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(
              part.toUpperCase(),
              style: AppTypography.sans(
                fontSize: 10,
                height: 1.3,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: AppTheme.mutedInk,
              ),
            ),
          ),
          for (final chapter in chapters)
            _SidebarChapter(
              chapter: chapter,
              selected: chapter.routePath == currentPath,
              onOpen: () => onOpen(chapter),
            ),
        ],
      ),
    );
  }
}

class _SidebarChapter extends StatelessWidget {
  const _SidebarChapter({
    required this.chapter,
    required this.selected,
    required this.onOpen,
  });

  final BookChapter chapter;
  final bool selected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      semanticsLabel: 'Chapter ${chapter.number}: ${chapter.title}',
      onPress: onOpen,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.paleBlue
              : states.contains(FTappableVariant.hovered)
              ? AppTheme.paper
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child!,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          '${chapter.number}. ${chapter.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sans(
            fontSize: 13,
            height: 1.25,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : AppTheme.ink,
          ),
        ),
      ),
    );
  }
}

class _HeaderLink extends StatelessWidget {
  const _HeaderLink({
    required this.label,
    required this.onPress,
    required this.child,
  });

  final String label;
  final VoidCallback onPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      semanticsLabel: label,
      onPress: onPress,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => Padding(
        padding: const EdgeInsets.all(6),
        child: Opacity(
          opacity: states.contains(FTappableVariant.hovered) ? 0.72 : 1,
          child: child!,
        ),
      ),
      child: child,
    );
  }
}
