// GENERATED CODE - DO NOT MODIFY BY HAND

part of '[postId].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for FeedPostRoute.
///
/// URI: /tabs/feed/following/:postId
/// Layout: FollowingLayout
abstract class _$FeedPostRoute extends AppRoute with RouteGuard, RouteDeepLink {
  /// Dynamic parameter from path segment.
  final String postId;

  _$FeedPostRoute({required this.postId});

  @override
  Type? get layout => FollowingLayout;

  @override
  Uri toUri() => Uri.parse('/tabs/feed/following/$postId');

  @override
  List<Object?> get props => [postId];

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
}
