// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for FeedDynamicRoute.
///
/// URI: /tabs/feed/following/...:slugs
/// Layout: FollowingLayout
abstract class _$FeedDynamicRoute extends AppRoute {
  /// Dynamic parameter from path segment.
  final List<String> slugs;

  _$FeedDynamicRoute({required this.slugs});

  @override
  Type? get layout => FollowingLayout;

  @override
  Uri toUri() => Uri(pathSegments: ['', 'tabs', 'feed', 'following', ...slugs]);

  @override
  List<Object?> get props => [slugs];
}
