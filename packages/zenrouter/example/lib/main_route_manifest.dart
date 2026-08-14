import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// Run with:
///
/// ```sh
/// flutter run -t lib/main_route_manifest.dart
/// ```
///
/// This example is intentionally codegen-free. The manifest describes static
/// topology, while [ManualManifestCoordinator.parseRouteFromUri] is the
/// Flutter binding from manifest IDs to concrete route instances.
void main() => runApp(const ManualManifestApp());

final manualManifestCoordinator = ManualManifestCoordinator();

class ManualManifestApp extends StatelessWidget {
  const ManualManifestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter manual manifest',
      routerConfig: manualManifestCoordinator,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
    );
  }
}

enum ManualRouteId { home, profile, docs }

class ManualManifestCoordinator extends Coordinator<ManualManifestRoute> {
  /// The graph is pure routing data: no Widget, BuildContext, or route factory.
  static final manifest = RouteManifest<ManualRouteId>(
    name: 'manual-manifest-example',
    idCodec: RouteIdCodec.enumValues(ManualRouteId.values),
    routes: [
      RouteManifestRoute(id: ManualRouteId.home, path: '/'),
      RouteManifestRoute(
        id: ManualRouteId.profile,
        path: '/profiles/:profileId',
      ),
      RouteManifestRoute(id: ManualRouteId.docs, path: '/docs/...:slugs'),
    ],
  );

  @override
  RouteManifest<ManualRouteId> get routeManifest => manifest;

  /// Manual presentation binding. Codegen generates an equivalent switch.
  @override
  ManualManifestRoute parseRouteFromUri(Uri uri) {
    return switch (routeManifest.match(uri)) {
      RouteManifestMatch(id: ManualRouteId.home) => ManualHomeRoute(),
      RouteManifestMatch(
        id: ManualRouteId.profile,
        pathParameters: {'profileId': final profileId},
      ) =>
        ManualProfileRoute(profileId: profileId),
      RouteManifestMatch(
        id: ManualRouteId.docs,
        restParameters: {'slugs': final slugs},
      ) =>
        ManualDocsRoute(slugs: slugs),
      null => ManualNotFoundRoute(uri),
      _ => ManualNotFoundRoute(uri),
    };
  }

  /// Reverse routing uses the same patterns as forward matching.
  static Uri homeLocation() => manifest.location(ManualRouteId.home);

  static Uri profileLocation(String profileId) => manifest.location(
    ManualRouteId.profile,
    pathParameters: {'profileId': profileId},
  );

  static Uri docsLocation(List<String> slugs) =>
      manifest.location(ManualRouteId.docs, restParameters: {'slugs': slugs});
}

abstract class ManualManifestRoute extends RouteTarget with RouteUnique {}

class ManualHomeRoute extends ManualManifestRoute {
  @override
  Uri toUri() => ManualManifestCoordinator.homeLocation();

  @override
  Widget build(
    covariant ManualManifestCoordinator coordinator,
    BuildContext context,
  ) {
    final profileLocation = ManualManifestCoordinator.profileLocation(
      'core team',
    );
    final docsLocation = ManualManifestCoordinator.docsLocation([
      'guides',
      'web navigation',
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Route Manifest')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'No annotations, part files, or build_runner are used. Each button '
            'builds a URI from the manifest, then resolves it through the same '
            'manifest before creating a Flutter route.',
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Dynamic profile route'),
            subtitle: Text(profileLocation.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                unawaited(coordinator.recoverRouteFromUri(profileLocation)),
          ),
          ListTile(
            title: const Text('Catch-all documentation route'),
            subtitle: Text(docsLocation.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                unawaited(coordinator.recoverRouteFromUri(docsLocation)),
          ),
          const Divider(),
          Text(
            'Serializable graph: ${ManualManifestCoordinator.manifest.encode()}',
          ),
        ],
      ),
    );
  }
}

class ManualProfileRoute extends ManualManifestRoute {
  ManualProfileRoute({required this.profileId});

  final String profileId;

  @override
  Uri toUri() => ManualManifestCoordinator.profileLocation(profileId);

  @override
  List<Object?> get props => [profileId];

  @override
  Widget build(
    covariant ManualManifestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('profileId = $profileId'),
            const SizedBox(height: 8),
            SelectableText(toUri().toString()),
          ],
        ),
      ),
    );
  }
}

class ManualDocsRoute extends ManualManifestRoute {
  ManualDocsRoute({required Iterable<String> slugs})
    : slugs = List.unmodifiable(slugs);

  final List<String> slugs;

  @override
  Uri toUri() => ManualManifestCoordinator.docsLocation(slugs);

  @override
  List<Object?> get props => [slugs];

  @override
  Widget build(
    covariant ManualManifestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Documentation')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('slugs = ${slugs.join(' / ')}'),
            const SizedBox(height: 8),
            SelectableText(toUri().toString()),
          ],
        ),
      ),
    );
  }
}

class ManualNotFoundRoute extends ManualManifestRoute with RouteNotFound {
  ManualNotFoundRoute(this.requestedUri);

  final Uri requestedUri;

  @override
  Uri toUri() => requestedUri;

  @override
  List<Object?> get props => [requestedUri];

  @override
  Widget build(
    covariant ManualManifestCoordinator coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route matches $requestedUri')),
    );
  }
}
