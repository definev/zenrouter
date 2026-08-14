import 'dart:async';

import 'package:zenrouter_core/zenrouter_core.dart';

import '../../shared/harness.dart';

class CurrentBenchmarkCoordinator extends CoordinatorCore<BenchRoute>
    with
        CoordinatorLayoutCore<BenchRoute>,
        CoordinatorNavigatable<BenchRoute>,
        CoordinatorMutatable<BenchRoute>,
        BenchListenable
    implements BenchmarkCoordinator {
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
    implementation: 'current',
    zenrouterVersion: 'workspace',
    coreVersion: 'workspace',
    createCoordinator: CurrentBenchmarkCoordinator.new,
  );
}
