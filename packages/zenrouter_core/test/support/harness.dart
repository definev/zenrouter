// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/src/path/commit.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// Listener bookkeeping used by headless [ListenableObject] implementations.
mixin RecordingListenable {
  final List<VoidCallback> listeners = [];

  void addListener(VoidCallback listener) => listeners.add(listener);

  void removeListener(VoidCallback listener) => listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<VoidCallback>.of(listeners)) {
      listener();
    }
  }
}

class AppRoute extends RouteUri {
  AppRoute(this.id, {this.parentLayoutKey});

  final String id;

  @override
  final Object? parentLayoutKey;

  @override
  Uri toUri() => Uri.parse('/$id');

  @override
  List<Object?> get props => [id];

  @override
  String toString() => 'AppRoute($id)';
}

class TrackingRoute extends AppRoute {
  TrackingRoute(super.id, {super.parentLayoutKey});

  final events = <String>[];

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    events.add('onDidPop');
    super.onDidPop(result, coordinator);
  }

  @override
  void onDiscard() {
    events.add('onDiscard');
    super.onDiscard();
  }

  @override
  void onUpdate(covariant RouteTarget newRoute) {
    events.add('onUpdate:${(newRoute as AppRoute).id}');
    super.onUpdate(newRoute);
  }
}

class GuardedAppRoute extends AppRoute with RouteGuard {
  GuardedAppRoute(super.id, {this.allowPop = true, super.parentLayoutKey});

  final bool allowPop;

  @override
  FutureOr<bool> popGuard() => allowPop;
}

class RedirectAppRoute extends AppRoute with RouteRedirect<AppRoute> {
  RedirectAppRoute(super.id, {this.to, this.stop = false});

  final AppRoute? to;
  final bool stop;
  int redirectCalls = 0;

  @override
  FutureOr<AppRoute> redirect() {
    redirectCalls++;
    return to ?? this;
  }

  @override
  FutureOr<AppRoute?> redirectWith(covariant CoordinatorCore coordinator) {
    redirectCalls++;
    if (stop) return null;
    return to ?? this;
  }
}

class DeepLinkAppRoute extends AppRoute with RouteDeepLink {
  DeepLinkAppRoute(super.id, {required this.deeplinkStrategy});

  @override
  final DeeplinkStrategy deeplinkStrategy;

  var customHandlerCalled = false;

  @override
  FutureOr<void> deeplinkHandler(
    covariant CoordinatorCore coordinator,
    Uri uri,
  ) {
    customHandlerCalled = true;
  }
}

class AppLayout extends AppRoute with RouteLayoutParent<AppRoute> {
  AppLayout(
    super.id, {
    required this.layoutKey,
    required this.path,
    super.parentLayoutKey,
  });

  @override
  final Object layoutKey;

  final StackPath path;

  @override
  StackPath resolvePath(covariant CoordinatorCore coordinator) => path;
}

class AppStackPath extends StackPath<AppRoute>
    with RecordingListenable, StackMutatable<AppRoute> {
  AppStackPath({super.coordinator, super.debugLabel}) : super([]);

  @override
  AppRoute? get activeRoute => stack.lastOrNull;

  @override
  PathKey get pathKey => const PathKey('app');

  @override
  void reset() {
    clear();
    notifyListeners();
  }

  @override
  Future<void> activateRoute(AppRoute route) => pushSilently(route);

  void seed(Iterable<AppRoute> routes) => bindStack(List.of(routes));
}

/// [StackPath] that is neither [StackCommit] nor [StackNavigatable].
class ActivateOnlyPath extends StackPath<AppRoute> with RecordingListenable {
  ActivateOnlyPath({super.coordinator, super.debugLabel}) : super([]);

  var activateCalls = 0;

  @override
  AppRoute? get activeRoute => stack.lastOrNull;

  @override
  PathKey get pathKey => const PathKey('activate-only');

  @override
  void reset() {
    clear();
    notifyListeners();
  }

  @override
  Future<void> activateRoute(AppRoute route) async {
    activateCalls++;
    bindStack([...stack, route]);
    notifyListeners();
  }
}

/// [StackNavigatable] path that is not a [StackCommit].
class NavigateOnlyPath extends StackPath<AppRoute>
    with RecordingListenable, StackNavigatable<AppRoute> {
  NavigateOnlyPath({super.coordinator, super.debugLabel}) : super([]);

  var navigateCalls = 0;

  @override
  AppRoute? get activeRoute => stack.lastOrNull;

  @override
  PathKey get pathKey => const PathKey('navigate-only');

  @override
  void reset() {
    clear();
    notifyListeners();
  }

  @override
  Future<void> activateRoute(AppRoute route) async {
    bindStack([...stack, route]);
    notifyListeners();
  }

  @override
  Future<void> navigate(AppRoute route) async {
    navigateCalls++;
    await activateRoute(route);
  }
}

