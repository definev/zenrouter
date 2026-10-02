## 0.1.1

Maintenance release with native dialog presentation enhancements, updated documentation, and an overhauled showcase example.

### Presentation adapters

- Add optional `ios` configuration (`DialogIOSConfig?`) to `ExperimentalDialogPresentation`, forwarding native iOS dialog properties directly to DartNative's `Dialog`.

### Maintenance and tooling

- Suppress internal and protected member analyzer warnings in native coordinator and path lifecycle hooks.
- Clarify package documentation and update installation instructions for published releases.
- Exclude build and distribution artifacts (`dist/`) in `.gitignore` and `.pubignore`.

### Example app (Cupping Studio)

- Completely overhaul the example into an interactive coffee tasting studio demonstrating real-world navigation patterns.
- Implement persistent indexed tab layouts with shelf and logbook views.
- Add dynamic parameterized lot routes (`/lot/:id`) returning cupping score results back to the shelf.
- Support both modal dialog routes via `ExperimentalDialogPresentation` and native `showAlert` confirmation on guarded Back navigation.
- Add native modal bottom sheets for brew guides and a dedicated `BaristaCoordinator` route module.
- Adapt UI styling for both Android Material 3 and iOS Cupertino native chrome, ensuring reliable touch handling for cards and action buttons.

## 0.1.0

Initial DartNative navigation and layout adapter for `zenrouter_core` 3.0.0.

### Navigation and layout

- `Coordinator<T>` and `CoordinatorView<T>` drive one persistent native root
  and an ordered stack of managed route presentations.
- Native `RouteUnique` routes build DartNative widgets and expose their URI,
  parent layout, and presentation. `CoordinatorScope` is installed on every
  presented screen, including screens outside the root widget ancestry.
- Support `push<R>`, `pop(result)`, `pushSilently`, `pushReplacement`, `replace`,
  `navigate`, redirects, and URI actions supplied by core.
- Distinguish route identity from value equality: equal routes and repeated
  URIs can coexist as separate entries with independent lifecycle/results.
  New entries require fresh route instances; removed result completers cannot
  be reused.
- Add native `NavigationPath`, `IndexedStackPath`, and `BranchedStackPath`
  implementations, plus `RouteLayout` and `IndexedStackPathBuilder` for
  persistent indexed/branched logical layouts.
- Bind layout constructors on paths and select indexed entries through the
  coordinator so hierarchy activation, URI changes, guards, and commits agree.
- Support `CoordinatorModular` feature coordinators as route modules sharing
  the parent's root presentation stack and navigation transactions.
- Expose `zenrouter_dartnative_core.dart` for headless coordinator/path use on
  the Dart VM without loading native widget bindings.

### Presentation adapters

- `ScreenPresentation` pushes native screens, with configurable transition,
  duration, and zoom source; the default is `slideFromRight` with 350ms duration.
- Open `Presentation` interface supports app/plugin-defined containers through
  `PresentationContext`, `PresentationHandle`, and `PresentationHandleAdapter`.
  Entry tokens keep removal acknowledgements attributable to the right route.
- `canMountAsRoot` declares whether a presentation has an inline persistent-root
  form. Non-root presentations are rejected before initial/root replacement
  mutates state.
- Add explicitly experimental detent sheet, content-sized bottom sheet,
  centered dialog, and iOS keyboard overlay presentation helpers.
- `CoordinatorView.presentationBuilder` wraps every presentation, allowing
  shared application decoration and native DevTools integration.

### Guards, results, and synchronization

- Bridge core `RouteGuard`, asynchronous pop decisions, and reactive
  `canPopListenable` into native Back handling; convert DartNative notifiers
  through `toListenableMixin()`.
- Never pop the sole root route. Android root Back can call `onExitRequested`
  after guard approval, defaulting to `SystemNavigator.pop`.
- Complete push results once when the entry is removed. `pushSilently` waits
  for logical commitment rather than the route's later pop result.
- Snapshot paths at navigation commits, serialize native presentation commands,
  coalesce bursts, and suppress late or duplicate dismissal acknowledgements.
- Merge presentation-result futures, `PopScope` notifications, and subtree
  disposal into removal acknowledgements scoped by entry identity.
- Drain native screen suffixes before swapping root content; apply top
  replacement as pop followed by push while core emits one logical commit.
- Require `onError` on the host; synchronization stops on native command failure
  or confirmation timeout. Already-completed core results are not rolled back.
- Stop issuing commands after host detachment and ignore late callbacks from
  disposed presentations. A thrown guard leaves subsequent Back requests usable.

### File-based routing and examples

- Integrate with `zenrouter_file_generator: ^3.0.0` using
  `platform: dartnative` on both builders.
- Include handwritten modular and generated examples covering route parameters,
  not-found routes, results, guarded Back, native presentations, indexed layouts,
  and native DevTools.

### Limits in 0.1.0

- No state restoration, native hot-restart replay adoption, or independent
  physical native Navigator stacks per branch. Logical branch histories are
  supported; detail screens use the shared native presentation stack.
- Moving an existing non-top route through `pushOrMoveToTop` is unsupported;
  use `navigate` to return to an existing destination.
- Mount acknowledgement does not indicate transition completion. The adapter
  does not promise exact native animation sequencing or predictive Back parity.
- Experimental sheet/dialog helpers cannot reliably observe every external
  scrim/grabber/swipe dismissal in the inspected SDK. Use coordinator-driven
  dismissal or a custom adapter with a reliable native removal callback.
- A dismissal that has already occurred cannot be retroactively blocked by a
  route guard; interactive adapters must consult guards before dismissal.
- Include custom paths in `coordinator.paths`; direct mutation or casting of
  exposed paths bypasses the managed navigation contract.
- The host exclusively owns its presentations; raw Navigator mutations,
  unmanaged overlays, nested hosts, and adoption after remount are unsupported.
  The application owns coordinator disposal and must dispose the host first.
- `recoverUri` resolves routing state; it does not register an OS incoming-link
  listener. Native synchronization failure requires a cold restart.

### Requirements and verification

- Dart 3.9 or newer; DartNative SDK/framework 1.0.0;
  `zenrouter_core: ^3.0.0`.
- Resolve SDK packages with `dn pub get`. Local development overrides are
  excluded from release archives; public publication still requires a supported
  framework dependency/registry arrangement.
- See [VERIFICATION.md](VERIFICATION.md) for dated automated and native-device
  evidence, including Android and gesture acceptance checks still outstanding.
