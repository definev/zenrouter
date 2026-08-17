// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';
import '_route.dart';

import '(auth).forgot-password.dart' deferred as _auth_forgotpassword;
import '(auth)/_layout.dart';
import '(auth)/login.dart' deferred as _auth_login;
import '(auth)/register.dart' deferred as _auth_register;
import 'about.dart' deferred as about;
import 'blog.[...slugs].dart' deferred as blog___slugs;
import 'collection.list.dart' deferred as collection_list;
import 'index.dart' deferred as index;
import 'not_found.dart';
import 'profile/[profileId]/index.dart' deferred as profile__profileId_index;
import 'profile/general.dart' deferred as profile_general;
import 'settings.account.index.dart' deferred as settings_account_index;
import 'shop.products.[productId].reviews.dart'
    deferred as shop_products__productId_reviews;
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
export '_route.dart';

/// Generated coordinator managing all routes.
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorRouteBinding<AppRoute, String>, CoordinatorDebug {
  /// Immutable application route topology.
  static final RouteManifest<String> manifest = RouteManifest<String>(
    name: 'AppCoordinator',
    routes: [
      RouteManifestRoute(
        id: 'ForgotPasswordRoute',
        path: '/forgot-password',
        parentId: 'AuthLayout',
      ),
      RouteManifestRoute(
        id: 'LoginRoute',
        path: '/login',
        parentId: 'AuthLayout',
      ),
      RouteManifestRoute(
        id: 'RegisterRoute',
        path: '/register',
        parentId: 'AuthLayout',
      ),
      RouteManifestRoute(id: 'AboutRoute', path: '/about'),
      RouteManifestRoute(id: 'BlogSlugsRoute', path: '/blog/...:slugs'),
      RouteManifestRoute(id: 'CollectionListRoute', path: '/collection/list'),
      RouteManifestRoute(id: 'IndexRoute', path: '/'),
      RouteManifestRoute(id: 'ProfileIdRoute', path: '/profile/:profileId'),
      RouteManifestRoute(id: 'ProfileGeneralRoute', path: '/profile/general'),
      RouteManifestRoute(
        id: 'SettingsAccountIndexRoute',
        path: '/settings/account',
      ),
      RouteManifestRoute(
        id: 'ShopProductsProductIdReviewsRoute',
        path: '/shop/products/:productId/reviews',
      ),
      RouteManifestRoute(
        id: 'FeedDynamicIdRoute',
        path: '/tabs/feed/following/...:slugs/:id',
        parentId: 'FollowingLayout',
      ),
      RouteManifestRoute(
        id: 'FeedDynamicAboutRoute',
        path: '/tabs/feed/following/...:slugs/about',
        parentId: 'FollowingLayout',
      ),
      RouteManifestRoute(
        id: 'FeedDynamicRoute',
        path: '/tabs/feed/following/...:slugs',
        parentId: 'FollowingLayout',
      ),
      RouteManifestRoute(
        id: 'FeedPostRoute',
        path: '/tabs/feed/following/:postId',
        parentId: 'FollowingLayout',
      ),
      RouteManifestRoute(
        id: 'FollowingRoute',
        path: '/tabs/feed/following',
        parentId: 'FollowingLayout',
      ),
      RouteManifestRoute(
        id: 'ForYouRoute',
        path: '/tabs/feed/for-you',
        parentId: 'ForYouLayout',
      ),
      RouteManifestRoute(
        id: 'ForYouSheetRoute',
        path: '/tabs/feed/for-you/sheet',
        parentId: 'ForYouLayout',
      ),
      RouteManifestRoute(
        id: 'TabProfileRoute',
        path: '/tabs/profile',
        parentId: 'TabsLayout',
      ),
      RouteManifestRoute(
        id: 'TabSettingsRoute',
        path: '/tabs/settings',
        parentId: 'TabsLayout',
      ),
    ],
    layouts: [
      RouteManifestLayout.stack(id: 'AuthLayout', path: '/'),
      RouteManifestLayout.indexed(
        id: 'TabsLayout',
        path: '/tabs',
        childIds: ['FeedTabLayout', 'TabProfileRoute', 'TabSettingsRoute'],
      ),
      RouteManifestLayout.branched(
        id: 'FeedTabLayout',
        path: '/tabs/feed',
        parentId: 'TabsLayout',
        childIds: ['FollowingLayout', 'ForYouLayout'],
      ),
      RouteManifestLayout.stack(
        id: 'FollowingLayout',
        path: '/tabs/feed/following',
        parentId: 'FeedTabLayout',
      ),
      RouteManifestLayout.stack(
        id: 'ForYouLayout',
        path: '/tabs/feed/for-you',
        parentId: 'FeedTabLayout',
      ),
    ],
  );

  /// Type-safe reverse routing without constructing presentation routes.
  static const location = AppCoordinatorLocation();

  /// Presentation bindings from manifest IDs to route targets.
  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding.deferred(
        id: 'ForgotPasswordRoute',
        loadLibrary: _auth_forgotpassword.loadLibrary,
        create: (_) => _auth_forgotpassword.ForgotPasswordRoute(),
      ),
      RouteBinding.deferred(
        id: 'LoginRoute',
        loadLibrary: _auth_login.loadLibrary,
        create: (_) => _auth_login.LoginRoute(),
      ),
      RouteBinding.deferred(
        id: 'RegisterRoute',
        loadLibrary: _auth_register.loadLibrary,
        create: (_) => _auth_register.RegisterRoute(),
      ),
      RouteBinding.deferred(
        id: 'AboutRoute',
        loadLibrary: about.loadLibrary,
        create: (_) => about.AboutRoute(),
      ),
      RouteBinding.deferred(
        id: 'BlogSlugsRoute',
        loadLibrary: blog___slugs.loadLibrary,
        create: (match) =>
            blog___slugs.BlogSlugsRoute(slugs: match.restParameters['slugs']!),
      ),
      RouteBinding.deferred(
        id: 'CollectionListRoute',
        loadLibrary: collection_list.loadLibrary,
        create: (match) => collection_list.CollectionListRoute(
          queries: match.uri.queryParameters,
        ),
      ),
      RouteBinding.deferred(
        id: 'IndexRoute',
        loadLibrary: index.loadLibrary,
        create: (_) => index.IndexRoute(),
      ),
      RouteBinding.deferred(
        id: 'ProfileIdRoute',
        loadLibrary: profile__profileId_index.loadLibrary,
        create: (match) => profile__profileId_index.ProfileIdRoute(
          profileId: match.pathParameters['profileId']!,
        ),
      ),
      RouteBinding.deferred(
        id: 'ProfileGeneralRoute',
        loadLibrary: profile_general.loadLibrary,
        create: (_) => profile_general.ProfileGeneralRoute(),
      ),
      RouteBinding.deferred(
        id: 'SettingsAccountIndexRoute',
        loadLibrary: settings_account_index.loadLibrary,
        create: (_) => settings_account_index.SettingsAccountIndexRoute(),
      ),
      RouteBinding.deferred(
        id: 'ShopProductsProductIdReviewsRoute',
        loadLibrary: shop_products__productId_reviews.loadLibrary,
        create: (match) =>
            shop_products__productId_reviews.ShopProductsProductIdReviewsRoute(
              productId: match.pathParameters['productId']!,
            ),
      ),
      RouteBinding.deferred(
        id: 'FeedDynamicIdRoute',
        loadLibrary: tabs_feed_following___slugs__id.loadLibrary,
        create: (match) => tabs_feed_following___slugs__id.FeedDynamicIdRoute(
          slugs: match.restParameters['slugs']!,
          id: match.pathParameters['id']!,
        ),
      ),
      RouteBinding.deferred(
        id: 'FeedDynamicAboutRoute',
        loadLibrary: tabs_feed_following___slugs_about.loadLibrary,
        create: (match) =>
            tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
              slugs: match.restParameters['slugs']!,
            ),
      ),
      RouteBinding.deferred(
        id: 'FeedDynamicRoute',
        loadLibrary: tabs_feed_following___slugs_index.loadLibrary,
        create: (match) => tabs_feed_following___slugs_index.FeedDynamicRoute(
          slugs: match.restParameters['slugs']!,
        ),
      ),
      RouteBinding.deferred(
        id: 'FeedPostRoute',
        loadLibrary: tabs_feed_following__postId.loadLibrary,
        create: (match) => tabs_feed_following__postId.FeedPostRoute(
          postId: match.pathParameters['postId']!,
        ),
      ),
      RouteBinding.deferred(
        id: 'FollowingRoute',
        loadLibrary: tabs_feed_following_index.loadLibrary,
        create: (_) => tabs_feed_following_index.FollowingRoute(),
      ),
      RouteBinding.deferred(
        id: 'ForYouRoute',
        loadLibrary: tabs_feed_foryou_index.loadLibrary,
        create: (match) => tabs_feed_foryou_index.ForYouRoute(
          queries: match.uri.queryParameters,
        ),
      ),
      RouteBinding.deferred(
        id: 'ForYouSheetRoute',
        loadLibrary: tabs_feed_foryou_sheet.loadLibrary,
        create: (_) => tabs_feed_foryou_sheet.ForYouSheetRoute(),
      ),
      RouteBinding(id: 'TabProfileRoute', create: (_) => TabProfileRoute()),
      RouteBinding(id: 'TabSettingsRoute', create: (_) => TabSettingsRoute()),
    ],
    notFound: (uri) => NotFoundRoute(uri: uri, queries: uri.queryParameters),
  );

  late final authPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'Auth',
  )..bindLayout(AuthLayout.new);
  late final tabsPath = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'Tabs',
    [FeedTabLayout(), TabProfileRoute(), TabSettingsRoute()],
  )..bindLayout(TabsLayout.new);
  late final feedTabPath = BranchedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'FeedTab',
    [FollowingLayout(), ForYouLayout()],
  )..bindLayout(FeedTabLayout.new);
  late final followingPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'Following',
  )..bindLayout(FollowingLayout.new);
  late final forYouPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'ForYou',
  )..bindLayout(ForYouLayout.new);

  @override
  List<StackPath> get paths => [
    ...super.paths,
    authPath,
    tabsPath,
    feedTabPath,
    followingPath,
    forYouPath,
  ];

  @override
  Widget layoutBuilder(BuildContext context) {
    return AppCoordinatorProvider(
      coordinator: this,
      child: super.layoutBuilder(context),
    );
  }
}

