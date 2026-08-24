This guide targets ZenRouter 3, currently published as a prerelease. Pinning the intended version is the first correctness check; otherwise you can copy a valid 3.0 example into a project that resolved 2.x APIs.

## Prerequisites

You need a Flutter project that can run on at least one target and a supported Dart SDK from the workspace. Start from a clean analyzer result so routing errors are not mixed with unrelated project failures.

Check the versions your project actually uses:

```bash
flutter --version
dart --version
```

If the repository uses FVM, run the same commands through `fvm` and continue using that prefix for generation, tests, and builds.

## Install the Coordinator package

Pin the beta explicitly:

```yaml
dependencies:
  flutter:
    sdk: flutter
  zenrouter: ^3.0.0-beta.1
```

Then resolve dependencies:

```bash
flutter pub get
```

For a hand-written graph, that is the complete dependency setup. You define the manifest, bindings, route targets, and Coordinator in normal Dart files.

## Optional file-based routing

Choose file generation when a `lib/routes/` directory should own the public graph. Add the annotations at runtime and the generator at development time:

```yaml
dependencies:
  zenrouter: ^3.0.0-beta.1
  zenrouter_file_annotation: ^3.0.0-beta.1

dev_dependencies:
  build_runner: ^2.10.4
  zenrouter_file_generator: ^3.0.0-beta.1
```

Generate after adding or renaming route files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files are checked-in output in this repository. Review the emitted manifest, bindings, locations, and deferred imports just as you review hand-written routing code.

## Optional DevTools

Add the debugging package only to applications that need the overlay and graph inspection:

```bash
flutter pub add zenrouter_devtools
```

Enable it on the Coordinator:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug<AppRoute> {}
```

The debug surface is designed for development and defaults to disabled behavior in release builds.

## Package boundaries

| Package | Responsibility |
| --- | --- |
| `zenrouter` | Flutter Coordinator, stacks, layouts, restoration, transitions |
| `zenrouter_core` | Adapter-neutral targets, paths, manifests, bindings, commits |
| `zenrouter_file_annotation` | Route, layout, and Coordinator annotations |
| `zenrouter_file_generator` | Generated manifest, bindings, locations, and imports |
| `zenrouter_devtools` | Overlay, route inspection, problems, graph, observed flow |

Most Flutter apps depend only on `zenrouter`. The other packages exist so generation, headless graph contracts, and debugging do not become one inseparable dependency.

## Handwritten or generated?

Use a handwritten graph when the route set is small, explicit composition is valuable, or you are migrating one slice at a time. Use file routing when route ownership naturally follows folders and the team benefits from generated locations and deferred imports.

Both produce the same concepts. Generation does not replace the manifest; it writes it.

## Verify the setup

Create a minimal import and let the analyzer prove resolution:

```dart
import 'package:zenrouter/zenrouter.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}
```

Run:

```bash
flutter analyze
flutter test
```

If generation is enabled, also confirm that the generated Coordinator exports a non-empty `RouteManifest` and a `location` surface.

## Common installation failures

**2.x was selected.** Inspect `pubspec.lock` and pin `^3.0.0-beta.1` instead of relying on the default stable resolver.

**Generator and annotations are on different release lines.** Keep the ZenRouter packages on compatible versions.

**Generated code is stale.** Re-run `build_runner` after route file changes and include the generated diff in review.

**The app imports `zenrouter_core` for Flutter widgets.** Use `zenrouter`; it re-exports the public graph contracts and adds the Flutter adapter.

## Checkpoint

Dependency resolution, analysis, and a test run complete on the intended 3.0 beta line. If using file routing, generation is deterministic and leaves no unexpected diff on a second run.

Next, **Build your first graph** turns this setup into a two-screen, URL-aware Compass app.
