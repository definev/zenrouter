import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  final benchmarkDirectory = File.fromUri(Platform.script).parent;
  final repositoryRoot = benchmarkDirectory.parent.parent;
  final currentDirectory = Directory.fromUri(
    benchmarkDirectory.uri.resolve('current/'),
  );
  final oldDirectory = Directory.fromUri(
    benchmarkDirectory.uri.resolve('old/'),
  );
  final artifactsDirectory = Directory.fromUri(
    repositoryRoot.uri.resolve('.dart_tool/zenrouter_benchmark/'),
  );
  artifactsDirectory.createSync(recursive: true);

  final dart = Platform.resolvedExecutable;
  final flutter = _findFlutterExecutable(dart);
  final currentExecutable = File.fromUri(
    artifactsDirectory.uri.resolve('current_benchmark'),
  );
  final oldExecutable = File.fromUri(
    artifactsDirectory.uri.resolve('old_benchmark'),
  );

  stdout.writeln('Resolving benchmark dependencies...');
  await _run(
    flutter,
    <String>['pub', 'get', if (options.offline) '--offline'],
    currentDirectory,
  );
  await _run(
    flutter,
    <String>['pub', 'get', if (options.offline) '--offline'],
    oldDirectory,
  );

  stdout.writeln('Compiling AOT benchmark executables...');
  await _run(
    dart,
    <String>[
      'compile',
      'exe',
      'bin/benchmark.dart',
      '-o',
      currentExecutable.path,
    ],
    currentDirectory,
  );
  await _run(
    dart,
    <String>[
      'compile',
      'exe',
      'bin/benchmark.dart',
      '-o',
      oldExecutable.path,
    ],
    oldDirectory,
  );

  final rawRuns = <String, List<Map<String, Object?>>>{
    'old': <Map<String, Object?>>[],
    'current': <Map<String, Object?>>[],
  };

  for (var trial = 0; trial < options.trials; trial++) {
    final order = trial.isEven
        ? <(String, File)>[
            ('old', oldExecutable),
            ('current', currentExecutable)
          ]
        : <(String, File)>[
            ('current', currentExecutable),
            ('old', oldExecutable)
          ];
    for (final (label, executable) in order) {
      stdout.writeln('Running $label trial ${trial + 1}/${options.trials}...');
      final result = await Process.run(
        executable.path,
        <String>[
          '--samples=${options.samples}',
          '--iterations=${options.iterations}',
          '--warmup=${options.warmup}',
          '--rotation=$trial',
          if (options.only != null) '--only=${options.only}',
          if (options.verbose) '--verbose',
        ],
        workingDirectory: benchmarkDirectory.path,
      );
      if (result.exitCode != 0) {
        stderr.write(result.stderr);
        throw ProcessException(
            executable.path, const <String>[], '', result.exitCode);
      }
      rawRuns[label]!.add(
        (jsonDecode((result.stdout as String).trim()) as Map).cast(),
      );
    }
  }

  final report = await _buildReport(
    options: options,
    repositoryRoot: repositoryRoot,
    currentExecutable: currentExecutable,
    oldExecutable: oldExecutable,
    rawRuns: rawRuns,
  );

  _printSummary(report);
  if (options.output != null) {
    final output = File(
      options.output!.startsWith('/')
          ? options.output!
          : File.fromUri(repositoryRoot.uri.resolve(options.output!)).path,
    );
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n');
    stdout.writeln('\nWrote ${output.path}');
  }
}