/// Type-safe reverse routing without constructing presentation routes.
final class AppCoordinatorLocation {
  /// Creates the [AppCoordinatorLocation] reverse-routing surface.
  const AppCoordinatorLocation();

  Uri get forgotPassword =>
      AppCoordinator.manifest.location('ForgotPasswordRoute');

  Uri get login => AppCoordinator.manifest.location('LoginRoute');

  Uri get register => AppCoordinator.manifest.location('RegisterRoute');

  Uri get about => AppCoordinator.manifest.location('AboutRoute');

  Uri blogSlugs({required List<String> slugs, String? fragment}) =>
      AppCoordinator.manifest.location(
        'BlogSlugsRoute',
        restParameters: {'slugs': slugs},
        fragment: fragment,
      );

  Uri collectionList({
    Map<String, String> queries = const {},
    String? fragment,
  }) => AppCoordinator.manifest.location(
    'CollectionListRoute',
    queryParameters: queries,
    fragment: fragment,
  );

  Uri get index => AppCoordinator.manifest.location('IndexRoute');

  Uri profileId({required String profileId, String? fragment}) =>
      AppCoordinator.manifest.location(
        'ProfileIdRoute',
        pathParameters: {'profileId': profileId},
        fragment: fragment,
      );

  Uri get profileGeneral =>
      AppCoordinator.manifest.location('ProfileGeneralRoute');

