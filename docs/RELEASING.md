# ZenRouter 3.0.0 and DartNative 0.1.0

This checkout prepares release metadata; it does not publish packages or create
release tags. Keep the historical beta changelog entries as the detailed record
of the 3.0 API migration.

## Package versions and publication order

Publish each prerequisite before its dependents, then wait for hosted dependency
resolution to succeed before continuing.

| Order | Package | Version | Internal requirements |
| --- | --- | --- | --- |
| 1 | `zenrouter_core` | 3.0.0 | None |
| 2 | `zenrouter_file_annotation` | 3.0.0 | None |
| 3 | `zenrouter` | 3.0.0 | core ^3.0.0 |
| 4 | `zenrouter_file_generator` | 3.0.0 | core and annotations ^3.0.0 |
| 5 | `zenrouter_devtools` | 3.0.0 | zenrouter ^3.0.0 |
| 6 | `zenrouter_dartnative` | 0.1.0 | core ^3.0.0; DartNative SDK |
| 7 | `zenrouter_dartnative_devtools` | 0.1.0 | native adapter ^0.1.0; DartNative SDK |

The Flutter workspace requires Dart 3.11 or newer because of the generator.
DartNative packages intentionally remain outside that workspace and use the
Dart executable bundled with the installed Zero/DartNative SDK.

## Verification

From the repository root:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub
```

Run `flutter test --no-pub` from each of `packages/zenrouter`,
`packages/zenrouter_core`, `packages/zenrouter_file_generator`,
`packages/zenrouter_devtools`, and `packages/zenrouter_docs`. Run the docs tests
from their package directory so their asset bundle is included. CI covers all
five suites.

For native development, use an ignored `pubspec_overrides.yaml` in each native
package. Override `zenrouter_core` to `../zenrouter_core`; in native DevTools,
also override `zenrouter_dartnative` to `../zenrouter_dartnative`. `dn pub get`
provides the SDK framework; use an explicit local `dartnative` SDK override
when running ordinary Dart pub commands. Overrides stay out of the archives.

From each native package:

```sh
dn pub get
dn analyze --no-pub
dn test
```

From `packages/zenrouter_dartnative/example`, run `dn pub get`, then use the
SDK's Dart executable to run `dart run build_runner build`. If Dart attempts
to re-resolve platform packages on pub.dev, follow the explicit SDK override
setup in the example README, preserving all existing ZenRouter overrides.
Run generation twice
to verify stable output, then `dn analyze --no-pub`. The example's
`main_file_router.dart` entry point exercises native file routing.

Before a native release, complete the device acceptance checks in
[`../packages/zenrouter_dartnative/example/README.md`](../packages/zenrouter_dartnative/example/README.md),
including system Back, guarded dismissal, pop results, indexed/branched layouts,
and inspector dismissal on iOS and Android. The dated evidence and remaining
runtime limits are in
[`../packages/zenrouter_dartnative/VERIFICATION.md`](../packages/zenrouter_dartnative/VERIFICATION.md).
The experimental presentation helpers keep that status in 0.1.0.

## Dry run and publish

Run `dart pub publish --dry-run` inside each Flutter package. Inspect its file
list and validation output. Preparation produced only the expected warning
about uncommitted tracked files; commit the reviewed release changes before
publishing and rerun the dry run.

After upstream versions are hosted, validate an isolated consumer without
workspace resolution or local overrides. This proves the shipped constraints
resolve the published artifacts rather than this checkout.

**Native publication gate:** the installed SDK provides `dartnative` 1.0.0,
while a clean public pub.dev resolution currently cannot find that package.
The native archive checks pass with local overrides, which do not establish
public dependency availability. Confirm a supported SDK dependency/registry
arrangement before publishing either native package. Do not bypass validation
or treat `dn publish` as interchangeable with `dart pub publish`: this SDK's
`dn publish` builds and uploads registered binary plugins to dartpub.dev.
These adapters are Dart source packages and have no registered native plugin
build configured here.

Once validation and consumer checks pass, publish the Flutter packages in the
order above with `dart pub publish`. Tag the committed release as `v3.0.0`.
Publish and tag the native family separately after its publication gate and
native acceptance checks pass. Do not include machine-local overrides or SDK
headers in either release.

Publishing conventions: [Dart package publishing](https://dart.dev/tools/pub/publishing).

## Preparation evidence — 2026-09-30

- Formatting and Flutter workspace analysis passed.
- Router/core/generator: 1,179 tests passed; Flutter DevTools: 79;
  documentation: 16; native adapter: 26; native DevTools: 5.
- Native package and example analysis passed; native file routing generated.
- Documentation web release built successfully. The build still reports
  Material/Cupertino font-family references from dependencies; the docs use
  Forui icons and do not declare those font assets.
- Five stable package dry runs validated with only dirty-checkout warnings.
- Two native archives validated with local SDK overrides and override hints;
  the public dependency availability gate above remains open.
