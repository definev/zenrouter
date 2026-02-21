import 'package:zenrouter/zenrouter.dart';
import 'app_route.dart';

class AppCoordinator extends Coordinator<AppRoute> {
  late final homeIndexed = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'home',
    [FeedLayout(), ProfileLayout()],
  )..bindLayout(HomeLayout.new);
  late final feedNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'feed',
  )..bindLayout(FeedLayout.new);
  late final profileNavigation = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'profile',
  )..bindLayout(ProfileLayout.new);

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    homeIndexed,
    feedNavigation,
    profileNavigation,
  ];

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
