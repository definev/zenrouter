# ZenRouter 2.2.0 comparison benchmark

This harness compares the current workspace implementation with the exact
dependency pair shipped by ZenRouter 2.2.0:

- old: `zenrouter 2.2.0` + `zenrouter_core 2.1.0`
- current: workspace `zenrouter` + `zenrouter_core`

ZenRouter 2.2.0 delegated coordinator operations to `zenrouter_core 2.1.0`, so
the timed executable imports the core library directly. This keeps the runner
pure Dart and measures the capability-mixin refactor without Flutter engine or
widget-test noise.

## Run

From the repository root:

```sh
fvm dart run benchmark/zenrouter/run.dart \
  --output=benchmark/zenrouter/results/latest.json
```

Use `--offline` once both old packages exist in the pub cache. For a quick
smoke run:

```sh
fvm dart run benchmark/zenrouter/run.dart \
  --trials=1 --samples=3 --iterations=500 --warmup=100
```

Each compiled child runner also accepts `--only=<benchmark-name>` and
`--verbose`, which is useful when profiling or debugging an individual case.

The driver:

1. resolves each dependency graph independently;
2. compiles both runners to native AOT executables;
3. alternates old/current process order between trials;
4. rotates benchmark order between trials;
5. reports median, p95, mean, standard deviation, raw samples, and AOT size.

Default iteration counts target tens of milliseconds per sample on a modern
desktop. If a workload finishes in only a few milliseconds on your machine,
increase `--iterations` before treating its numbers as a baseline.

Lower `ns/op` is better. A positive delta means the current implementation is
slower; a speedup greater than `1.0x` means the current implementation is
faster.

## Workloads

- mutable path push/pop lifecycle;
- push-or-move-to-top through 32 routes;
- navigate back through a 32-route path;
- flat coordinator replace, navigate, and push fallback;
- nested-layout resolution and replace;
- coordinator construction and disposal.

Route construction is included where it is part of the public operation.
Fixture setup for the depth-32 navigation case is outside the timer.

## Interpretation

Results are machine-specific. Do not use a single run as a CI gate. Compare
multiple trials on an idle machine, keep the Dart/Flutter SDK fixed, inspect
raw samples for variance, and confirm material regressions with a profiler.

This harness does not measure Flutter widget construction, frame time, route
transition animation, browser history, or application startup.

## Recorded baselines

- [2026-08-13](results/2026-08-13.md) — Dart 3.13.0 AOT on macOS arm64
