import 'dart:async';

import 'package:zenrouter_core/zenrouter_core.dart';

import '../../shared/harness.dart';

class OldBenchmarkCoordinator extends CoordinatorCore<BenchRoute>
    with BenchListenable
    implements BenchmarkCoordinator {
  final Map<Object, RouteLayoutParentConstructor> _layoutConstructors =
      <Object, RouteLayoutParentConstructor>{};

  late final ActivationPath _root = ActivationPath(
    coordinator: this,
    label: 'root',
  );
  late final ActivationPath _nestedPath = ActivationPath(
    coordinator: this,
    label: 'nested',
  );

  @override
  ActivationPath get root => _root;

  @override
  ActivationPath get nestedPath => _nestedPath;

  @override
  List<StackPath> get paths => <StackPath>[...super.paths, nestedPath];

  @override
  void defineLayout() {
    defineLayoutParentConstructor(shellLayoutKey, (_) => BenchLayout());
  }

  @override
  void defineLayoutParentConstructor(
    Object layoutKey,
    RouteLayoutParentConstructor constructor,
  ) {
    _layoutConstructors[layoutKey] = constructor;
  }

  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) =>
      _layoutConstructors[layoutKey]?.call(layoutKey);

  @override
  FutureOr<BenchRoute?> parseRouteFromUri(Uri uri) => null;

  @override
  Future<void> replaceRoute(BenchRoute route) => replace(route);

  @override
  Future<void> navigateRoute(BenchRoute route) => navigate(route);

  @override
  Future<void> pushRoute(BenchRoute route) async {
    await push<Object>(route);
  }

  @override
  void disposeCoordinator() => dispose();
}

Future<void> main(List<String> arguments) async {
  setBenchmarkArguments(arguments);
  await runBenchmarkCli(
    implementation: 'old',
    zenrouterVersion: '2.2.0',
    coreVersion: '2.1.0',
    createCoordinator: OldBenchmarkCoordinator.new,
  );
}
