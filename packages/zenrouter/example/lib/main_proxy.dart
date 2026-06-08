import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final coordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ProxyPath Coordinator Example',
      routerConfig: coordinator,
    );
  }
}

abstract class AppRoute extends RouteTarget with RouteUnique {}

class AppCoordinator extends Coordinator<AppRoute> {
  late final embeddedCoordinator = EmbeddedCoordinator();

  late final embeddedPath = ProxyPath<AppRoute>.createWith(
    coordinator: this,
    label: 'embedded-coordinator',
    builder: (context, path) =>
        CoordinatorView<EmbeddedAppRoute>(coordinator: embeddedCoordinator),
    onReset: () {
      for (final path in embeddedCoordinator.paths) {
        path.reset();
      }
    },
  )..bindLayout(EmbeddedShellRoute.new);

  @override
  List<StackPath> get paths => [...super.paths, embeddedPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] || ['home'] => HomeRoute(),
      ['embedded'] => OpenEmbeddedHomeRoute(),
      ['embedded', 'detail', final id] => OpenEmbeddedDetailRoute(id),
      ['embedded', 'settings'] => OpenEmbeddedSettingsRoute(),
      _ => HomeRoute(),
    };
  }

  @override
  void dispose() {
    embeddedCoordinator.dispose();
    super.dispose();
  }
}

abstract class EmbeddedAppRoute extends RouteTarget with RouteUnique {}

class EmbeddedCoordinator extends Coordinator<EmbeddedAppRoute> {
  late final contentPath = NavigationPath<EmbeddedAppRoute>.createWith(
    coordinator: this,
    label: 'embedded-content',
  )..bindLayout(EmbeddedDashboardLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, contentPath];

  @override
  EmbeddedAppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] || ['embedded'] => EmbeddedHomeRoute(),
      ['embedded', 'detail', final id] => EmbeddedDetailRoute(id),
      ['embedded', 'settings'] => EmbeddedSettingsRoute(),
      _ => EmbeddedHomeRoute(),
    };
  }
}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ProxyPath host')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Host Coordinator root route'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.push(OpenEmbeddedHomeRoute()),
              child: const Text('Open embedded Coordinator'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  coordinator.push(OpenEmbeddedDetailRoute('from-host')),
              child: const Text('Push embedded detail from host'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => coordinator.push(OpenEmbeddedSettingsRoute()),
              child: const Text('Open embedded settings from host'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmbeddedShellRoute extends AppRoute with RouteLayout<AppRoute> {
  @override
  ProxyPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.embeddedPath;

  @override
  Uri toUri() => Uri.parse('/embedded');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => coordinator.tryPop()),
        title: const Text('Embedded Coordinator'),
      ),
      body: buildPath(coordinator),
    );
  }
}

abstract class EmbeddedProxyRoute extends AppRoute with ProxyRoute<AppRoute> {
  @override
  Type get layout => EmbeddedShellRoute;

  EmbeddedAppRoute toEmbeddedRoute();

  EmbeddedCoordinator embeddedCoordinator(ProxyPath<AppRoute> path) =>
      (path.coordinator as AppCoordinator).embeddedCoordinator;

  @override
  Future<void> onActivate(ProxyPath<AppRoute> path) =>
      embeddedCoordinator(path).replace(toEmbeddedRoute());

  @override
  Future<void> onNavigate(ProxyPath<AppRoute> path) =>
      embeddedCoordinator(path).navigate(toEmbeddedRoute());

  @override
  Future<R?> onPush<R extends Object>(ProxyPath<AppRoute> path) =>
      embeddedCoordinator(path).push<R>(toEmbeddedRoute());

  @override
  Future<R?> onPushReplacement<R extends Object, RO extends Object>(
    ProxyPath<AppRoute> path, {
    RO? result,
  }) => embeddedCoordinator(
    path,
  ).pushReplacement<R, RO>(toEmbeddedRoute(), result: result);

  @override
  Future<void> onPushOrMoveToTop(ProxyPath<AppRoute> path) async {
    embeddedCoordinator(path).pushOrMoveToTop(toEmbeddedRoute());
  }

  @override
  Future<bool?> onPop(ProxyPath<AppRoute> path, [Object? result]) =>
      embeddedCoordinator(path).tryPop(result);
}

class OpenEmbeddedHomeRoute extends EmbeddedProxyRoute {
  @override
  Uri toUri() => Uri.parse('/embedded');

