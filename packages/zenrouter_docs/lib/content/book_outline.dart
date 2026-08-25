library;

/// Navigation metadata parsed from one chapter's Markdown front matter.
class BookChapter {
  const BookChapter({
    required this.part,
    required this.number,
    required this.title,
    required this.outcome,
  });

  final String part;
  final int number;
  final String title;
  final String outcome;

  String get routePath => '/docs/chapter/chapter-$number';
}

/// The chapter filenames are the only ordering contract kept in Dart.
///
/// Titles, summaries, and part names live beside the prose in Markdown front
/// matter so editors do not need to change application code.
const bookChapterCount = 20;

List<BookChapter> _bookChapters = const [];

List<BookChapter> get bookChapters {
  if (_bookChapters.isEmpty) {
    throw StateError('Book content has not been loaded.');
  }
  return _bookChapters;
}

void registerBookChapters(Iterable<BookChapter> chapters) {
  _bookChapters = List<BookChapter>.unmodifiable(chapters);
}

List<String> get bookParts => [
  for (final chapter in bookChapters)
    if (!bookChapters
        .take(bookChapters.indexOf(chapter))
        .any((item) => item.part == chapter.part))
      chapter.part,
];

BookChapter? chapterForSlug(String slug) {
  final match = RegExp(r'^chapter-(\d+)$').firstMatch(slug);
  if (match == null) return null;
  final number = int.tryParse(match.group(1)!);
  if (number == null) return null;
  for (final chapter in bookChapters) {
    if (chapter.number == number) return chapter;
  }
  return null;
}

const legacyChapterNumbers = <String, int>{
  '/docs/paradigms/imperative': 2,
  '/docs/paradigms/declarative': 2,
  '/docs/paradigms/coordinator': 5,
  '/docs/paradigms/choosing': 2,
  '/docs/concepts/routes-and-paths': 3,
  '/docs/concepts/stack-management': 6,
  '/docs/concepts/uri-parsing': 9,
  '/docs/patterns/layouts': 7,
  '/docs/patterns/guards-redirects': 10,
  '/docs/patterns/deep-linking': 11,
  '/docs/patterns/query-parameters': 9,
  '/docs/file-routing/getting-started': 4,
  '/docs/file-routing/conventions': 12,
  '/docs/file-routing/dynamic-routes': 12,
  '/docs/file-routing/deferred-imports': 12,
  '/docs/examples/basic-navigation': 6,
  '/docs/examples/tab-bar': 17,
  '/docs/examples/deep-linking': 11,
  '/docs/examples/auth-flow': 16,
};

BookChapter? legacyChapterForPath(String path) {
  final number = legacyChapterNumbers[path];
  if (number == null) return null;
  for (final chapter in bookChapters) {
    if (chapter.number == number) return chapter;
  }
  return null;
}
