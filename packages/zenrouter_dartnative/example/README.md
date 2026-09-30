# ZenRouter × DartNative playground

The default `lib/main.dart` uses hand-written coordinators and URI parsers.
It demonstrates nested layouts, coordinators used as route modules, route
results, and application-defined presentations. No manifest or generation step
is needed for this entry point.

In debug builds, the **Routes** button opens `zenrouter_dartnative_devtools`
as a native sheet. Inspect paths, switch tabs, and try URI or quick-route
actions. The launcher is present on pushed screens; release builds omit it.

## Run

From this directory, with DartNative installed and its normal licence setup:

```sh
dn create --platforms=ios,android --project-name=zenrouter_dartnative_example --org=dev.zenrouter --no-pub .
dn pub get
dn run
```

Platform scaffolding and the generated plugin registrant are not committed.
Do not use `--overwrite` when generating scaffolding. Use a cold launch:
native hot-restart route replay is not integrated with the coordinator.

## Adapted playground examples

Source: the local `DartNative/dartnative/playground/lib/screens` checkout.
These are focused adaptations; they add route navigation to the widget demos.

| Original | Example | Adaptation |
| --- | --- | --- |
| `state_basics_demo.dart` | `lib/controls/counter_demo.dart` | Signal/computed counter and effect; subscriptions belong to the mounted widget. Push a detail from the feature coordinator and await its result. |
| `radio_check_demo.dart` | `lib/controls/selection_demo.dart` | Checkbox/radio state persists while switching tabs and sections. |
| `grid_demo.dart` | `lib/gallery/grid_demo.dart` | Local `GridView.count` and `GridView.builder` tiles; select a tile through a routed detail screen. |
| `color_picker_demo.dart` | `lib/gallery/palette_demo.dart` | Live color preview and luminance-based text contrast. A routed palette replaces the iOS-only system picker, with apply/cancel results on both platforms. |

The selected demos need no network, image assets, or extra widget plugins.

## Layout and module structure

```text
AppCoordinator + CoordinatorModular<AppRoute>
  root: PlaygroundLayout                       ← one CoordinatorView
    sections: BranchedStackPath
      ControlsLayout                           ← ControlsCoordinator
        tabs: IndexedStackPath
          CounterRoute    /controls/counter
          SelectionRoute  /controls/selection
      GalleryLayout                            ← GalleryCoordinator
        tabs: IndexedStackPath
          GridRoute       /gallery/grid
          PaletteRoute    /gallery/palette
  pushed screens on the same root:
    TileRoute             /gallery/tile/:id
    PalettePickerRoute    /gallery/pick?color=FFE74C3C
    HomeRoute             /navigation           ← navigation lab
    DetailRoute           /details/:id
    EditorRoute           /editor
    SheetRoute            /sheet
```

- `AppCoordinator.defineModules()` registers two **Coordinator subclasses**.
  Each overrides `coordinator` with its parent; it needs no initial route or
  separate host. Each owns its parser, paths, and layout registration.
- `bindLayout` registers the layout on its path. A leaf's `layout` getter
  identifies its parent. The two feature layouts themselves belong to
  `PlaygroundLayout`, giving two levels of navigation.
- The outer layout renders bottom navigation; `FeatureTabs` renders an inner
  button bar. Both use `IndexedStackPathBuilder` snapshots. Neither widget owns
  a duplicate selected-index variable. The URI label observes committed state.
- `IndexedStack` keeps the demo subtrees mounted when changing tabs/sections.
  Each branch also retains its selected inner tab. `replace`/`recoverUri` resets
  navigation paths; widget state only persists for the lifetime of its subtree.
- Modules return `null` for unhandled URIs, allowing composition and the root's
  not-found fallback. `/gallery/tile/:id` validates IDs from 1 through 12.
- Counter → Gallery demonstrates `getModule<GalleryCoordinator>()` followed by
  navigation through that coordinator. Gallery pushes details and picks colors
  using its own coordinator; the parent host presents them.

There is one physical native stack. Detail routes have no parent layout, so they
cover the shell and reveal the same selected tabs on Back. This example does
not create independent native Navigators inside each branch.

`main.dart` resolves `INITIAL_URI` (default `/controls/counter`) before mounting
the host. For example, set its value to `/gallery/palette` to start with both
layout levels selected by URI. The Navigation lab also includes URI recovery
buttons for this destination and an unknown URI.

## Extension points

### Add a demo to a feature

