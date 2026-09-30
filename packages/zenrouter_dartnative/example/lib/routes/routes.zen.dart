// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';
import 'index.dart';
import 'item/[id].dart';
import 'tabs/_layout.dart';
import 'tabs/feed.dart';
import 'tabs/profile.dart';

export 'package:zenrouter_dartnative/zenrouter_dartnative.dart';
export 'index.dart';
export 'item/[id].dart';
export 'tabs/_layout.dart';
export 'tabs/feed.dart';
export 'tabs/profile.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

class AppCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, String> {
  AppCoordinator() : super(initialRoute: IndexRoute());

  /// Immutable application route topology.
  static final RouteManifest<String> manifest = RouteManifest<String>(
    name: 'AppCoordinator',
    routes: [
      RouteManifestRoute(id: 'IndexRoute', path: '/'),
      RouteManifestRoute(id: 'ItemIdRoute', path: '/item/:id'),
      RouteManifestRoute(
        id: 'FeedRoute',
        path: '/tabs/feed',
        parentId: 'TabsLayout',
      ),
      RouteManifestRoute(
        id: 'ProfileRoute',
        path: '/tabs/profile',
        parentId: 'TabsLayout',
      ),
    ],
    layouts: [
      RouteManifestLayout.indexed(
        id: 'TabsLayout',
        path: '/tabs',
        childIds: ['FeedRoute', 'ProfileRoute'],
      ),
    ],
  );

  /// Type-safe reverse routing without constructing presentation routes.
  static const location = AppCoordinatorLocation();

  /// Presentation bindings from manifest IDs to route targets.
  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(id: 'IndexRoute', create: (_) => IndexRoute()),
      RouteBinding(
        id: 'ItemIdRoute',
        create: (match) => ItemIdRoute(id: match.pathParameters['id']!),
      ),
      RouteBinding(id: 'FeedRoute', create: (_) => FeedRoute()),
      RouteBinding(id: 'ProfileRoute', create: (_) => ProfileRoute()),
    ],
    notFound: (uri) => NotFoundRoute(uri: uri, queries: uri.queryParameters),
  );

  late final tabsPath = IndexedStackPath<AppRoute>.createWith(
    [FeedRoute(), ProfileRoute()],
    coordinator: this,
    label: 'Tabs',
  );

  @override
  List<StackPath> get paths => [...super.paths, tabsPath];

  @override
  void init() {
    super.init();
    defineLayoutParent(TabsLayout.new);
  }
}

/// Type-safe reverse routing without constructing presentation routes.
final class AppCoordinatorLocation {
  /// Creates the [AppCoordinatorLocation] reverse-routing surface.
  const AppCoordinatorLocation();

  Uri get index => AppCoordinator.manifest.location('IndexRoute');

  Uri itemId({required String id, String? fragment}) => AppCoordinator.manifest
      .location('ItemIdRoute', pathParameters: {'id': id}, fragment: fragment);

  Uri get feed => AppCoordinator.manifest.location('FeedRoute');

  Uri get profile => AppCoordinator.manifest.location('ProfileRoute');
}

class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute({required this.uri, this.queries = const {}});
  final Uri uri;
  final Map<String, String> queries;
  @override
  Uri toUri() => uri;
  @override
  List<Object?> get props => [uri, queries];
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      Text('Route not found: ${uri.path}');
}

extension AppCoordinatorNav on AppCoordinator {
  AppCoordinatorLocation get location => AppCoordinator.location;
  Future<T?> pushIndex<T extends Object>() => push(IndexRoute());
  Future<void> replaceIndex() => replace(IndexRoute());
  Future<void> recoverIndex() => recover(IndexRoute());
  Future<T?> pushItemId<T extends Object>({required String id}) =>
      push(ItemIdRoute(id: id));
  Future<void> replaceItemId({required String id}) =>
      replace(ItemIdRoute(id: id));
  Future<void> recoverItemId({required String id}) =>
      recover(ItemIdRoute(id: id));
  Future<T?> pushFeed<T extends Object>() => push(FeedRoute());
  Future<void> replaceFeed() => replace(FeedRoute());
  Future<void> recoverFeed() => recover(FeedRoute());
  Future<T?> pushProfile<T extends Object>() => push(ProfileRoute());
  Future<void> replaceProfile() => replace(ProfileRoute());
  Future<void> recoverProfile() => recover(ProfileRoute());
}

extension AppCoordinatorContext on BuildContext {
  AppCoordinator get appCoordinator =>
      CoordinatorScope.of<AppRoute>(this) as AppCoordinator;
}
