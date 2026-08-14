import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:zenrouter_core/zenrouter_core.dart';

typedef CoordinatorFactory = BenchmarkCoordinator Function();
typedef BatchRunner = Future<int> Function(int iterations);
typedef BenchmarkVoidCallback = void Function();

int _blackHole = 0;

abstract interface class BenchmarkCoordinator {
  ActivationPath get root;

  ActivationPath get nestedPath;

  Future<void> replaceRoute(BenchRoute route);

  Future<void> navigateRoute(BenchRoute route);

  Future<void> pushRoute(BenchRoute route);

  void disposeCoordinator();
}

mixin BenchListenable {
  final List<BenchmarkVoidCallback> _listeners = <BenchmarkVoidCallback>[];

  void addListener(BenchmarkVoidCallback listener) => _listeners.add(listener);

  void removeListener(BenchmarkVoidCallback listener) =>
      _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List<BenchmarkVoidCallback>.of(_listeners)) {
      listener();
    }
  }
}

class BenchRoute extends RouteUri {
  BenchRoute(this.id, {this.parentKey});

  final int id;
  final Object? parentKey;

  @override
  Object? get parentLayoutKey => parentKey;

  @override
  Uri toUri() => Uri(path: '/bench/$id');

  @override
  List<Object?> get props => <Object?>[id];
}

const Object shellLayoutKey = #benchmarkShell;

class BenchLayout extends BenchRoute with RouteLayoutParent<BenchRoute> {
  BenchLayout() : super(-1);

  @override
  Object get layoutKey => shellLayoutKey;

  @override
  StackPath<BenchRoute> resolvePath(CoordinatorCore coordinator) =>
      (coordinator as BenchmarkCoordinator).nestedPath;
}

class ActivationPath extends StackPath<BenchRoute>
    with BenchListenable
    implements StackNavigatable<BenchRoute> {
  ActivationPath({required CoordinatorCore coordinator, required String label})
      : super(<BenchRoute>[], coordinator: coordinator, debugLabel: label);

  @override
  BenchRoute? get activeRoute => stack.isEmpty ? null : stack.last;

  @override
  PathKey get pathKey => const PathKey('benchmark-activation');

  @override
  void reset() {
    clear();
  }

  @override
  Future<void> activateRoute(BenchRoute route) async {
    bindStack(<BenchRoute>[route]);
    notifyListeners();
  }

  @override
  Future<void> navigate(BenchRoute route) => activateRoute(route);
}

class MutationPath extends StackPath<BenchRoute>
    with BenchListenable, StackMutatable<BenchRoute> {
  MutationPath() : super(<BenchRoute>[], debugLabel: 'benchmark-mutation');

  @override
  BenchRoute? get activeRoute => stack.isEmpty ? null : stack.last;

  @override
  PathKey get pathKey => const PathKey('benchmark-mutation');

  void seed(List<BenchRoute> routes) => bindStack(routes);

  @override
  void reset() {
    clear();
  }

  @override
  Future<void> activateRoute(BenchRoute route) async {
    bindStack(<BenchRoute>[route]);
    notifyListeners();
  }
}

class BenchmarkCase {
  const BenchmarkCase({
    required this.name,
    required this.description,
    required this.run,
    this.iterationScale = 1,
  });

  final String name;
  final String description;
  final BatchRunner run;
  final double iterationScale;
}

