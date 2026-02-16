import 'package:zenrouter/zenrouter.dart';
import 'app_route.dart';

class AppCoordinator extends Coordinator<AppRoute> {
  late final homeIndexed = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'home',
    [FeedLayout(), ProfileLayout()],
  );
  late final feedNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'feed',
  );
  late final profileNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'profile',
  );

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];

  @override
  void defineLayout() {
    defineRouteLayout(HomeLayout, HomeLayout.new);
    defineRouteLayout(FeedLayout, FeedLayout.new);
    defineRouteLayout(ProfileLayout, ProfileLayout.new);
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['post'] => PostList(),
      ['post', final id] => PostDetail(id: int.parse(id)),
      ['profile'] => Profile(),
      ['settings'] => Settings(),
      _ => NotFoundRoute(uri: uri),
    };
  }
}
