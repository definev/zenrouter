// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:zenrouter/zenrouter.dart';

import '(auth)/_layout.dart';
import '(auth)/login.dart' deferred as _auth_login;
import '(auth)/register.dart' deferred as _auth_register;
import 'about.dart' deferred as about;
import 'index.dart' deferred as index;
import 'not_found.dart';
import 'profile/[profileId]/collections/[collectionId].dart'
    deferred as profile__profileId_collections__collectionId;
import 'profile/[profileId]/index.dart' deferred as profile__profileId_index;
import 'profile/general.dart' deferred as profile_general;
import 'tabs/_layout.dart';
import 'tabs/feed/_layout.dart';
import 'tabs/feed/following/[...slugs]/[id].dart'
    deferred as tabs_feed_following___slugs__id;
import 'tabs/feed/following/[...slugs]/about.dart'
    deferred as tabs_feed_following___slugs_about;
import 'tabs/feed/following/[...slugs]/index.dart'
    deferred as tabs_feed_following___slugs_index;
import 'tabs/feed/following/[postId].dart'
    deferred as tabs_feed_following__postId;
import 'tabs/feed/following/_layout.dart';
import 'tabs/feed/following/index.dart' deferred as tabs_feed_following_index;
import 'tabs/feed/for-you/_layout.dart';
import 'tabs/feed/for-you/index.dart' deferred as tabs_feed_foryou_index;
import 'tabs/feed/for-you/sheet.dart' deferred as tabs_feed_foryou_sheet;
import 'tabs/profile.dart';
import 'tabs/settings.dart';

export 'package:zenrouter/zenrouter.dart';
export '(auth)/_layout.dart';
export 'not_found.dart';
export 'tabs/_layout.dart';
export 'tabs/feed/_layout.dart';
export 'tabs/feed/following/_layout.dart';
export 'tabs/feed/for-you/_layout.dart';
export 'tabs/profile.dart';
export 'tabs/settings.dart';

/// Base class for all routes in this application.
abstract class AppRoute extends RouteTarget with RouteUnique {}

/// Generated coordinator managing all routes.
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> authPath = NavigationPath.createWith(
    label: 'Auth',
    coordinator: this,
  );
  late final IndexedStackPath<AppRoute> tabsPath = IndexedStackPath.createWith(
    coordinator: this,
    label: 'Tabs',
    [FeedTabLayout(), TabProfileRoute(), TabSettingsRoute()],
  );
  late final IndexedStackPath<AppRoute> feedTabPath =
      IndexedStackPath.createWith(coordinator: this, label: 'FeedTab', [
        FollowingLayout(),
        ForYouLayout(),
      ]);
  late final NavigationPath<AppRoute> followingPath = NavigationPath.createWith(
    label: 'Following',
    coordinator: this,
  );
  late final NavigationPath<AppRoute> forYouPath = NavigationPath.createWith(
    label: 'ForYou',
    coordinator: this,
  );

  @override
  List<StackPath> get paths => [
    root,
    authPath,
    tabsPath,
    feedTabPath,
    followingPath,
    forYouPath,
  ];

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
      [] => await () async {
        await index.loadLibrary();
        return index.IndexRoute();
      }(),
      ['tabs', 'feed', 'for-you', 'sheet'] => await () async {
        await tabs_feed_foryou_sheet.loadLibrary();
        return tabs_feed_foryou_sheet.ForYouSheetRoute();
      }(),
      ['tabs', 'feed', 'following', final postId] => await () async {
        await tabs_feed_following__postId.loadLibrary();
        return tabs_feed_following__postId.FeedPostRoute(postId: postId);
      }(),
      ['tabs', 'feed', 'following'] => await () async {
        await tabs_feed_following_index.loadLibrary();
        return tabs_feed_following_index.FollowingRoute();
      }(),
      ['tabs', 'feed', 'for-you'] => await () async {
        await tabs_feed_foryou_index.loadLibrary();
        return tabs_feed_foryou_index.ForYouRoute();
      }(),
      ['profile', final profileId, 'collections', final collectionId] =>
        await () async {
          await profile__profileId_collections__collectionId.loadLibrary();
          return profile__profileId_collections__collectionId.CollectionsCollectionIdRoute(
            profileId: profileId,
            collectionId: collectionId,
            queries: uri.queryParameters,
          );
        }(),
      ['profile', 'general'] => await () async {
        await profile_general.loadLibrary();
        return profile_general.ProfileGeneralRoute();
      }(),
      ['tabs', 'profile'] => TabProfileRoute(),
      ['tabs', 'settings'] => TabSettingsRoute(),
      ['profile', final profileId] => await () async {
        await profile__profileId_index.loadLibrary();
        return profile__profileId_index.ProfileIdRoute(profileId: profileId);
      }(),
      ['login'] => await () async {
        await _auth_login.loadLibrary();
        return _auth_login.LoginRoute();
      }(),
      ['register'] => await () async {
        await _auth_register.loadLibrary();
        return _auth_register.RegisterRoute();
      }(),
      ['about'] => await () async {
        await about.loadLibrary();
        return about.AboutRoute();
      }(),
      ['tabs', 'feed', 'following', ...final slugs, 'about'] => await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: slugs,
        );
      }(),
      ['tabs', 'feed', 'following', ...final slugs, final id] =>
        await () async {
          await tabs_feed_following___slugs__id.loadLibrary();
          return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
            slugs: slugs,
            id: id,
          );
        }(),
      ['tabs', 'feed', 'following', ...final slugs] => await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
      }(),
      _ => NotFoundRoute(uri: uri, queries: uri.queryParameters),
    };
  }
}

