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
class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug {
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

  @override
  RouteManifest<String> get routeManifest => manifest;

  /// Type-safe reverse routing without constructing presentation routes.
  static Uri forgotPasswordLocation({String? fragment}) =>
      manifest.location('ForgotPasswordRoute', fragment: fragment);

  static Uri loginLocation({String? fragment}) =>
      manifest.location('LoginRoute', fragment: fragment);

  static Uri registerLocation({String? fragment}) =>
      manifest.location('RegisterRoute', fragment: fragment);

  static Uri aboutLocation({String? fragment}) =>
      manifest.location('AboutRoute', fragment: fragment);

  static Uri blogSlugsLocation({
    required List<String> slugs,
    String? fragment,
  }) => manifest.location(
    'BlogSlugsRoute',
    restParameters: {'slugs': slugs},
    fragment: fragment,
  );

  static Uri collectionListLocation({
    Map<String, String> queries = const {},
    String? fragment,
  }) => manifest.location(
    'CollectionListRoute',
    queryParameters: queries,
    fragment: fragment,
  );

  static Uri indexLocation({String? fragment}) =>
      manifest.location('IndexRoute', fragment: fragment);

  static Uri profileIdLocation({required String profileId, String? fragment}) =>
      manifest.location(
        'ProfileIdRoute',
        pathParameters: {'profileId': profileId},
        fragment: fragment,
      );

  static Uri profileGeneralLocation({String? fragment}) =>
      manifest.location('ProfileGeneralRoute', fragment: fragment);

  static Uri settingsAccountIndexLocation({String? fragment}) =>
      manifest.location('SettingsAccountIndexRoute', fragment: fragment);

  static Uri shopProductsProductIdReviewsLocation({
    required String productId,
    String? fragment,
  }) => manifest.location(
    'ShopProductsProductIdReviewsRoute',
    pathParameters: {'productId': productId},
    fragment: fragment,
  );

  static Uri feedDynamicIdLocation({
    required List<String> slugs,
    required String id,
    String? fragment,
  }) => manifest.location(
    'FeedDynamicIdRoute',
    pathParameters: {'id': id},
    restParameters: {'slugs': slugs},
    fragment: fragment,
  );

  static Uri feedDynamicAboutLocation({
    required List<String> slugs,
    String? fragment,
  }) => manifest.location(
    'FeedDynamicAboutRoute',
    restParameters: {'slugs': slugs},
    fragment: fragment,
  );

  static Uri feedDynamicLocation({
    required List<String> slugs,
    String? fragment,
  }) => manifest.location(
    'FeedDynamicRoute',
    restParameters: {'slugs': slugs},
    fragment: fragment,
  );

  static Uri feedPostLocation({required String postId, String? fragment}) =>
      manifest.location(
        'FeedPostRoute',
        pathParameters: {'postId': postId},
        fragment: fragment,
      );

  static Uri followingLocation({String? fragment}) =>
      manifest.location('FollowingRoute', fragment: fragment);

  static Uri forYouLocation({
    Map<String, String> queries = const {},
    String? fragment,
  }) => manifest.location(
    'ForYouRoute',
    queryParameters: queries,
    fragment: fragment,
  );

  static Uri forYouSheetLocation({String? fragment}) =>
      manifest.location('ForYouSheetRoute', fragment: fragment);

  static Uri tabProfileLocation({String? fragment}) =>
      manifest.location('TabProfileRoute', fragment: fragment);