List<BenchmarkCase> createBenchmarkCases(CoordinatorFactory createCoordinator) {
  return <BenchmarkCase>[
    BenchmarkCase(
      name: 'path_push_pop',
      description: 'StackMutatable push-to-result lifecycle followed by pop',
      iterationScale: 0.5,
      run: (iterations) async {
        final path = MutationPath();
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          final route = BenchRoute(i);
          final pendingResult = path.push<int>(route);
          await Future<void>.value();
          await path.pop(i);
          route.completeOnResult(i, null);
          route.onDidPop(i, null);
          _blackHole ^= (await pendingResult) ?? 0;
        }
        stopwatch.stop();
        return stopwatch.elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'path_push_or_move_to_top',
      description: 'Move an equal route through a 32-entry mutable path',
      iterationScale: 0.5,
      run: (iterations) async {
        final path = MutationPath();
        path.seed(List<BenchRoute>.generate(32, BenchRoute.new));
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          await path.pushOrMoveToTop(BenchRoute(i & 31));
        }
        stopwatch.stop();
        _blackHole ^= path.activeRoute?.id ?? 0;
        return stopwatch.elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'path_navigate_depth_32',
      description:
          'Navigate from the top to the first route in a 32-entry path',
      iterationScale: 0.05,
      run: (iterations) async {
        final path = MutationPath();
        var elapsedMicroseconds = 0;
        for (var i = 0; i < iterations; i++) {
          final routes = List<BenchRoute>.generate(
            32,
            (index) => BenchRoute((i << 5) | index),
          );
          path.seed(routes);
          final stopwatch = Stopwatch()..start();
          await path.navigate(routes.first);
          stopwatch.stop();
          elapsedMicroseconds += stopwatch.elapsedMicroseconds;
          _blackHole ^= path.activeRoute?.id ?? 0;
        }
        return elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'coordinator_replace_flat',
      description: 'Resolve and replace a flat route through Coordinator',
      run: (iterations) async {
        final coordinator = createCoordinator();
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          await coordinator.replaceRoute(BenchRoute(i));
        }
        stopwatch.stop();
        _blackHole ^= coordinator.root.activeRoute?.id ?? 0;
        coordinator.disposeCoordinator();
        return stopwatch.elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'coordinator_navigate_flat',
      description: 'Resolve and navigate through a StackNavigatable path',
      run: (iterations) async {
        final coordinator = createCoordinator();
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          await coordinator.navigateRoute(BenchRoute(i));
        }
        stopwatch.stop();
        _blackHole ^= coordinator.root.activeRoute?.id ?? 0;
        coordinator.disposeCoordinator();
        return stopwatch.elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'coordinator_push_fallback',
      description: 'Push through a non-mutatable path using activateRoute',
      run: (iterations) async {
        final coordinator = createCoordinator();
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          await coordinator.pushRoute(BenchRoute(i));
        }
        stopwatch.stop();
        _blackHole ^= coordinator.root.activeRoute?.id ?? 0;
        coordinator.disposeCoordinator();
        return stopwatch.elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'coordinator_replace_nested',
      description: 'Resolve a layout parent and replace its nested route',
      iterationScale: 0.5,
      run: (iterations) async {
        final coordinator = createCoordinator();
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          await coordinator
              .replaceRoute(BenchRoute(i, parentKey: shellLayoutKey));
        }
        stopwatch.stop();
        _blackHole ^= coordinator.nestedPath.activeRoute?.id ?? 0;
        coordinator.disposeCoordinator();
        return stopwatch.elapsedMicroseconds;
      },
    ),
    BenchmarkCase(
      name: 'coordinator_create_dispose',
      description: 'Construct, initialize, and dispose a Coordinator',
      iterationScale: 0.5,
      run: (iterations) async {
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < iterations; i++) {
          final coordinator = createCoordinator();
          _blackHole ^= coordinator.root.hashCode;
          coordinator.disposeCoordinator();
        }
        stopwatch.stop();
        return stopwatch.elapsedMicroseconds;
      },
    ),
  ];
}

Future<void> runBenchmarkCli({
  required String implementation,
  required String zenrouterVersion,
  required String coreVersion,
  required CoordinatorFactory createCoordinator,
}) async {
  final options = _CliOptions.parse(arguments: _benchmarkArguments);
  final cases = createBenchmarkCases(
    createCoordinator,
  )
      .where(
          (benchmark) => options.only == null || benchmark.name == options.only)
      .toList();
  if (cases.isEmpty) {
    throw ArgumentError.value(options.only, '--only', 'Unknown benchmark');
  }
  final rotation = options.rotation % cases.length;
  final orderedCases = <BenchmarkCase>[
    ...cases.skip(rotation),
    ...cases.take(rotation),
  ];
  final results = <Map<String, Object?>>[];

  for (final benchmark in orderedCases) {
    if (options.verbose) stderr.writeln('benchmark: ${benchmark.name}');
    final iterations = (options.iterations * benchmark.iterationScale)
        .round()
        .clamp(1, 1 << 30)
        .toInt();
    final warmupIterations = (options.warmup * benchmark.iterationScale)
        .round()
        .clamp(1, 1 << 30)
        .toInt();

    await benchmark.run(warmupIterations);
    final samples = <double>[];
    for (var sample = 0; sample < options.samples; sample++) {
      final elapsedMicroseconds = await benchmark.run(iterations);
      samples.add(elapsedMicroseconds * 1000 / iterations);
    }

    results.add(<String, Object?>{
      'name': benchmark.name,
      'description': benchmark.description,
      'iterations_per_sample': iterations,
      'samples_ns_per_op': samples,
    });
  }

  print(
    jsonEncode(<String, Object?>{
      'schema_version': 1,
      'implementation': implementation,
      'zenrouter_version': zenrouterVersion,
      'zenrouter_core_version': coreVersion,
      'runtime': 'dart-aot',
      'benchmarks': results,
      'checksum': _blackHole,
    }),
  );
}

List<String> _benchmarkArguments = const <String>[];

void setBenchmarkArguments(List<String> arguments) {
  _benchmarkArguments = List<String>.unmodifiable(arguments);
}

class _CliOptions {
  const _CliOptions({
    required this.samples,
    required this.iterations,
    required this.warmup,
    required this.rotation,
    required this.only,
    required this.verbose,
  });

  factory _CliOptions.parse({required List<String> arguments}) {
    int read(String name, int fallback) {
      final prefix = '--$name=';
      final value = arguments
          .where((argument) => argument.startsWith(prefix))
          .map((argument) => argument.substring(prefix.length))
          .firstOrNull;
      return value == null ? fallback : int.parse(value);
    }

    return _CliOptions(
      samples: read('samples', 10),
      iterations: read('iterations', 100000),
      warmup: read('warmup', 10000),
      rotation: read('rotation', 0),
      only: arguments
          .where((argument) => argument.startsWith('--only='))
          .map((argument) => argument.substring('--only='.length))
          .firstOrNull,
      verbose: arguments.contains('--verbose'),
    );
  }

  final int samples;
  final int iterations;
  final int warmup;
  final int rotation;
  final String? only;
  final bool verbose;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
