import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_docs/content/book_content.dart';
import 'package:zenrouter_docs/content/book_outline.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final content = await BookContentRepository.load();
    registerLoadedContent(content);
  });

  test('book chapters are ordered, unique, and complete', () {
    expect(bookChapters, hasLength(20));
    expect([
      for (final chapter in bookChapters) chapter.number,
    ], orderedEquals(List<int>.generate(20, (index) => index + 1)));
    expect({
      for (final chapter in bookChapters) chapter.routePath,
    }, hasLength(bookChapters.length));
    expect(bookParts, hasLength(5));
    for (final chapter in bookChapters) {
      expect(chapter.part, isNotEmpty);
      expect(chapter.title, isNotEmpty);
      expect(chapter.outcome, isNotEmpty);
    }
  });

  test('every route slug resolves to a chapter', () {
    for (final chapter in bookChapters) {
      final slug = chapter.routePath.split('/').last;
      expect(chapterForSlug(slug), same(chapter));
    }
  });

  test(
    'startup loads one outline and chapter requests share a cache',
    () async {
      final requested = <String>[];
      final repository = await BookContentRepository.load(
        assetLoader: (path) {
          requested.add(path);
          return rootBundle.loadString(path);
        },
      );

      expect(requested, ['assets/content/outline.md']);

      final firstLoad = repository.markdownFor(repository.chapters.first);
      final duplicateLoad = repository.markdownFor(repository.chapters.first);
      expect(identical(firstLoad, duplicateLoad), isTrue);
      expect(await firstLoad, isNotEmpty);
      expect(
        requested.where((path) => path.endsWith('chapter-01.md')),
        hasLength(1),
      );
      expect(
        requested.where((path) => path.endsWith('chapter-02.md')),
        isEmpty,
      );
    },
  );

  test('every Markdown chapter is long, structured, and actionable', () async {
    for (final chapter in bookChapters) {
      final number = chapter.number.toString().padLeft(2, '0');
      final source = await rootBundle.loadString(
        'assets/content/chapter-$number.md',
      );
      final words = source
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final sections = RegExp(
        r'^## ',
        multiLine: true,
      ).allMatches(source).length;

      expect(words, greaterThanOrEqualTo(500), reason: 'chapter $number');
      expect(sections, greaterThanOrEqualTo(4), reason: 'chapter $number');
      expect(source, contains('## Checkpoint'), reason: 'chapter $number');
      expect(source, contains('```'), reason: 'chapter $number');
    }
  });

  test('legacy paths resolve into the new learning journey', () {
    for (final entry in legacyChapterNumbers.entries) {
      final chapter = legacyChapterForPath(entry.key);
      expect(chapter, isNotNull, reason: entry.key);
      expect(chapter!.number, entry.value, reason: entry.key);
    }
  });
}
