import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// Run with:
///
/// ```sh
/// flutter run -t lib/main_route_manifest.dart
/// ```
///
/// This example is intentionally codegen-free. Three independently owned
/// features contribute [RouteManifestFragment]s, then the coordinator composes
/// them into one validated [RouteManifest]. The coordinator is the Flutter
/// binding from manifest IDs to concrete route instances.
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

/// In a real application these IDs and fragments can live in separate feature
/// packages. Keeping their enum types separate prevents accidental coupling
/// between feature-owned routes.
enum AppShellRouteId { home }

enum AccountsRouteId { profile }

enum KnowledgeBaseRouteId { article }

final appShellManifestFragment = RouteManifestFragment<AppShellRouteId>(
  name: 'app-shell',
  idCodec: RouteIdCodec.enumValues(AppShellRouteId.values),
  routes: [RouteManifestRoute(id: AppShellRouteId.home, path: '/')],
);

final accountsManifestFragment = RouteManifestFragment<AccountsRouteId>(
  name: 'accounts',
  idCodec: RouteIdCodec.enumValues(AccountsRouteId.values),
  routes: [
    RouteManifestRoute(
      id: AccountsRouteId.profile,
      path: '/profiles/:profileId',
    ),
  ],
);

final knowledgeBaseManifestFragment =
    RouteManifestFragment<KnowledgeBaseRouteId>(
      name: 'knowledge-base',
      idCodec: RouteIdCodec.enumValues(KnowledgeBaseRouteId.values),
      routes: [
        RouteManifestRoute(
          id: KnowledgeBaseRouteId.article,
          path: '/docs/...:slugs',
        ),
      ],
    );

class ManualManifestCoordinator extends Coordinator<ManualManifestRoute>
    with CoordinatorRouteBinding<ManualManifestRoute, Object> {
  /// Composition validates duplicate IDs, ambiguous paths, and graph
  /// relationships across all feature boundaries in one place.
  static final manifest = RouteManifest<Object>.fromFragments(
    name: 'manual-manifest-example',
    fragments: [
      appShellManifestFragment,
      accountsManifestFragment,
      knowledgeBaseManifestFragment,
    ],
  );

  /// Runtime presentation bindings replace a handwritten parser switch.
  @override
  late final routeBindings = manifest.bind<ManualManifestRoute>(
    bindings: () => <RouteBinding<Object, ManualManifestRoute>>[
      RouteBinding<AppShellRouteId, ManualManifestRoute>(
        id: AppShellRouteId.home,
        create: (_) => ManualHomeRoute(),
      ),
      RouteBinding<AccountsRouteId, ManualManifestRoute>(
        id: AccountsRouteId.profile,
        create: (match) =>
            ManualProfileRoute(profileId: match.pathParameters['profileId']!),
      ),
      RouteBinding<KnowledgeBaseRouteId, ManualManifestRoute>(
        id: KnowledgeBaseRouteId.article,
        create: (match) =>
            ManualDocsRoute(slugs: match.restParameters['slugs']!),
      ),
    ],
    notFound: ManualNotFoundRoute.new,
  );

  /// Reverse routing uses the same patterns as forward matching.
  static Uri homeLocation() => manifest.location(AppShellRouteId.home);

  static Uri profileLocation(String profileId) => manifest.location(
    AccountsRouteId.profile,
    pathParameters: {'profileId': profileId},
  );

  static Uri docsLocation(List<String> slugs) => manifest.location(
    KnowledgeBaseRouteId.article,
    restParameters: {'slugs': slugs},
  );
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
            'The app shell, accounts, and knowledge-base features own separate '
            'manifest fragments. The app composes them once, builds each URI '
            'from the resulting manifest, and resolves it through that same '
            'graph before creating a Flutter route.',
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Dynamic profile route'),
            subtitle: Text(profileLocation.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(coordinator.recoverUri(profileLocation)),
          ),
          ListTile(
            title: const Text('Catch-all documentation route'),
            subtitle: Text(docsLocation.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(coordinator.recoverUri(docsLocation)),
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