  Uri get settingsAccountIndex =>
      AppCoordinator.manifest.location('SettingsAccountIndexRoute');

  Uri shopProductsProductIdReviews({
    required String productId,
    String? fragment,
  }) => AppCoordinator.manifest.location(
    'ShopProductsProductIdReviewsRoute',
    pathParameters: {'productId': productId},
    fragment: fragment,
  );

  Uri feedDynamicId({
    required List<String> slugs,
    required String id,
    String? fragment,
  }) => AppCoordinator.manifest.location(
    'FeedDynamicIdRoute',
    pathParameters: {'id': id},
    restParameters: {'slugs': slugs},
    fragment: fragment,
  );

  Uri feedDynamicAbout({required List<String> slugs, String? fragment}) =>
      AppCoordinator.manifest.location(
        'FeedDynamicAboutRoute',
        restParameters: {'slugs': slugs},
        fragment: fragment,
      );

  Uri feedDynamic({required List<String> slugs, String? fragment}) =>
      AppCoordinator.manifest.location(
        'FeedDynamicRoute',
        restParameters: {'slugs': slugs},
        fragment: fragment,
      );

  Uri feedPost({required String postId, String? fragment}) =>
      AppCoordinator.manifest.location(
        'FeedPostRoute',
        pathParameters: {'postId': postId},
        fragment: fragment,
      );

  Uri get following => AppCoordinator.manifest.location('FollowingRoute');

  Uri forYou({Map<String, String> queries = const {}, String? fragment}) =>
      AppCoordinator.manifest.location(
        'ForYouRoute',
        queryParameters: queries,
        fragment: fragment,
      );

  Uri get forYouSheet => AppCoordinator.manifest.location('ForYouSheetRoute');

