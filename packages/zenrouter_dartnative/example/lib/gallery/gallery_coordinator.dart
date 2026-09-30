import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import '../app_route.dart';
import '../demo_widgets.dart';
import '../playground_layout.dart';
import '../tracing_presentation.dart';
import 'grid_demo.dart';
import 'palette_demo.dart';

class GalleryCoordinator extends Coordinator<AppRoute> {
  GalleryCoordinator(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  late final tabs = IndexedStackPath<AppRoute>.createWith(
    [GridRoute(), PaletteRoute()],
    coordinator: this,
    label: 'gallery-tabs',
  )..bindLayout(GalleryLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, tabs];

  @override
  AppRoute? parseRouteFromUri(Uri uri) {
    switch (uri.pathSegments) {
      case ['gallery'] || ['gallery', 'grid']:
        return GridRoute();
      case ['gallery', 'palette']:
        return PaletteRoute();
      case ['gallery', 'tile', final rawId]:
        final id = int.tryParse(rawId);
        return id != null && id >= 1 && id <= 12 ? TileRoute(id) : null;
      case ['gallery', 'pick']:
        final rawColor = uri.queryParameters['color'];
        if (rawColor == null) return PalettePickerRoute(palette.first.value);
        if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(rawColor)) return null;
        return PalettePickerRoute(int.parse(rawColor, radix: 16));
      default:
        return null; // Allow other modules and the app's not-found route.
    }
  }

  /// A feature-level action, usable by this feature or another module.
  Future<int?> pickColor(int initialColor) =>
      push<int>(PalettePickerRoute(initialColor));
}

class GalleryLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type get layout => PlaygroundLayout;

  @override
  IndexedStackPath<AppRoute> resolvePath(Coordinator<AppRoute> coordinator) =>
      moduleOf<GalleryCoordinator>(coordinator).tabs;

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      FeatureTabs(
        coordinator: moduleOf<GalleryCoordinator>(coordinator),
        path: resolvePath(coordinator),
        labels: const ['Grid', 'Palette'],
      );
}

class GridRoute extends AppRoute {
  @override
  Type get layout => GalleryLayout;

  @override
  Uri toUri() => Uri(path: '/gallery/grid');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      GridDemo(coordinator: moduleOf<GalleryCoordinator>(coordinator));
}

class PaletteRoute extends AppRoute {
  @override
  Type get layout => GalleryLayout;

  @override
  Uri toUri() => Uri(path: '/gallery/palette');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      PaletteDemo(coordinator: moduleOf<GalleryCoordinator>(coordinator));
}

/// No parent layout: this detail is presented over the whole playground.
class TileRoute extends AppRoute {
  TileRoute(this.id);
  final int id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri(path: '/gallery/tile/$id');

  @override
  Presentation get presentation =>
      const TracingPresentation(ScreenPresentation());

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      DemoPage(
        title: 'Tile $id',
        children: [
          ColorPreview(
            color: palette[(id - 1) % palette.length],
            label: 'Tile $id',
          ),
          const SizedBox(height: 16),
          action('Choose this tile', () => coordinator.pop(id)),
          action('Back to gallery', () => coordinator.pop()),
        ],
      );
}

class PalettePickerRoute extends AppRoute {
  PalettePickerRoute(this.initialColor);
  final int initialColor;

  @override
  List<Object?> get props => [initialColor];

  @override
  Uri toUri() => Uri(
    path: '/gallery/pick',
    queryParameters: {'color': initialColor.toRadixString(16).padLeft(8, '0')},
  );

  @override
  Presentation get presentation =>
      const TracingPresentation(ScreenPresentation());

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      PalettePicker(
        coordinator: coordinator,
        initialColor: Color(initialColor),
      );
}
