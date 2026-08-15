// GENERATED CODE - DO NOT MODIFY BY HAND

part of '_layout.dart';

// **************************************************************************
// LayoutGenerator
// **************************************************************************

/// Generated base class for FeedTabLayout.
///
/// URI: /tabs/feed
/// Path type: branched
/// Parent layout: TabsLayout
abstract class _$FeedTabLayout extends AppRoute with RouteLayout<AppRoute> {
  _$FeedTabLayout();

  @override
  Type? get layout => TabsLayout;

  @override
  BranchedStackPath<AppRoute> resolvePath(
    covariant AppCoordinator coordinator,
  ) => coordinator.feedTabPath;

  @override
  Uri toUri() => Uri.parse('/tabs/feed');

  @override
  List<Object?> get props => [];
}
