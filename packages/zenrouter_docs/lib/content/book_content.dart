/// Lazily loaded Markdown documentation content.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:zenrouter_docs/content/book_outline.dart';

typedef DocumentationAssetLoader = Future<String> Function(String path);

/// Loads the small navigation outline once, then fetches chapter bodies only
/// when they are opened.
///
/// In-flight and completed chapter loads share the same cached [Future], so a
/// rebuild or a second reader never starts a duplicate asset request.
class BookContentRepository {
  BookContentRepository._(this.chapters, this._loadAsset);

  final List<BookChapter> chapters;
  final DocumentationAssetLoader _loadAsset;
  final Map<int, Future<String>> _chapterLoads = {};

  static Future<BookContentRepository> load({
    DocumentationAssetLoader? assetLoader,
  }) async {
    final loadAsset = assetLoader ?? rootBundle.loadString;
    final outline = await loadAsset('assets/content/outline.md');
    return BookContentRepository._(_parseOutline(outline), loadAsset);
  }

  static List<BookChapter> _parseOutline(String source) {
    final chapters = <BookChapter>[];
    final numbers = <int>{};
    String? currentPart;

    for (final rawLine in source.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trim();
      final partMatch = RegExp(r'^##\s+(.+)$').firstMatch(line);
      if (partMatch != null) {
        currentPart = partMatch.group(1)!.trim();
        continue;
      }

      final chapterMatch = RegExp(
        r'^-\s+(\d{2})\s+\|\s+([^|]+?)\s+\|\s+(.+)$',
      ).firstMatch(line);
      if (chapterMatch == null) continue;
      if (currentPart == null) {
        throw const FormatException('A chapter must follow a part heading.');
      }

      final number = int.parse(chapterMatch.group(1)!);
      if (!numbers.add(number)) {
        throw FormatException('Duplicate chapter number $number.');
      }
      chapters.add(
        BookChapter(
          part: currentPart,
          number: number,
          title: chapterMatch.group(2)!.trim(),
          outcome: chapterMatch.group(3)!.trim(),
        ),
      );
    }

    if (chapters.length != bookChapterCount) {
      throw FormatException(
        'Expected $bookChapterCount outline chapters, found ${chapters.length}.',
      );
    }
    for (var index = 0; index < chapters.length; index++) {
      final expected = index + 1;
      if (chapters[index].number != expected) {
        throw FormatException(
          'Expected chapter $expected at outline position ${index + 1}.',
        );
      }
    }

    return List<BookChapter>.unmodifiable(chapters);
  }

  Future<String> markdownFor(BookChapter chapter) =>
      _chapterLoads.putIfAbsent(chapter.number, () async {
        final number = chapter.number.toString().padLeft(2, '0');
        final markdown = (await _loadAsset(
          'assets/content/chapter-$number.md',
        )).trim();
        if (markdown.isEmpty) {
          throw FormatException('Chapter $number has no Markdown body.');
        }
        return markdown;
      });

  /// Warms adjacent chapters after the current chapter is visible.
  void prefetchNeighbors(BookChapter chapter) {
    final index = chapters.indexOf(chapter);
    if (index < 0) return;
    for (final neighbor in [
      if (index > 0) chapters[index - 1],
      if (index + 1 < chapters.length) chapters[index + 1],
    ]) {
      unawaited(markdownFor(neighbor).catchError((_) => ''));
    }
  }

  Future<String> reload(BookChapter chapter) {
    _chapterLoads.remove(chapter.number);
    return markdownFor(chapter);
  }
}

/// Makes the loaded outline and lazy chapter cache available to route widgets.
class DocsContentScope extends InheritedWidget {
  const DocsContentScope({
    super.key,
    required this.content,
    required super.child,
  });

  final BookContentRepository content;

  static BookContentRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocsContentScope>()!.content;

  @override
  bool updateShouldNotify(DocsContentScope oldWidget) =>
      content != oldWidget.content;
}

void registerLoadedContent(BookContentRepository content) {
  registerBookChapters(content.chapters);
}
