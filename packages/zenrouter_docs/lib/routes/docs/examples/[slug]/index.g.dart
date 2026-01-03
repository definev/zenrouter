// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for ExamplesSlugRoute.
///
/// URI: /docs/examples/:slug
/// Layout: ExamplesLayout
abstract class _$ExamplesSlugRoute extends DocsRoute {
  /// Dynamic parameter from path segment.
  final String slug;

  _$ExamplesSlugRoute({required this.slug});

  @override
  Type? get layout => ExamplesLayout;

  @override
  Uri toUri() => Uri.parse('/docs/examples/$slug');

  @override
  List<Object?> get props => [slug];
}
