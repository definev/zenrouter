library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrouter_docs/content/book_content.dart';
import 'package:zenrouter_docs/content/book_outline.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/chapter_navigation.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_docs/widgets/mardown_section.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part '[slug].g.dart';

@ZenRoute()
class ChapterSlugRoute extends _$ChapterSlugRoute with RouteSeo {
  ChapterSlugRoute({required super.slug});

  BookChapter? get chapter => chapterForSlug(slug);

  @override
  String get title => chapter?.title ?? 'Chapter not found';

  @override
  String get description =>
      chapter?.outcome ?? 'The requested ZenRouter chapter does not exist.';

  @override
  String get keywords => 'ZenRouter, Flutter, navigation, ${chapter?.title}';

  Future<void> _openUri(DocsCoordinator coordinator, Uri uri) async {
    if (uri.hasScheme) {
      await launchUrl(uri);
      return;
    }

    final route = await coordinator.parseRouteFromUri(uri);
    if (route != null) await coordinator.navigate(route);
  }

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);
    final current = chapter;

    if (current != null) {
      return _LazyChapterPage(
        chapter: current,
        coordinator: coordinator,
        tocController: tocController,
        onOpenUri: (uri) => _openUri(coordinator, uri),
      );
    }

    return DocPage(
      title: 'Chapter not found',
      subtitle: 'The requested chapter does not exist',
      tocController: tocController,
      onOpenUri: (uri) => _openUri(coordinator, uri),
      markdown:
          '''
The chapter **$slug** does not exist.

Return to [Contents](/docs) and choose one of the numbered chapters.
''',
    );
  }
}

class _LazyChapterPage extends StatefulWidget {
  const _LazyChapterPage({
    required this.chapter,
    required this.coordinator,
    required this.tocController,
    required this.onOpenUri,
  });

  final BookChapter chapter;
  final DocsCoordinator coordinator;
  final TocController? tocController;
  final ValueChanged<Uri> onOpenUri;

  @override
  State<_LazyChapterPage> createState() => _LazyChapterPageState();
}

class _LazyChapterPageState extends State<_LazyChapterPage> {
  BookContentRepository? _repository;
  Future<String>? _markdown;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = DocsContentScope.of(context);
    if (identical(repository, _repository) && _markdown != null) return;
    _repository = repository;
    _markdown = repository.markdownFor(widget.chapter);
  }

  @override
  void didUpdateWidget(covariant _LazyChapterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.number == widget.chapter.number) return;
    _markdown = _repository?.markdownFor(widget.chapter);
  }

  void _retry() {
    setState(() {
      _markdown = _repository!.reload(widget.chapter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigation = ChapterNavigation(
      chapter: widget.chapter,
      coordinator: widget.coordinator,
    );
    final subtitle =
        '${widget.chapter.part}  /  Chapter ${widget.chapter.number.toString().padLeft(2, '0')}';

    return FutureBuilder<String>(
      future: _markdown,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _repository!.prefetchNeighbors(widget.chapter);
          return DocPage(
            title: widget.chapter.title,
            subtitle: subtitle,
            tocController: widget.tocController,
            onOpenUri: widget.onOpenUri,
            chapterNavigation: navigation,
            markdown: snapshot.data!,
          );
        }

        if (snapshot.hasError) {
          return DocPage(
            title: widget.chapter.title,
            subtitle: subtitle,
            tocController: widget.tocController,
            chapterNavigation: navigation,
            markdown:
                'The chapter could not be loaded. Check the connection and try again.',
            bottomWidget: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: FButton(
                onPress: _retry,
                child: const Text('Retry chapter'),
              ),
            ),
          );
        }

        return DocPage(
          title: widget.chapter.title,
          subtitle: subtitle,
          tocController: widget.tocController,
          chapterNavigation: navigation,
          markdown: 'Loading this chapter…',
        );
      },
    );
  }
}
