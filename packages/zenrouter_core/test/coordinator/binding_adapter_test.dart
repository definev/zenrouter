import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import '../support/harness.dart';

class _BindingCoordinator extends CoordinatorCore<AppRoute>
    with
        RecordingListenable,
        CoordinatorLayoutCore<AppRoute>,
        RouteModuleBinding<AppRoute, String> {
  _BindingCoordinator(this.routeBindings);

  @override
  final RouteBindingRegistry<String, AppRoute> routeBindings;

  late final AppStackPath _root = AppStackPath(coordinator: this);

  @override
  StackPath<AppRoute> get root => _root;
}

class _BindingModule extends RouteModule<AppRoute>
    with RouteModuleBinding<AppRoute, String> {
  _BindingModule(super.coordinator, this.routeBindings);

  @override
  final RouteBindingRegistry<String, AppRoute> routeBindings;
}

RouteBindingRegistry<String, AppRoute> _registry() {
  return RouteManifest<String>(
    name: 'bound',
    routes: [
      RouteManifestRoute(id: 'home', path: '/'),
      RouteManifestRoute(id: 'profile', path: '/profile/:id'),
    ],
  ).bind<AppRoute>(
    bindings: [
      RouteBinding(id: 'home', create: (match) => AppRoute('home')),
      RouteBinding(
        id: 'profile',
        create: (match) => AppRoute('profile/${match.pathParameters['id']}'),
      ),
    ],
    notFound: (uri) => AppRoute('missing'),
  );
}

void main() {
  group('RouteModuleBinding on CoordinatorCore', () {
    test(
      'exposes the registry manifest and resolves URIs through bindings',
      () async {
        final registry = _registry();
        final coordinator = _BindingCoordinator(registry);

        expect(coordinator.routeManifest, same(registry.manifest));
        expect(
          (await coordinator.parseRouteFromUri(Uri.parse('/')))?.id,
          'home',
        );
        expect(
          (await coordinator.parseRouteFromUri(Uri.parse('/profile/42')))?.id,
          'profile/42',
        );
        expect(
          (await coordinator.parseRouteFromUri(Uri.parse('/nope')))?.id,
          'missing',
        );
      },
    );
  });

  group('RouteModuleBinding', () {
    test('gives a leaf module manifest-backed parsing', () async {
      final registry = _registry();
      final coordinator = ModularAppCoordinator(
        modules: (c) => [_BindingModule(c, registry)],
      );
      final module = coordinator.getModule<_BindingModule>();

      expect(module.routeManifest, same(registry.manifest));
      expect((await module.parseRouteFromUri(Uri.parse('/')))?.id, 'home');
      expect(
        (await coordinator.parseRouteFromUri(Uri.parse('/profile/ada')))?.id,
        'profile/ada',
      );
    });
  });
}
