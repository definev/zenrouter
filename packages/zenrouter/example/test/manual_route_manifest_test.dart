import 'package:example/main_route_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  test('manual manifest binds dynamic and rest matches to Flutter routes', () {
    final coordinator = ManualManifestCoordinator();
    addTearDown(coordinator.dispose);

    final profileUri = ManualManifestCoordinator.profileLocation('core team');
    expect(profileUri, Uri.parse('/profiles/core%20team'));
    expect(
      coordinator.parseRouteFromUri(profileUri),
      isA<ManualProfileRoute>().having(
        (route) => route.profileId,
        'profileId',
        'core team',
      ),
    );

    final docsUri = ManualManifestCoordinator.docsLocation(['guides', 'web']);
    expect(
      coordinator.parseRouteFromUri(docsUri),
      isA<ManualDocsRoute>().having((route) => route.slugs, 'slugs', [
        'guides',
        'web',
      ]),
    );
  });

  test('manual manifest preserves typed not-found resolution', () async {
    final coordinator = ManualManifestCoordinator();
    addTearDown(coordinator.dispose);

    final resolution = await coordinator.resolveRoute(
      RouteRequest.navigation(Uri.parse('/missing')),
    );

    expect(resolution, isA<NotFoundRouteResolution<ManualManifestRoute>>());
    expect(resolution.statusCode, 404);
  });
}
