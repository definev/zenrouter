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
import 'profile/general.dart' deferred as profile_general;
import 'tabs/_layout.dart';
import 'tabs/feed/_layout.dart';
import 'tabs/feed/following/[...slugs]/[id].dart';
import 'tabs/feed/following/[...slugs]/about.dart';
import 'tabs/feed/following/[...slugs]/index.dart';
import 'tabs/feed/following/[postId].dart' deferred as tabs_feed_following_postId;
import 'tabs/feed/following/_layout.dart';
import 'tabs/feed/following/index.dart';
import 'tabs/feed/for-you/_layout.dart';
import 'tabs/feed/for-you/index.dart';
import 'tabs/feed/for-you/sheet.dart';
import 'tabs/profile.dart';
import 'tabs/settings.dart';

export 'package:zenrouter/zenrouter.dart';
export '(auth)/_layout.dart';
export '(auth)/login.dart';
export '(auth)/register.dart';
export 'about.dart';
export 'index.dart';
export 'not_found.dart';
export 'profile/[profileId]/collections/[collectionId].dart';
export 'profile/[profileId]/index.dart';
export 'tabs/_layout.dart';
export 'tabs/feed/_layout.dart';
export 'tabs/feed/following/[...slugs]/[id].dart';
export 'tabs/feed/following/[...slugs]/about.dart';
export 'tabs/feed/following/[...slugs]/index.dart';
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
  Future<AppRoute> parseRouteFromUri(Uri uri) async {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['tabs', 'feed', 'for-you', 'sheet'] => ForYouSheetRoute(),
      ['tabs', 'feed', 'following', final postId] => await () async { await tabs_feed_following_postId.loadLibrary(); return tabs_feed_following_postId.FeedPostRoute(postId: postId); }(),
      ['tabs', 'feed', 'following'] => FollowingRoute(),
      ['tabs', 'feed', 'for-you'] => ForYouRoute(),
      ['profile', final profileId, 'collections', final collectionId] => CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: uri.queryParameters),
      ['profile', 'general'] => await () async { await profile_general.loadLibrary(); return profile_general.ProfileGeneralRoute(); }(),
      ['tabs', 'profile'] => TabProfileRoute(),
      ['tabs', 'settings'] => TabSettingsRoute(),
      ['profile', final profileId] => ProfileIdRoute(profileId: profileId),
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(),
      ['about'] => AboutRoute(),
      ['tabs', 'feed', 'following', ...final slugs, 'about'] => FeedDynamicAboutRoute(slugs: slugs),
      ['tabs', 'feed', 'following', ...final slugs, final id] => FeedDynamicIdRoute(slugs: slugs, id: id),
      ['tabs', 'feed', 'following', ...final slugs] => FeedDynamicRoute(slugs: slugs),
      _ => NotFoundRoute(uri: uri, queries: uri.queryParameters),
    };
  }
}

