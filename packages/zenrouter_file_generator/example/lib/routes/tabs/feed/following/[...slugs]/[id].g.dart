// GENERATED CODE - DO NOT MODIFY BY HAND

part of '[id].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for FeedDynamicIdRoute.
///
/// URI: /tabs/feed/following/...:slugs/:id
/// Layout: FollowingLayout
abstract class _$FeedDynamicIdRoute extends AppRoute {
  /// Dynamic parameter from path segment.
  final List<String> slugs;

  /// Dynamic parameter from path segment.
  final String id;

  _$FeedDynamicIdRoute({required this.slugs, required this.id});

  @override
  Type? get layout => FollowingLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/feed/following/${slugs.join('/')}/$id');

  @override
  List<Object?> get props => [slugs, id];
}