1. Add an `AppRoute` with `toUri`, `build`, and `layout` pointing to the feature
   layout. Use a fresh route instance for each navigation request.
2. Add the fixed tab route to the feature's `IndexedStackPath`, its label to
   `FeatureTabs`, and a matching case to that coordinator's parser.
3. For a pushed detail or picker, omit the layout and use `push<R>` / `pop(result)`.

### Add a feature coordinator

Follow `ControlsCoordinator`: extend `Coordinator<AppRoute>`, initialize its
`coordinator` field from the parent constructor, and contribute paths through
`paths`. Register it in `AppCoordinator.defineModules()`; add its layout to the
outer branched path and its navigation item to `PlaygroundLayout`.

### Change layout widgets

Replace the body of `FeatureTabs` or `PlaygroundLayout.build` while keeping the
same path and snapshot. Layout rendering is ordinary DartNative widget code.

### Extend presentation

`lib/tracing_presentation.dart` implements `Presentation`, wraps a delegate's
handle, and logs present/dismiss/result using the entry token. `TileRoute` and
`PalettePickerRoute` compose it with `ScreenPresentation`; `SheetRoute` uses the
same wrapper around `ExperimentalModalSheetPresentation`.

A different adapter can implement this same interface with a plugin controller.
It must render `context.builder`, forward dismissal, and report actual removal
through its result future or the mounted subtree's dismissal signals. The host
and the coordinators do not need concrete-type branches for the new adapter.

## Walkthrough on a device

These are manual checks to perform after launching; static analysis does not
verify native rendering or gesture behavior.

1. Increment Counter, change Selection options, then visit Gallery and return.
   Both the state and each section's selected inner tab should persist.
2. Use Counter's “Go to Gallery / Grid” action. The bottom bar, inner selection,
   and URI label should all select `/gallery/grid`.
3. Tap tile 4, choose it, and confirm the grid displays `Chosen tile: 4`.
   Repeat with native Back: canceling must preserve the previous choice.
4. Open Palette, choose a color, preview another swatch, and apply it. Reopen
   and cancel or use Back: the applied color should remain unchanged. Observe
   `[Presentation]` logs for the pushed picker and its result.
5. Open Navigation and recover `/gallery/palette`. Both layout levels should
   select correctly. Recover an unknown URI and check the not-found screen.
6. In Navigation, open detail 42 and return `saved:42`. Push the same URI twice;
   Back must remove only the top instance. Replace the top with detail 99.
7. Open the guarded editor: Back initially stays blocked. Save and go back;
   reopen, allow the next back via its async guard, and confirm one pop.
8. Recover `/details/7`: it becomes the root. “Reset to playground” should
   return to Controls/Counter with no old detail beneath it.
9. Open the experimental sheet from Navigation and close with its coordinator
   button. Expect `sheet:done`. External grabber/scrim dismissal remains outside
   the installed SDK adapter's supported synchronization contract.
10. On Android, check system Back and root exit. On iOS, check the back button
    and both cancelled and completed interactive back gestures.

Any `ZENROUTER ERROR` is a failed synchronization; cold restart before continuing.
Mount acknowledgement is not native animation completion. Use coordinator
navigation and route presentations throughout this host.

## Separate file-based routing entry point

To try the file-based routing entry point, run `dn pub get`, then use the Dart
executable bundled with the same DartNative SDK to run
`dart run build_runner build`. Launch with
`dn run --target lib/main_file_router.dart`.

If the SDK's `dart run` attempts to resolve `dartnative_ios` or
`dartnative_android` from pub.dev, add an ignored `pubspec_overrides.yaml`
pointing those packages and `dartnative` at the installed SDK. Preserve all
local ZenRouter overrides too; an overrides file replaces the pubspec's
`dependency_overrides` block:

```yaml
dependency_overrides:
  dartnative:
    path: /path/to/zero/bin/cache/pkg/dartnative
  dartnative_ios:
    path: /path/to/zero/bin/cache/pkg/dartnative_ios
  dartnative_android:
    path: /path/to/zero/bin/cache/pkg/dartnative_android
  zenrouter_core:
    path: ../../zenrouter_core
  zenrouter_file_annotation:
    path: ../../zenrouter_file_annotation
  zenrouter_dartnative:
    path: ..
```

The generated routes live in `lib/routes/`; `build.yaml` selects the DartNative
output for both builders. The default `lib/main.dart` remains the hand-written
modular playground described above.
