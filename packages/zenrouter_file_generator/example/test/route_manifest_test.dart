import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

void main() {
  test(
    'generated manifest is the source of truth for parsing and links',
    () async {
      final coordinator = AppCoordinator();
      addTearDown(coordinator.dispose);

      final location = coordinator.location.profileId(profileId: 'core team');
      expect(location, Uri.parse('/profile/core%20team'));
      expect(
        location,
        AppCoordinator.location.profileId(profileId: 'core team'),
      );

      final route = await coordinator.parseRouteFromUri(location);
      expect(route, isNotNull);
      expect(route!.toUri(), location);
      expect(
        AppCoordinator.manifest.match(location)?.route.id,
        'ProfileIdRoute',
      );
      expect(coordinator.routeBindings['ProfileIdRoute'], isNotNull);
      expect(coordinator.routeManifest, same(AppCoordinator.manifest));
    },
  );

  test('static routes reverse-route as location getters', () {
    expect(AppCoordinator.location.index, Uri.parse('/'));
    expect(AppCoordinator.location.about, Uri.parse('/about'));
  });

  test('generated reverse routing supports middle rest parameters', () {
    final location = AppCoordinator.location.feedDynamicId(
      slugs: ['guides', 'web'],
      id: 'start',
    );

    expect(location, Uri.parse('/tabs/feed/following/guides/web/start'));
    final match = AppCoordinator.manifest.match(location)!;
    expect(match.route.id, 'FeedDynamicIdRoute');
    expect(match.restParameters, {
      'slugs': ['guides', 'web'],
    });
    expect(match.pathParameters, {'id': 'start'});
  });
}