class AppCoordinator extends CoordinatorCore<AppRoute>
    with
        RecordingListenable,
        CoordinatorLayoutCore<AppRoute>,
        CoordinatorNavigatable<AppRoute>,
        CoordinatorMutatable<AppRoute>,
        CoordinatorRecoverable<AppRoute> {
  AppCoordinator({
    super.initialRoutePath,
    this.parser,
    AppStackPath? root,
    this.extraPaths = const [],
  }) : _providedRoot = root;

  final FutureOr<AppRoute?> Function(Uri uri)? parser;
  final AppStackPath? _providedRoot;
  final List<StackPath> extraPaths;

  late final AppStackPath nested = AppStackPath(
    coordinator: this,
    debugLabel: 'nested',
  );

  late final AppStackPath _root =
      _providedRoot ?? AppStackPath(coordinator: this, debugLabel: 'root');

  @override
  StackPath<AppRoute> get root => _root;

  @override
  List<StackPath> get paths => [...super.paths, nested, ...extraPaths];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    if (parser != null) return parser!(uri);
    final id = uri.pathSegments.isEmpty ? 'home' : uri.pathSegments.join('/');
    return AppRoute(id);
  }

  void registerShell({Object key = 'shell', StackPath? path}) {
    defineLayoutParentConstructor(
      key,
      (layoutKey) => AppLayout(
        layoutKey.toString(),
        layoutKey: layoutKey,
        path: path ?? nested,
      ),
    );
  }
}

class ModularAppCoordinator extends AppCoordinator
    with CoordinatorModular<AppRoute> {
  ModularAppCoordinator({
    Iterable<RouteModule<AppRoute>> Function(ModularAppCoordinator coordinator)?
    modules,
    this.localFragment,
    this.manifestName,
  }) : _modulesBuilder = modules;

  final Iterable<RouteModule<AppRoute>> Function(ModularAppCoordinator)?
  _modulesBuilder;
  final RouteManifestFragment<Object>? localFragment;
  final String? manifestName;

  @override
  String get routeManifestName => manifestName ?? super.routeManifestName;

  @override
  RouteManifestFragment<Object> get localRouteManifestFragment =>
      localFragment ?? super.localRouteManifestFragment;

  @override
  Iterable<RouteModule<AppRoute>> defineModules() =>
      _modulesBuilder?.call(this) ?? const [];

  @override
  AppRoute notFoundRoute(Uri uri) => AppRoute('not-found');
}

class NestedCoordinator extends CoordinatorCore<AppRoute>
    with
        RecordingListenable,
        CoordinatorLayoutCore<AppRoute>,
        CoordinatorNavigatable<AppRoute>,
        CoordinatorMutatable<AppRoute>,
        CoordinatorRecoverable<AppRoute>,
        CoordinatorModular<AppRoute> {
  NestedCoordinator(this._parent, {this.childModules = const []});

  final CoordinatorModular<AppRoute> _parent;
  final Iterable<RouteModule<AppRoute>> childModules;

  late final AppStackPath extra = AppStackPath(
    coordinator: this,
    debugLabel: 'nested-extra',
  );

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  @override
  StackPath<AppRoute> get root => _parent.root;

  @override
  List<StackPath> get paths => [...super.paths, extra];

  @override
  Iterable<RouteModule<AppRoute>> defineModules() => childModules;

  @override
  AppRoute notFoundRoute(Uri uri) => AppRoute('nested-not-found');

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) =>
      super.parseRouteFromUri(uri);
}

class FeatureModule extends RouteModule<AppRoute> {
  FeatureModule(
    super.coordinator, {
    this.prefix = 'feature',
    this.fragment,
    this.hasPath = false,
  });

  final String prefix;
  final RouteManifestFragment<Object>? fragment;
  final bool hasPath;

  int layoutCalls = 0;
  int converterCalls = 0;

  late final AppStackPath featurePath = AppStackPath(
    coordinator: coordinator,
    debugLabel: prefix,
  );

  @override
  List<StackPath> get paths => hasPath ? [featurePath] : super.paths;

  @override
  RouteManifest<Object> get routeManifest => fragment == null
      ? super.routeManifest
      : RouteManifest(
          name: fragment!.name,
          routes: fragment!.routes,
          layouts: fragment!.layouts,
          idCodec: fragment!.idCodec,
        );

  @override
  RouteManifestFragment<Object> get routeManifestFragment =>
      fragment ?? super.routeManifestFragment;

  @override
  void defineLayout() {
    layoutCalls++;
    super.defineLayout();
  }

  @override
  void defineConverter() {
    converterCalls++;
    super.defineConverter();
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    if (uri.pathSegments case [final first, ...] when first == prefix) {
      return AppRoute(uri.pathSegments.join('/'));
    }
    return null;
  }
}

class AsyncFeatureModule extends FeatureModule {
  AsyncFeatureModule(super.coordinator, {super.prefix, this.delay});

  final Duration? delay;

  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async {
    if (delay != null) await Future<void>.delayed(delay!);
    return super.parseRouteFromUri(uri);
  }
}
