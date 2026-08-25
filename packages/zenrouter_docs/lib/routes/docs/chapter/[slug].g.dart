// GENERATED CODE - DO NOT MODIFY BY HAND

part of '[slug].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for ChapterSlugRoute.
///
/// URI: /docs/chapter/:slug
/// Layout: DocsLayout
abstract class _$ChapterSlugRoute extends DocsRoute {
  /// Dynamic parameter from path segment.
  final String slug;

  _$ChapterSlugRoute({required this.slug});

  @override
  Type? get layout => DocsLayout;

  @override
  Uri toUri() => Uri(pathSegments: ['', 'docs', 'chapter', slug]);

  @override
  List<Object?> get props => [slug];
}