  @override
  EmbeddedAppRoute toEmbeddedRoute() => EmbeddedHomeRoute();

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();
}

class OpenEmbeddedDetailRoute extends EmbeddedProxyRoute {
  OpenEmbeddedDetailRoute(this.id);

  final String id;

  @override
  Uri toUri() => Uri.parse('/embedded/detail/$id');

  @override
  List<Object?> get props => [id];

  @override
  EmbeddedAppRoute toEmbeddedRoute() => EmbeddedDetailRoute(id);

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();
}

class OpenEmbeddedSettingsRoute extends EmbeddedProxyRoute {
  @override
  Uri toUri() => Uri.parse('/embedded/settings');

  @override
  EmbeddedAppRoute toEmbeddedRoute() => EmbeddedSettingsRoute();

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();
}

abstract class EmbeddedRoute extends EmbeddedAppRoute {
  EmbeddedCoordinator resolveEmbeddedCoordinator(CoordinatorCore coordinator) {
    return switch (coordinator) {
      EmbeddedCoordinator embedded => embedded,
      _ => throw StateError(
        'Embedded routes require EmbeddedCoordinator, '
        'but received ${coordinator.runtimeType}.',
      ),
    };
  }
}

class EmbeddedDashboardLayout extends EmbeddedRoute
    with RouteLayout<EmbeddedAppRoute> {
  @override
  NavigationPath<EmbeddedAppRoute> resolvePath(CoordinatorCore coordinator) =>
      resolveEmbeddedCoordinator(coordinator).contentPath;

  @override
  Uri toUri() => Uri.parse('/embedded');

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) {
    final embeddedCoordinator = resolveEmbeddedCoordinator(coordinator);
    final contentPath = embeddedCoordinator.contentPath;

    return ListenableBuilder(
      listenable: contentPath,
      builder: (context, _) {
        final activeRoute = contentPath.activeRoute;
        final selectedIndex = activeRoute is EmbeddedSettingsRoute ? 1 : 0;

        return Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    embeddedCoordinator.navigate(EmbeddedHomeRoute());
                  case 1:
                    embeddedCoordinator.navigate(EmbeddedSettingsRoute());
                }
              },
            ),
            const VerticalDivider(width: 1),
            Expanded(child: buildPath(embeddedCoordinator)),
          ],
        );
      },
    );
  }
}

class EmbeddedHomeRoute extends EmbeddedRoute {
  @override
  Type get layout => EmbeddedDashboardLayout;

  @override
  Uri toUri() => Uri.parse('/embedded');

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) {
    final embeddedCoordinator = resolveEmbeddedCoordinator(coordinator);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Embedded Coordinator home'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => embeddedCoordinator.push(
              EmbeddedDetailRoute('through-inner-layout'),
            ),
            child: const Text('Push detail through inner layout'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                embeddedCoordinator.navigate(EmbeddedSettingsRoute()),
            child: const Text('Navigate to embedded settings'),
          ),
        ],
      ),
    );
  }
}

class EmbeddedDetailRoute extends EmbeddedRoute {
  EmbeddedDetailRoute(this.id);

  final String id;

  @override
  Type get layout => EmbeddedDashboardLayout;

  @override
  Uri toUri() => Uri.parse('/embedded/detail/$id');

  @override
  List<Object?> get props => [id];

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) {
    final embeddedCoordinator = resolveEmbeddedCoordinator(coordinator);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Embedded detail: $id'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final popped = await embeddedCoordinator.tryPop();
              if (popped != true) {
                await embeddedCoordinator.replace(EmbeddedHomeRoute());
              }
            },
            child: const Text('Back inside embedded layout'),
          ),
        ],
      ),
    );
  }
}

class EmbeddedSettingsRoute extends EmbeddedRoute {
  @override
  Type get layout => EmbeddedDashboardLayout;

  @override
  Uri toUri() => Uri.parse('/embedded/settings');

  @override
  Widget build(CoordinatorCore coordinator, BuildContext context) {
    final embeddedCoordinator = resolveEmbeddedCoordinator(coordinator);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Embedded settings inside nested layout'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => embeddedCoordinator.push(
              EmbeddedDetailRoute('settings-detail'),
            ),
            child: const Text('Push settings detail'),
          ),
        ],
      ),
    );
  }
}