Future<Map<String, Object?>> _buildReport({
  required _Options options,
  required Directory repositoryRoot,
  required File currentExecutable,
  required File oldExecutable,
  required Map<String, List<Map<String, Object?>>> rawRuns,
}) async {
  final byImplementation = <String, Map<String, Object?>>{};
  for (final label in <String>['old', 'current']) {
    final runs = rawRuns[label]!;
    final samplesByName = <String, List<double>>{};
    final descriptions = <String, String>{};
    final iterations = <String, int>{};
    for (final run in runs) {
      for (final rawBenchmark in run['benchmarks']! as List) {
        final benchmark = (rawBenchmark as Map).cast<String, Object?>();
        final name = benchmark['name']! as String;
        descriptions[name] = benchmark['description']! as String;
        iterations[name] = benchmark['iterations_per_sample']! as int;
        samplesByName.putIfAbsent(name, () => <double>[]).addAll(
              (benchmark['samples_ns_per_op']! as List).cast<num>().map(
                    (value) => value.toDouble(),
                  ),
            );
      }
    }
    byImplementation[label] = <String, Object?>{
      'zenrouter_version': runs.first['zenrouter_version'],
      'zenrouter_core_version': runs.first['zenrouter_core_version'],
      'executable_size_bytes':
          (label == 'old' ? oldExecutable : currentExecutable).lengthSync(),
      'benchmarks': <String, Object?>{
        for (final entry in samplesByName.entries)
          entry.key: <String, Object?>{
            'description': descriptions[entry.key],
            'iterations_per_sample': iterations[entry.key],
            ..._statistics(entry.value),
            'samples_ns_per_op': entry.value,
          },
      },
    };
  }

  final oldBenchmarks =
      (byImplementation['old']!['benchmarks']! as Map).cast<String, Object?>();
  final currentBenchmarks = (byImplementation['current']!['benchmarks']! as Map)
      .cast<String, Object?>();
  final comparisons = <String, Object?>{};
  for (final name in oldBenchmarks.keys) {
    final oldStats = (oldBenchmarks[name]! as Map).cast<String, Object?>();
    final currentStats =
        (currentBenchmarks[name]! as Map).cast<String, Object?>();
    final oldMedian = oldStats['median_ns_per_op']! as double;
    final currentMedian = currentStats['median_ns_per_op']! as double;
    comparisons[name] = <String, Object?>{
      'old_median_ns_per_op': oldMedian,
      'current_median_ns_per_op': currentMedian,
      'delta_percent': (currentMedian - oldMedian) * 100 / oldMedian,
      'speedup': oldMedian / currentMedian,
    };
  }

  final gitRevision = await Process.run(
    'git',
    const <String>['rev-parse', 'HEAD'],
    workingDirectory: repositoryRoot.path,
  );
  final gitStatus = await Process.run(
    'git',
    const <String>['status', '--porcelain'],
    workingDirectory: repositoryRoot.path,
  );
  final architecture = await Process.run('uname', const <String>['-m']);

  return <String, Object?>{
    'schema_version': 1,
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'scope': 'ZenRouter core navigation operations (no widget rendering)',
    'old_dependency': 'zenrouter 2.2.0 / zenrouter_core 2.1.0',
    'current_dependency': 'workspace zenrouter / zenrouter_core',
    'runtime': 'dart-aot',
    'environment': <String, Object?>{
      'dart_version': Platform.version,
      'operating_system': Platform.operatingSystem,
      'operating_system_version': Platform.operatingSystemVersion,
      'architecture': (architecture.stdout as String).trim(),
      'processors': Platform.numberOfProcessors,
      'git_revision': (gitRevision.stdout as String).trim(),
      'working_tree_dirty': (gitStatus.stdout as String).trim().isNotEmpty,
    },
    'configuration': <String, Object?>{
      'trials': options.trials,
      'samples_per_trial': options.samples,
      'base_iterations_per_sample': options.iterations,
      'base_warmup_iterations': options.warmup,
    },
    'implementations': byImplementation,
    'comparison': comparisons,
  };
}

Map<String, Object?> _statistics(List<double> samples) {
  final sorted = List<double>.of(samples)..sort();
  final mean = sorted.reduce((a, b) => a + b) / sorted.length;
  final variance = sorted
          .map((sample) => math.pow(sample - mean, 2).toDouble())
          .reduce((a, b) => a + b) /
      sorted.length;
  return <String, Object?>{
    'median_ns_per_op': _percentile(sorted, 0.5),
    'p95_ns_per_op': _percentile(sorted, 0.95),
    'mean_ns_per_op': mean,
    'standard_deviation_ns_per_op': math.sqrt(variance),
    'min_ns_per_op': sorted.first,
    'max_ns_per_op': sorted.last,
  };
}

