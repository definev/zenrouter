# 0.1.0 release preparation — 2026-09-30

- Adapter analysis: passed with the installed DartNative SDK.
- Headless navigation/session suite: **26 tests passed**.
- Native DevTools analysis and lifecycle suite: **5 tests passed**.
- Example file-routing generation and analysis: passed.
- Package archives validated with local SDK/core overrides: no warnings;
  dependency-override hints remain. Archives exclude SDK caches, build output,
  generated platform runners, and local overrides.
- A dry-run without a DartNative SDK override cannot resolve `dartnative` on
  pub.dev. Public publication is gated on a supported SDK dependency/registry
  arrangement, followed by a clean consumer resolution check.

No new native device acceptance run was performed for this release preparation.
The runtime results and outstanding checks below retain their original date.

# MVP verification — 2026-09-18

## Environment

- Public DartNative checkout inspected: `46d2869`.
- Installed SDK headers stamp: `98a127957cb5426a2ae11b972203484c99d50386`.
- Zero Dart: `3.12.0-192.0.dev`; SDK was not upgraded during this implementation.
- iOS Simulator: iPhone Air, iOS 26.5, arm64, debug build.
- Existing core regression suite: Flutter stable / Dart 3.13.0.

These results apply to that installed runtime, not an assertion about newer SDK
editions. The public checkout docs and local SDK can evolve independently.

## Automated

- Package `dn pub get`: passed independently of the Flutter pub workspace.
- Package Dart analysis and example `dn analyze --no-pub`: passed.
- Root repository `flutter analyze --no-pub`: passed.
- Headless adapter test suite: **26 tests passed**, including indexed selection,
  tab guards, layout deep navigation, hierarchy replacement, and branched reset.
- Existing `zenrouter_core` regression suite: **429 tests passed**.
- iOS example build/install/launch using `dn run`: passed.

## Observed on iOS native UI

- Home → detail 42 → programmatic pop: home displays `Result: saved:42`.
- Unsaved editor → native Back: screen remains visible and guard logs false.
- Save editor → native Back: returns home; result completes with null.
- Push two detail routes with identical URI: Back removes only the top entry;
  the back-button parent changes from Detail 42 to Home as expected.
- Top replacement changes Detail 42 to Detail 99, preserving its parent.
- Reset from a multi-entry stack returns to a fresh Home with no Back button.
- Recover `/details/7` replaces root content; no phantom Home route underneath.
- Recover `/unknown` displays a not-found screen retaining that URI.
- Commit logs agree with the visible stack throughout these checks.
- The routed detent sheet opens and closes through the coordinator with
  `sheet:done`; its app-defined tracing adapter is exercised.
- The bottom-navigation layout renders Feed and Profile through DartNative's
  native tab bar. Recovering `/tabs/profile` selects Profile, pushing a global
  detail hides the bar, and native Back returns to the selected Profile tab.

## Not yet verified

- Android native runtime, hardware/system/predictive Back and root exit.
- iOS interactive gesture cancellation/completion with instant routes.
- Native error/timeout recovery on a real bridge failure (fake-driver tests cover
  fail-stop behavior, but rollback is intentionally unsupported).
- External grabber/scrim dismissal for the SDK sheet/dialog helpers. The
  installed SDK did not expose a reliable dismissal acknowledgement in this
  path, so these helpers are explicitly experimental and the custom adapter
  interface is the supported extension seam.
- Direct tab-bar tap switching and mounted-subtree persistence still need a
  complete manual acceptance pass; Android tab rendering is not yet verified.
- Independent native Navigator stacks per branch, native hot-restart adoption,
  unmanaged overlays and restoration. Logical branched paths exist, but the
  installed SDK has no public nested-Navigator host to render them natively.