/// Type-safe navigation extension methods.
extension AppCoordinatorNav on AppCoordinator {
  Future<T?> pushLogin<T extends Object>() async => push(await () async {
    await _auth_login.loadLibrary();
    return _auth_login.LoginRoute();
  }());
  Future<void> replaceLogin() async => replace(await () async {
    await _auth_login.loadLibrary();
    return _auth_login.LoginRoute();
  }());
  Future<void> recoverLogin() async => recover(await () async {
    await _auth_login.loadLibrary();
    return _auth_login.LoginRoute();
  }());
  Future<T?> pushRegister<T extends Object>() async => push(await () async {
    await _auth_register.loadLibrary();
    return _auth_register.RegisterRoute();
  }());
  Future<void> replaceRegister() async => replace(await () async {
    await _auth_register.loadLibrary();
    return _auth_register.RegisterRoute();
  }());
  Future<void> recoverRegister() async => recover(await () async {
    await _auth_register.loadLibrary();
    return _auth_register.RegisterRoute();
  }());
  Future<T?> pushAbout<T extends Object>() async => push(await () async {
    await about.loadLibrary();
    return about.AboutRoute();
  }());
  Future<void> replaceAbout() async => replace(await () async {
    await about.loadLibrary();
    return about.AboutRoute();
  }());
  Future<void> recoverAbout() async => recover(await () async {
    await about.loadLibrary();
    return about.AboutRoute();
  }());
  Future<T?> pushIndex<T extends Object>() async => push(await () async {
    await index.loadLibrary();
    return index.IndexRoute();
  }());
  Future<void> replaceIndex() async => replace(await () async {
    await index.loadLibrary();
    return index.IndexRoute();
  }());
  Future<void> recoverIndex() async => recover(await () async {
    await index.loadLibrary();
    return index.IndexRoute();
  }());
  Future<T?> pushCollectionsCollectionId<T extends Object>(
    String profileId,
    String collectionId, [
    Map<String, String> queries = const {},
  ]) async => push(await () async {
    await profile__profileId_collections__collectionId.loadLibrary();
    return profile__profileId_collections__collectionId.CollectionsCollectionIdRoute(
      profileId: profileId,
      collectionId: collectionId,
      queries: queries,
    );
  }());
  Future<void> replaceCollectionsCollectionId(
    String profileId,
    String collectionId, [
    Map<String, String> queries = const {},
  ]) async => replace(await () async {
    await profile__profileId_collections__collectionId.loadLibrary();
    return profile__profileId_collections__collectionId.CollectionsCollectionIdRoute(
      profileId: profileId,
      collectionId: collectionId,
      queries: queries,
    );
  }());
  Future<void> recoverCollectionsCollectionId(
    String profileId,
    String collectionId, [
    Map<String, String> queries = const {},
  ]) async => recover(await () async {
    await profile__profileId_collections__collectionId.loadLibrary();
    return profile__profileId_collections__collectionId.CollectionsCollectionIdRoute(
      profileId: profileId,
      collectionId: collectionId,
      queries: queries,
    );
  }());
  Future<T?> pushProfileId<T extends Object>(String profileId) async =>
      push(await () async {
        await profile__profileId_index.loadLibrary();
        return profile__profileId_index.ProfileIdRoute(profileId: profileId);
      }());
  Future<void> replaceProfileId(String profileId) async =>
      replace(await () async {
        await profile__profileId_index.loadLibrary();
        return profile__profileId_index.ProfileIdRoute(profileId: profileId);
      }());
  Future<void> recoverProfileId(String profileId) async =>
      recover(await () async {
        await profile__profileId_index.loadLibrary();
        return profile__profileId_index.ProfileIdRoute(profileId: profileId);
      }());
  Future<T?> pushProfileGeneral<T extends Object>() async =>
      push(await () async {
        await profile_general.loadLibrary();
        return profile_general.ProfileGeneralRoute();
      }());
  Future<void> replaceProfileGeneral() async => replace(await () async {
    await profile_general.loadLibrary();
    return profile_general.ProfileGeneralRoute();
  }());
  Future<void> recoverProfileGeneral() async => recover(await () async {
    await profile_general.loadLibrary();
    return profile_general.ProfileGeneralRoute();
  }());
  Future<T?> pushFeedDynamicId<T extends Object>(
    List<String> slugs,
    String id,
  ) async => push(await () async {
    await tabs_feed_following___slugs__id.loadLibrary();
    return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
      slugs: slugs,
      id: id,
    );
  }());
  Future<void> replaceFeedDynamicId(List<String> slugs, String id) async =>
      replace(await () async {
        await tabs_feed_following___slugs__id.loadLibrary();
        return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
          slugs: slugs,
          id: id,
        );
      }());
  Future<void> recoverFeedDynamicId(List<String> slugs, String id) async =>
      recover(await () async {
        await tabs_feed_following___slugs__id.loadLibrary();
        return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
          slugs: slugs,
          id: id,
        );
      }());
  Future<T?> pushFeedDynamicAbout<T extends Object>(List<String> slugs) async =>
      push(await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: slugs,
        );
      }());
  Future<void> replaceFeedDynamicAbout(List<String> slugs) async =>
      replace(await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: slugs,
        );
      }());
  Future<void> recoverFeedDynamicAbout(List<String> slugs) async =>
      recover(await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: slugs,
        );
      }());
  Future<T?> pushFeedDynamic<T extends Object>(List<String> slugs) async =>
      push(await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
      }());
  Future<void> replaceFeedDynamic(List<String> slugs) async =>
      replace(await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
      }());
  Future<void> recoverFeedDynamic(List<String> slugs) async =>
      recover(await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
      }());
  Future<T?> pushFeedPost<T extends Object>(String postId) async =>
      push(await () async {
        await tabs_feed_following__postId.loadLibrary();
        return tabs_feed_following__postId.FeedPostRoute(postId: postId);
      }());
  Future<void> replaceFeedPost(String postId) async => replace(await () async {
    await tabs_feed_following__postId.loadLibrary();
    return tabs_feed_following__postId.FeedPostRoute(postId: postId);
  }());
  Future<void> recoverFeedPost(String postId) async => recover(await () async {
    await tabs_feed_following__postId.loadLibrary();
    return tabs_feed_following__postId.FeedPostRoute(postId: postId);
  }());
  Future<T?> pushFollowing<T extends Object>() async => push(await () async {
    await tabs_feed_following_index.loadLibrary();
    return tabs_feed_following_index.FollowingRoute();
  }());
  Future<void> replaceFollowing() async => replace(await () async {
    await tabs_feed_following_index.loadLibrary();
    return tabs_feed_following_index.FollowingRoute();
  }());
  Future<void> recoverFollowing() async => recover(await () async {
    await tabs_feed_following_index.loadLibrary();
    return tabs_feed_following_index.FollowingRoute();
  }());
  Future<T?> pushForYou<T extends Object>() async => push(await () async {
    await tabs_feed_foryou_index.loadLibrary();
    return tabs_feed_foryou_index.ForYouRoute();
  }());
  Future<void> replaceForYou() async => replace(await () async {
    await tabs_feed_foryou_index.loadLibrary();
    return tabs_feed_foryou_index.ForYouRoute();
  }());
  Future<void> recoverForYou() async => recover(await () async {
    await tabs_feed_foryou_index.loadLibrary();
    return tabs_feed_foryou_index.ForYouRoute();
  }());
  Future<T?> pushForYouSheet<T extends Object>() async => push(await () async {
    await tabs_feed_foryou_sheet.loadLibrary();
    return tabs_feed_foryou_sheet.ForYouSheetRoute();
  }());
  Future<void> replaceForYouSheet() async => replace(await () async {
    await tabs_feed_foryou_sheet.loadLibrary();
    return tabs_feed_foryou_sheet.ForYouSheetRoute();
  }());
  Future<void> recoverForYouSheet() async => recover(await () async {
    await tabs_feed_foryou_sheet.loadLibrary();
    return tabs_feed_foryou_sheet.ForYouSheetRoute();
  }());
  Future<T?> pushTabProfile<T extends Object>() => push(TabProfileRoute());
  Future<void> replaceTabProfile() => replace(TabProfileRoute());
  Future<void> recoverTabProfile() => recover(TabProfileRoute());
  Future<T?> pushTabSettings<T extends Object>() => push(TabSettingsRoute());
  Future<void> replaceTabSettings() => replace(TabSettingsRoute());
  Future<void> recoverTabSettings() => recover(TabSettingsRoute());
}
