# Cupping studio

A small coffee lab that shows what `zenrouter_dartnative` is for: one persistent
shelf, pushed tastings that return a score, a guarded cupping form, a native
brew sheet, and a barista module that owns its own route.

## The story

The studio keeps two tabs. **Shelf** lists today's lots. Opening Yirgacheffe
pushes `/lot/yirga`; committing its cupping score pops that score back onto the
shelf. **Logbook** keeps its place while those screens are open. **Barista** is
resolved by a child coordinator, and **Brew guide** uses a native sheet instead
of another full screen.

| Destination | URI | What it shows |
| --- | --- | --- |
| Shelf | `/shelf` | Indexed tab. Push a lot and await its score. |
| Logbook | `/logbook` | Indexed tab retained while detail screens are open. |
| Lot | `/lot/:id` | Dynamic route with its own lifecycle and result. |
| Cupping | `/cupping?lot=:id` | Guard blocks Back until the score is committed. |
| Brew guide | `/brew?lot=:id` | Native modal sheet presentation. |
| Barista | `/barista` | Route module parsed by `BaristaCoordinator`. |

## Project structure

```text
lib/
├── main.dart             # CoordinatorView and native DevTools
├── app_coordinator.dart  # Studio tabs, URI parsing, barista module
├── app_route.dart        # Lots, cupping form, brew sheet, logbook
├── demo_widgets.dart     # Shared studio page, card, and tab chrome
├── main_file_router.dart # Generated file-routing entry point
└── routes/               # File-based shelf, logbook, and lot routes
```

## Run

From this directory:

```sh
dn create --platforms=ios,android --project-name=zenrouter_dartnative_example --org=dev.zenrouter --no-pub .
dn pub get
dn run
```

Platform scaffolding is generated locally and is not part of the package.

## File-based routing

The same studio can be entered through generated routes:

```sh
dart run build_runner build
dn run --target lib/main_file_router.dart
```

`lib/routes/` contains the shelf, the logbook tab, and `/lot/:id`. The
hand-written `lib/main.dart` remains the full studio, including the guarded
cupping form and brew sheet.