/// Type-safe navigation extension methods.
extension AppCoordinatorNav on AppCoordinator {
  Future<T?> pushLogin<T extends Object>() => push(LoginRoute());
  Future<void> replaceLogin() => replace(LoginRoute());
  Future<void> recoverLogin() => recover(LoginRoute());
  Future<T?> pushRegister<T extends Object>() => push(RegisterRoute());
  Future<void> replaceRegister() => replace(RegisterRoute());
  Future<void> recoverRegister() => recover(RegisterRoute());
  Future<T?> pushAbout<T extends Object>() => push(AboutRoute());
  Future<void> replaceAbout() => replace(AboutRoute());
  Future<void> recoverAbout() => recover(AboutRoute());
  Future<T?> pushIndex<T extends Object>() => push(IndexRoute());
  Future<void> replaceIndex() => replace(IndexRoute());
  Future<void> recoverIndex() => recover(IndexRoute());
  Future<T?> pushCollectionsCollectionId<T extends Object>(String profileId, String collectionId, [Map<String, String> queries = const {}]) => push(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  Future<void> replaceCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => replace(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  Future<void> recoverCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => recover(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  Future<T?> pushProfileId<T extends Object>(String profileId) => push(ProfileIdRoute(profileId: profileId));
  Future<void> replaceProfileId(String profileId) => replace(ProfileIdRoute(profileId: profileId));
  Future<void> recoverProfileId(String profileId) => recover(ProfileIdRoute(profileId: profileId));
  Future<T?> pushProfileGeneral<T extends Object>() async => push(await () async { await profile_general.loadLibrary(); return profile_general.ProfileGeneralRoute(); }());
  Future<void> replaceProfileGeneral() async => replace(await () async { await profile_general.loadLibrary(); return profile_general.ProfileGeneralRoute(); }());
  Future<void> recoverProfileGeneral() async => recover(await () async { await profile_general.loadLibrary(); return profile_general.ProfileGeneralRoute(); }());
  Future<T?> pushFeedDynamicId<T extends Object>(List<String> slugs, String id) => push(FeedDynamicIdRoute(slugs: slugs, id: id));
  Future<void> replaceFeedDynamicId(List<String> slugs, String id) => replace(FeedDynamicIdRoute(slugs: slugs, id: id));
  Future<void> recoverFeedDynamicId(List<String> slugs, String id) => recover(FeedDynamicIdRoute(slugs: slugs, id: id));
  Future<T?> pushFeedDynamicAbout<T extends Object>(List<String> slugs) => push(FeedDynamicAboutRoute(slugs: slugs));
  Future<void> replaceFeedDynamicAbout(List<String> slugs) => replace(FeedDynamicAboutRoute(slugs: slugs));
  Future<void> recoverFeedDynamicAbout(List<String> slugs) => recover(FeedDynamicAboutRoute(slugs: slugs));
  Future<T?> pushFeedDynamic<T extends Object>(List<String> slugs) => push(FeedDynamicRoute(slugs: slugs));
  Future<void> replaceFeedDynamic(List<String> slugs) => replace(FeedDynamicRoute(slugs: slugs));
  Future<void> recoverFeedDynamic(List<String> slugs) => recover(FeedDynamicRoute(slugs: slugs));
  Future<T?> pushFeedPost<T extends Object>(String postId) async => push(await () async { await tabs_feed_following_postId.loadLibrary(); return tabs_feed_following_postId.FeedPostRoute(postId: postId); }());
  Future<void> replaceFeedPost(String postId) async => replace(await () async { await tabs_feed_following_postId.loadLibrary(); return tabs_feed_following_postId.FeedPostRoute(postId: postId); }());
  Future<void> recoverFeedPost(String postId) async => recover(await () async { await tabs_feed_following_postId.loadLibrary(); return tabs_feed_following_postId.FeedPostRoute(postId: postId); }());
  Future<T?> pushFollowing<T extends Object>() => push(FollowingRoute());
  Future<void> replaceFollowing() => replace(FollowingRoute());
  Future<void> recoverFollowing() => recover(FollowingRoute());
  Future<T?> pushForYou<T extends Object>() => push(ForYouRoute());
  Future<void> replaceForYou() => replace(ForYouRoute());
  Future<void> recoverForYou() => recover(ForYouRoute());
  Future<T?> pushForYouSheet<T extends Object>() => push(ForYouSheetRoute());
  Future<void> replaceForYouSheet() => replace(ForYouSheetRoute());
  Future<void> recoverForYouSheet() => recover(ForYouSheetRoute());
  Future<T?> pushTabProfile<T extends Object>() => push(TabProfileRoute());
  Future<void> replaceTabProfile() => replace(TabProfileRoute());
  Future<void> recoverTabProfile() => recover(TabProfileRoute());
  Future<T?> pushTabSettings<T extends Object>() => push(TabSettingsRoute());
  Future<void> replaceTabSettings() => replace(TabSettingsRoute());
  Future<void> recoverTabSettings() => recover(TabSettingsRoute());
}
