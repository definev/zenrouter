// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog.[...slugs].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for BlogSlugsRoute.
///
/// URI: /blog/...:slugs
abstract class _$BlogSlugsRoute extends AppRoute {
  /// Dynamic parameter from path segment.
  final List<String> slugs;

  _$BlogSlugsRoute({required this.slugs});

  @override
  Uri toUri() => Uri.parse('/blog/${slugs.join('/')}');

  @override
  List<Object?> get props => [slugs];
}