  Uri get tabProfile => AppCoordinator.manifest.location('TabProfileRoute');

  Uri get tabSettings => AppCoordinator.manifest.location('TabSettingsRoute');
}

/// Type-safe navigation extension methods.
extension AppCoordinatorNav on AppCoordinator {
  /// Type-safe reverse routing without constructing presentation routes.
  AppCoordinatorLocation get location => AppCoordinator.location;

  Future<T?> pushForgotPassword<T extends Object>() async =>
      push(await () async {
        await _auth_forgotpassword.loadLibrary();
        return _auth_forgotpassword.ForgotPasswordRoute();
      }());
  Future<void> replaceForgotPassword() async => replace(await () async {
    await _auth_forgotpassword.loadLibrary();
    return _auth_forgotpassword.ForgotPasswordRoute();
  }());
  Future<void> recoverForgotPassword() async => recover(await () async {
    await _auth_forgotpassword.loadLibrary();
    return _auth_forgotpassword.ForgotPasswordRoute();
  }());
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
  Future<T?> pushBlogSlugs<T extends Object>({
    required List<String> slugs,
  }) async => push(await () async {
    await blog___slugs.loadLibrary();
    return blog___slugs.BlogSlugsRoute(slugs: slugs);
  }());
  Future<void> replaceBlogSlugs({required List<String> slugs}) async =>
      replace(await () async {
        await blog___slugs.loadLibrary();
        return blog___slugs.BlogSlugsRoute(slugs: slugs);
      }());
  Future<void> recoverBlogSlugs({required List<String> slugs}) async =>
      recover(await () async {
        await blog___slugs.loadLibrary();
        return blog___slugs.BlogSlugsRoute(slugs: slugs);
      }());
  Future<T?> pushCollectionList<T extends Object>({
    Map<String, String> queries = const {},
  }) async => push(await () async {
    await collection_list.loadLibrary();
    return collection_list.CollectionListRoute(queries: queries);
  }());
  Future<void> replaceCollectionList({
    Map<String, String> queries = const {},
  }) async => replace(await () async {
    await collection_list.loadLibrary();
    return collection_list.CollectionListRoute(queries: queries);
  }());
  Future<void> recoverCollectionList({
    Map<String, String> queries = const {},
  }) async => recover(await () async {
    await collection_list.loadLibrary();
    return collection_list.CollectionListRoute(queries: queries);
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
  Future<T?> pushProfileId<T extends Object>({
    required String profileId,
  }) async => push(await () async {
    await profile__profileId_index.loadLibrary();
    return profile__profileId_index.ProfileIdRoute(profileId: profileId);
  }());
  Future<void> replaceProfileId({required String profileId}) async =>
      replace(await () async {
        await profile__profileId_index.loadLibrary();
        return profile__profileId_index.ProfileIdRoute(profileId: profileId);
      }());
  Future<void> recoverProfileId({required String profileId}) async =>
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
  Future<T?> pushSettingsAccountIndex<T extends Object>() async =>
      push(await () async {
        await settings_account_index.loadLibrary();
        return settings_account_index.SettingsAccountIndexRoute();
      }());
  Future<void> replaceSettingsAccountIndex() async => replace(await () async {
    await settings_account_index.loadLibrary();
    return settings_account_index.SettingsAccountIndexRoute();
  }());
  Future<void> recoverSettingsAccountIndex() async => recover(await () async {
    await settings_account_index.loadLibrary();
    return settings_account_index.SettingsAccountIndexRoute();
  }());
  Future<T?> pushShopProductsProductIdReviews<T extends Object>({
    required String productId,
  }) async => push(await () async {
    await shop_products__productId_reviews.loadLibrary();
    return shop_products__productId_reviews.ShopProductsProductIdReviewsRoute(
      productId: productId,
    );
  }());
  Future<void> replaceShopProductsProductIdReviews({
    required String productId,
  }) async => replace(await () async {
    await shop_products__productId_reviews.loadLibrary();
    return shop_products__productId_reviews.ShopProductsProductIdReviewsRoute(
      productId: productId,
    );
  }());
  Future<void> recoverShopProductsProductIdReviews({
    required String productId,
  }) async => recover(await () async {
    await shop_products__productId_reviews.loadLibrary();
    return shop_products__productId_reviews.ShopProductsProductIdReviewsRoute(
      productId: productId,
    );
  }());
  Future<T?> pushFeedDynamicId<T extends Object>({
    required List<String> slugs,
    required String id,
  }) async => push(await () async {
    await tabs_feed_following___slugs__id.loadLibrary();
    return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
      slugs: slugs,
      id: id,
    );
  }());
  Future<void> replaceFeedDynamicId({
    required List<String> slugs,
    required String id,
  }) async => replace(await () async {
    await tabs_feed_following___slugs__id.loadLibrary();
    return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
      slugs: slugs,
      id: id,
    );
  }());
  Future<void> recoverFeedDynamicId({
    required List<String> slugs,
    required String id,
  }) async => recover(await () async {
    await tabs_feed_following___slugs__id.loadLibrary();
    return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
      slugs: slugs,
      id: id,
    );
  }());
  Future<T?> pushFeedDynamicAbout<T extends Object>({
    required List<String> slugs,
  }) async => push(await () async {
    await tabs_feed_following___slugs_about.loadLibrary();
    return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
      slugs: slugs,
    );
  }());
  Future<void> replaceFeedDynamicAbout({required List<String> slugs}) async =>
      replace(await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: slugs,
        );
      }());
  Future<void> recoverFeedDynamicAbout({required List<String> slugs}) async =>
      recover(await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: slugs,
        );
      }());
  Future<T?> pushFeedDynamic<T extends Object>({
    required List<String> slugs,
  }) async => push(await () async {
    await tabs_feed_following___slugs_index.loadLibrary();
    return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
  }());
  Future<void> replaceFeedDynamic({required List<String> slugs}) async =>
      replace(await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
      }());
  Future<void> recoverFeedDynamic({required List<String> slugs}) async =>
      recover(await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(slugs: slugs);
      }());
  Future<T?> pushFeedPost<T extends Object>({required String postId}) async =>
      push(await () async {
        await tabs_feed_following__postId.loadLibrary();
        return tabs_feed_following__postId.FeedPostRoute(postId: postId);
      }());
  Future<void> replaceFeedPost({required String postId}) async =>
      replace(await () async {
        await tabs_feed_following__postId.loadLibrary();
        return tabs_feed_following__postId.FeedPostRoute(postId: postId);
      }());
  Future<void> recoverFeedPost({required String postId}) async =>
      recover(await () async {
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
  Future<T?> pushForYou<T extends Object>({
    Map<String, String> queries = const {},
  }) async => push(await () async {
    await tabs_feed_foryou_index.loadLibrary();
    return tabs_feed_foryou_index.ForYouRoute(queries: queries);
  }());
  Future<void> replaceForYou({Map<String, String> queries = const {}}) async =>
      replace(await () async {
        await tabs_feed_foryou_index.loadLibrary();
        return tabs_feed_foryou_index.ForYouRoute(queries: queries);
      }());
  Future<void> recoverForYou({Map<String, String> queries = const {}}) async =>
      recover(await () async {
        await tabs_feed_foryou_index.loadLibrary();
        return tabs_feed_foryou_index.ForYouRoute(queries: queries);
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

/// InheritedWidget provider for accessing the coordinator from the widget tree.
class AppCoordinatorProvider extends InheritedWidget {
  const AppCoordinatorProvider({
    required this.coordinator,
    required super.child,
    super.key,
  });

  /// Retrieves the [AppCoordinator] from the widget tree.
  static AppCoordinator of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppCoordinatorProvider>()!
      .coordinator;

  final AppCoordinator coordinator;

  @override
  bool updateShouldNotify(AppCoordinatorProvider oldWidget) =>
      coordinator != oldWidget.coordinator;
}

/// Extension on [BuildContext] for convenient coordinator access.
extension AppCoordinatorGetter on BuildContext {
  /// Access the [AppCoordinator] from the widget tree.
  AppCoordinator get appCoordinator => AppCoordinatorProvider.of(this);
}

/// Destination navigation for [AppRoute] instances.
extension AppCoordinatorNavContext on AppRoute {
  Future<void> navigate(BuildContext context) =>
      context.appCoordinator.navigate(this);
  Future<T?> push<T extends Object>(BuildContext context) =>
      context.appCoordinator.push<T>(this);
  Future<void> pushSilently(BuildContext context) =>
      context.appCoordinator.pushSilently(this);
  Future<void> replace(BuildContext context) =>
      context.appCoordinator.replace(this);
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    BuildContext context, {
    RO? result,
  }) => context.appCoordinator.pushReplacement<R, RO>(this, result: result);
  Future<void> pushOrMoveToTop(BuildContext context) =>
      context.appCoordinator.pushOrMoveToTop(this);
  Future<void> recover(BuildContext context) =>
      context.appCoordinator.recover(this);
}
