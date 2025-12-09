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
import 'tabs/feed/following/[...slugs]/[id].dart';
import 'tabs/feed/following/[...slugs]/about.dart';
import 'tabs/feed/following/[...slugs]/index.dart';
import 'tabs/feed/following/[postId].dart';
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
export 'profile/general.dart';
export 'tabs/_layout.dart';
export 'tabs/feed/_layout.dart';
export 'tabs/feed/following/[...slugs]/[id].dart';
export 'tabs/feed/following/[...slugs]/about.dart';
export 'tabs/feed/following/[...slugs]/index.dart';
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
      ['tabs', 'feed', 'following'] => FollowingRoute(),
      ['tabs', 'feed', 'for-you'] => ForYouRoute(),
      ['profile', final profileId, 'collections', final collectionId] => CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: uri.queryParameters),
      ['profile', 'general'] => ProfileGeneralRoute(),
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
  void replaceLogin() => replace(LoginRoute());
  void recoverLogin() => recover(LoginRoute());
  Future<T?> pushRegister<T extends Object>() => push(RegisterRoute());
  void replaceRegister() => replace(RegisterRoute());
  void recoverRegister() => recover(RegisterRoute());
  Future<T?> pushAbout<T extends Object>() => push(AboutRoute());
  void replaceAbout() => replace(AboutRoute());
  void recoverAbout() => recover(AboutRoute());
  Future<T?> pushIndex<T extends Object>() => push(IndexRoute());
  void replaceIndex() => replace(IndexRoute());
  void recoverIndex() => recover(IndexRoute());
  Future<T?> pushCollectionsCollectionId<T extends Object>(String profileId, String collectionId, [Map<String, String> queries = const {}]) => push(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  void replaceCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => replace(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  void recoverCollectionsCollectionId(String profileId, String collectionId, [Map<String, String> queries = const {}]) => recover(CollectionsCollectionIdRoute(profileId: profileId, collectionId: collectionId, queries: queries));
  Future<T?> pushProfileId<T extends Object>(String profileId) => push(ProfileIdRoute(profileId: profileId));
  void replaceProfileId(String profileId) => replace(ProfileIdRoute(profileId: profileId));
  void recoverProfileId(String profileId) => recover(ProfileIdRoute(profileId: profileId));
  Future<T?> pushProfileGeneral<T extends Object>() => push(ProfileGeneralRoute());
  void replaceProfileGeneral() => replace(ProfileGeneralRoute());
  void recoverProfileGeneral() => recover(ProfileGeneralRoute());
  Future<T?> pushFeedDynamicId<T extends Object>(List<String> slugs, String id) => push(FeedDynamicIdRoute(slugs: slugs, id: id));
  void replaceFeedDynamicId(List<String> slugs, String id) => replace(FeedDynamicIdRoute(slugs: slugs, id: id));
  void recoverFeedDynamicId(List<String> slugs, String id) => recover(FeedDynamicIdRoute(slugs: slugs, id: id));
  Future<T?> pushFeedDynamicAbout<T extends Object>(List<String> slugs) => push(FeedDynamicAboutRoute(slugs: slugs));
  void replaceFeedDynamicAbout(List<String> slugs) => replace(FeedDynamicAboutRoute(slugs: slugs));
  void recoverFeedDynamicAbout(List<String> slugs) => recover(FeedDynamicAboutRoute(slugs: slugs));
  Future<T?> pushFeedDynamic<T extends Object>(List<String> slugs) => push(FeedDynamicRoute(slugs: slugs));
  void replaceFeedDynamic(List<String> slugs) => replace(FeedDynamicRoute(slugs: slugs));
  void recoverFeedDynamic(List<String> slugs) => recover(FeedDynamicRoute(slugs: slugs));
  Future<T?> pushFeedPost<T extends Object>(String postId) => push(FeedPostRoute(postId: postId));
  void replaceFeedPost(String postId) => replace(FeedPostRoute(postId: postId));
  void recoverFeedPost(String postId) => recover(FeedPostRoute(postId: postId));
  Future<T?> pushFollowing<T extends Object>() => push(FollowingRoute());
  void replaceFollowing() => replace(FollowingRoute());
  void recoverFollowing() => recover(FollowingRoute());
  Future<T?> pushForYou<T extends Object>() => push(ForYouRoute());
  void replaceForYou() => replace(ForYouRoute());
  void recoverForYou() => recover(ForYouRoute());
  Future<T?> pushForYouSheet<T extends Object>() => push(ForYouSheetRoute());
  void replaceForYouSheet() => replace(ForYouSheetRoute());
  void recoverForYouSheet() => recover(ForYouSheetRoute());
  Future<T?> pushTabProfile<T extends Object>() => push(TabProfileRoute());
  void replaceTabProfile() => replace(TabProfileRoute());
  void recoverTabProfile() => recover(TabProfileRoute());
  Future<T?> pushTabSettings<T extends Object>() => push(TabSettingsRoute());
  void replaceTabSettings() => replace(TabSettingsRoute());
  void recoverTabSettings() => recover(TabSettingsRoute());
}