  static Uri tabSettingsLocation({String? fragment}) =>
      manifest.location('TabSettingsRoute', fragment: fragment);

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
  Future<AppRoute> parseRouteFromUri(Uri uri) async {
    final match = routeManifest.match(uri);
    if (match == null) {
      return NotFoundRoute(uri: uri, queries: uri.queryParameters);
    }
    return switch (match.id) {
      'ForYouSheetRoute' => await () async {
        await tabs_feed_foryou_sheet.loadLibrary();
        return tabs_feed_foryou_sheet.ForYouSheetRoute();
      }(),
      'ShopProductsProductIdReviewsRoute' => await () async {
        await shop_products__productId_reviews.loadLibrary();
        return shop_products__productId_reviews.ShopProductsProductIdReviewsRoute(
          productId: match.pathParameters['productId']!,
        );
      }(),
      'FeedPostRoute' => await () async {
        await tabs_feed_following__postId.loadLibrary();
        return tabs_feed_following__postId.FeedPostRoute(
          postId: match.pathParameters['postId']!,
        );
      }(),
      'FollowingRoute' => await () async {
        await tabs_feed_following_index.loadLibrary();
        return tabs_feed_following_index.FollowingRoute();
      }(),
      'ForYouRoute' => await () async {
        await tabs_feed_foryou_index.loadLibrary();
        return tabs_feed_foryou_index.ForYouRoute(queries: uri.queryParameters);
      }(),
      'CollectionListRoute' => await () async {
        await collection_list.loadLibrary();
        return collection_list.CollectionListRoute(
          queries: uri.queryParameters,
        );
      }(),
      'ProfileGeneralRoute' => await () async {
        await profile_general.loadLibrary();
        return profile_general.ProfileGeneralRoute();
      }(),
      'SettingsAccountIndexRoute' => await () async {
        await settings_account_index.loadLibrary();
        return settings_account_index.SettingsAccountIndexRoute();
      }(),
      'TabProfileRoute' => TabProfileRoute(),
      'TabSettingsRoute' => TabSettingsRoute(),
      'ProfileIdRoute' => await () async {
        await profile__profileId_index.loadLibrary();
        return profile__profileId_index.ProfileIdRoute(
          profileId: match.pathParameters['profileId']!,
        );
      }(),
      'ForgotPasswordRoute' => await () async {
        await _auth_forgotpassword.loadLibrary();
        return _auth_forgotpassword.ForgotPasswordRoute();
      }(),
      'LoginRoute' => await () async {
        await _auth_login.loadLibrary();
        return _auth_login.LoginRoute();
      }(),
      'RegisterRoute' => await () async {
        await _auth_register.loadLibrary();
        return _auth_register.RegisterRoute();
      }(),
      'AboutRoute' => await () async {
        await about.loadLibrary();
        return about.AboutRoute();
      }(),
      'IndexRoute' => await () async {
        await index.loadLibrary();
        return index.IndexRoute();
      }(),
      'FeedDynamicAboutRoute' => await () async {
        await tabs_feed_following___slugs_about.loadLibrary();
        return tabs_feed_following___slugs_about.FeedDynamicAboutRoute(
          slugs: match.restParameters['slugs']!,
        );
      }(),
      'FeedDynamicIdRoute' => await () async {
        await tabs_feed_following___slugs__id.loadLibrary();
        return tabs_feed_following___slugs__id.FeedDynamicIdRoute(
          slugs: match.restParameters['slugs']!,
          id: match.pathParameters['id']!,
        );
      }(),
      'FeedDynamicRoute' => await () async {
        await tabs_feed_following___slugs_index.loadLibrary();
        return tabs_feed_following___slugs_index.FeedDynamicRoute(
          slugs: match.restParameters['slugs']!,
        );
      }(),
      'BlogSlugsRoute' => await () async {
        await blog___slugs.loadLibrary();
        return blog___slugs.BlogSlugsRoute(
          slugs: match.restParameters['slugs']!,
        );
      }(),
      _ => NotFoundRoute(uri: uri, queries: uri.queryParameters),
    };
  }

  @override
  Widget layoutBuilder(BuildContext context) {
    return AppCoordinatorProvider(
      coordinator: this,
      child: super.layoutBuilder(context),
    );
  }
}

/// Type-safe navigation extension methods.
extension AppCoordinatorNav on AppCoordinator {
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

/// Extension on [AppRoute] for navigation methods.
extension AppCoordinatorNavContext on AppRoute {
  Future<void> navigate(BuildContext context) =>
      context.appCoordinator.navigate(this);
  Future<T?> push<T extends Object>(BuildContext context) =>
      context.appCoordinator.push<T>(this);
  Future<void> replace(BuildContext context) =>
      context.appCoordinator.replace(this);
  Future<void> recover(BuildContext context) =>
      context.appCoordinator.recover(this);
}
