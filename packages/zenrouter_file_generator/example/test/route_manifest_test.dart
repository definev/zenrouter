import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

void main() {
  test(
    'generated manifest is the source of truth for parsing and links',
    () async {
      final coordinator = AppCoordinator();
      addTearDown(coordinator.dispose);

      final location = AppCoordinator.profileIdLocation(profileId: 'core team');
      expect(location, Uri.parse('/profile/core%20team'));

      final route = await coordinator.parseRouteFromUri(location);
      expect(route.toUri(), location);
      expect(
        AppCoordinator.manifest.match(location)?.route.id,
        'ProfileIdRoute',
      );
    },
  );

  test('generated reverse routing supports middle rest parameters', () {
    final location = AppCoordinator.feedDynamicIdLocation(
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
