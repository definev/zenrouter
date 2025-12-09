// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:zenrouter/zenrouter.dart';

import '(auth)/_layout.dart';
import '(auth)/login.dart';
import '(auth)/register.dart';
import 'about.dart';
import 'index.dart';
import 'not_found.dart';
import 'profile/[profileId]/collections/[collectionId].dart';
import 'profile/[profileId]/index.dart';
import 'profile/general.dart';
import 'tabs/_layout.dart';
import 'tabs/feed/_layout.dart';
import 'tabs/feed/following/[postId].dart';
import 'tabs/feed/following/_layout.dart';
import 'tabs/feed/following/index.dart';
import 'tabs/feed/for-you/_layout.dart';
import 'tabs/feed/for-you/index.dart';
import 'tabs/feed/for-you/sheet.dart';
import 'tabs/profile.dart';
import 'tabs/settings.dart';

export '(auth)/_layout.dart';
export '(auth)/login.dart';
export '(auth)/register.dart';
export 'about.dart';
export 'index.dart';
export 'not_found.dart';
export 'profile/[profileId]/collections/[collectionId].dart';
export 'profile/[profileId]/index.dart';
export 'profile/general.dart';
export 'tabs/_layout.dart';
export 'tabs/feed/_layout.dart';
export 'tabs/feed/following/[postId].dart';
export 'tabs/feed/following/_layout.dart';
export 'tabs/feed/following/index.dart';
export 'tabs/feed/for-you/_layout.dart';
export 'tabs/feed/for-you/index.dart';
export 'tabs/feed/for-you/sheet.dart';
export 'tabs/profile.dart';
export 'tabs/settings.dart';

/// Base class for all routes in this application.
abstract class AppRoute extends RouteTarget with RouteUnique {}

/// Generated coordinator managing all routes.
class AppCoordinator extends Coordinator<AppRoute> {
  final NavigationPath<AppRoute> authPath = NavigationPath('Auth');
  final IndexedStackPath<AppRoute> tabsPath = IndexedStackPath([
    FeedTabLayout(), TabProfileRoute(), TabSettingsRoute(),
  ], 'Tabs');
  final IndexedStackPath<AppRoute> feedTabPath = IndexedStackPath([
    FollowingLayout(), ForYouLayout(),
  ], 'FeedTab');
  final NavigationPath<AppRoute> followingPath = NavigationPath('Following');
  final NavigationPath<AppRoute> forYouPath = NavigationPath('ForYou');

  @override
  List<StackPath> get paths => [root, authPath, tabsPath, feedTabPath, followingPath, forYouPath];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(AuthLayout, () => AuthLayout());
    RouteLayout.defineLayout(TabsLayout, () => TabsLayout());
    RouteLayout.defineLayout(FeedTabLayout, () => FeedTabLayout());
    RouteLayout.defineLayout(FollowingLayout, () => FollowingLayout());
    RouteLayout.defineLayout(ForYouLayout, () => ForYouLayout());
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['tabs', 'feed', 'for-you', 'sheet'] => ForYouSheetRoute(),
      ['tabs', 'feed', 'following', final postId] => FeedPostRoute(postId: postId),
      ['profile', final profileId, 'collections', final collectionId] => CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: uri.queryParameters),
      ['tabs', 'feed', 'following'] => FollowingRoute(),
      ['tabs', 'feed', 'for-you'] => ForYouRoute(),
      ['profile', 'general'] => ProfileGeneralRoute(),
      ['tabs', 'profile'] => TabProfileRoute(),
      ['tabs', 'settings'] => TabSettingsRoute(),
      ['profile', final profileId] => ProfileIdRoute(profileId: profileId),
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(),
      ['about'] => AboutRoute(),
      _ => NotFoundRoute(uri: uri, queries: uri.queryParameters),
    };
  }
}

/// Type-safe navigation extension methods.
extension AppCoordinatorNav on AppCoordinator {
  Future<dynamic> pushLogin() => push(LoginRoute());
  void replaceLogin() => replace(LoginRoute());
  void recoverLogin() => recover(LoginRoute());
  Future<dynamic> pushRegister() => push(RegisterRoute());
  void replaceRegister() => replace(RegisterRoute());
  void recoverRegister() => recover(RegisterRoute());
  Future<dynamic> pushAbout() => push(AboutRoute());
  void replaceAbout() => replace(AboutRoute());
  void recoverAbout() => recover(AboutRoute());
  Future<dynamic> pushIndex() => push(IndexRoute());
  void replaceIndex() => replace(IndexRoute());
  void recoverIndex() => recover(IndexRoute());
  Future<dynamic> pushCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => push(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  void replaceCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => replace(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  void recoverCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => recover(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  Future<dynamic> pushProfileId(String profileId) => push(ProfileIdRoute(profileId: profileId));
  void replaceProfileId(String profileId) => replace(ProfileIdRoute(profileId: profileId));
  void recoverProfileId(String profileId) => recover(ProfileIdRoute(profileId: profileId));
  Future<dynamic> pushProfileGeneral() => push(ProfileGeneralRoute());
  void replaceProfileGeneral() => replace(ProfileGeneralRoute());
  void recoverProfileGeneral() => recover(ProfileGeneralRoute());
  Future<dynamic> pushFeedPost(String postId) => push(FeedPostRoute(postId: postId));
  void replaceFeedPost(String postId) => replace(FeedPostRoute(postId: postId));
  void recoverFeedPost(String postId) => recover(FeedPostRoute(postId: postId));
  Future<dynamic> pushFollowing() => push(FollowingRoute());
  void replaceFollowing() => replace(FollowingRoute());
  void recoverFollowing() => recover(FollowingRoute());
  Future<dynamic> pushForYou() => push(ForYouRoute());
  void replaceForYou() => replace(ForYouRoute());
  void recoverForYou() => recover(ForYouRoute());
  Future<dynamic> pushForYouSheet() => push(ForYouSheetRoute());
  void replaceForYouSheet() => replace(ForYouSheetRoute());
  void recoverForYouSheet() => recover(ForYouSheetRoute());
  Future<dynamic> pushTabProfile() => push(TabProfileRoute());
  void replaceTabProfile() => replace(TabProfileRoute());
  void recoverTabProfile() => recover(TabProfileRoute());
  Future<dynamic> pushTabSettings() => push(TabSettingsRoute());
  void replaceTabSettings() => replace(TabSettingsRoute());
  void recoverTabSettings() => recover(TabSettingsRoute());
}
