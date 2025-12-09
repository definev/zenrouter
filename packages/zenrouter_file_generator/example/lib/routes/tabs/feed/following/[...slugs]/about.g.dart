// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for FeedDynamicAboutRoute.
///
/// URI: /tabs/feed/following/...:slugs/about
/// Layout: FollowingLayout
abstract class _$FeedDynamicAboutRoute extends AppRoute {
  /// Dynamic parameter from path segment.
  final List<String> slugs;

  _$FeedDynamicAboutRoute({required this.slugs});

  @override
  Type? get layout => FollowingLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/feed/following/${slugs.join('/')}/about');

  @override
  List<Object?> get props => [slugs];
}