double _percentile(List<double> sorted, double percentile) {
  if (sorted.length == 1) return sorted.single;
  final position = (sorted.length - 1) * percentile;
  final lower = position.floor();
  final upper = position.ceil();
  if (lower == upper) return sorted[lower];
  final fraction = position - lower;
  return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
}

void _printSummary(Map<String, Object?> report) {
  final comparison = (report['comparison']! as Map).cast<String, Object?>();
  stdout.writeln('\nZenRouter benchmark (median ns/op; lower is better)');
  stdout.writeln('| benchmark | old 2.2.0 | current | delta | speedup |');
  stdout.writeln('|---|---:|---:|---:|---:|');
  for (final entry in comparison.entries) {
    final values = (entry.value! as Map).cast<String, Object?>();
    final delta = values['delta_percent']! as double;
    stdout.writeln(
      '| ${entry.key} '
      '| ${(values['old_median_ns_per_op']! as double).toStringAsFixed(1)} '
      '| ${(values['current_median_ns_per_op']! as double).toStringAsFixed(1)} '
      '| ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% '
      '| ${(values['speedup']! as double).toStringAsFixed(3)}x |',
    );
  }

  final implementations =
      (report['implementations']! as Map).cast<String, Object?>();
  final oldSize =
      ((implementations['old']! as Map)['executable_size_bytes']! as int);
  final currentSize =
      ((implementations['current']! as Map)['executable_size_bytes']! as int);
  final delta = (currentSize - oldSize) * 100 / oldSize;
  stdout.writeln(
    '\nAOT executable: old ${_bytes(oldSize)}, current ${_bytes(currentSize)} '
    '(${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}%).',
  );
}

String _bytes(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(2)} MiB';

String _findFlutterExecutable(String dartExecutable) {
  var directory = File(dartExecutable).parent;
  while (true) {
    final candidate = File.fromUri(directory.uri.resolve('flutter'));
    if (candidate.existsSync()) return candidate.path;

    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  throw StateError(
    'Could not locate the Flutter executable above $dartExecutable. '
    'Run this driver with `fvm dart run` or a Dart SDK bundled with Flutter.',
  );
}

Future<void> _run(
  String executable,
  List<String> arguments,
  Directory workingDirectory,
) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
  );
  if (result.exitCode != 0) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    throw ProcessException(executable, arguments, '', result.exitCode);
  }
}

class _Options {
  const _Options({
    required this.trials,
    required this.samples,
    required this.iterations,
    required this.warmup,
    required this.offline,
    required this.output,
    required this.only,
    required this.verbose,
  });

  factory _Options.parse(List<String> arguments) {
    String? read(String name) {
      final prefix = '--$name=';
      for (final argument in arguments) {
        if (argument.startsWith(prefix))
          return argument.substring(prefix.length);
      }
      return null;
    }

    if (arguments.contains('--help') || arguments.contains('-h')) {
      stdout.writeln('''
Usage: dart run benchmark/zenrouter/run.dart [options]

  --trials=N       Alternating old/current process trials (default: 3)
  --samples=N      Samples per benchmark per trial (default: 10)
  --iterations=N   Base operations per sample (default: 100000)
  --warmup=N       Base warm-up operations (default: 10000)
  --output=PATH    Write the complete JSON report
  --offline        Resolve dependencies from the pub cache only
  --only=NAME      Run one benchmark case
  --verbose        Print each child benchmark as it starts
''');
      exit(0);
    }

    return _Options(
      trials: int.parse(read('trials') ?? '3'),
      samples: int.parse(read('samples') ?? '10'),
      iterations: int.parse(read('iterations') ?? '100000'),
      warmup: int.parse(read('warmup') ?? '10000'),
      offline: arguments.contains('--offline'),
      output: read('output'),
      only: read('only'),
      verbose: arguments.contains('--verbose'),
    );
  }

  final int trials;
  final int samples;
  final int iterations;
  final int warmup;
  final bool offline;
  final String? output;
  final String? only;
  final bool verbose;
}
