// Adapted from DartNative playground/lib/screens/color_picker_demo.dart:
// live color preview and luminance-based text contrast. A routed palette
// replaces the iOS-only system picker so both platforms share result/Back flow.
import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import '../app_route.dart';
import '../demo_widgets.dart';
import 'gallery_coordinator.dart';
import 'grid_demo.dart';

class PaletteDemo extends StatefulWidget {
  const PaletteDemo({super.key, required this.coordinator});
  final GalleryCoordinator coordinator;

  @override
  State<PaletteDemo> createState() => _PaletteDemoState();
}

class _PaletteDemoState extends State<PaletteDemo> {
  Color _color = palette.first;

  Future<void> _pick() async {
    final picked = await widget.coordinator.pickColor(_color.value);
    if (mounted && picked != null) setState(() => _color = Color(picked));
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      ColorPreview(color: _color, label: 'Your palette'),
      const SizedBox(height: 16),
      action('Choose a color', _pick),
      const Text('Preview a color and apply it, or go back to keep this one.'),
      const SizedBox(height: 16),
      action(
        'Open Grid through its URI',
        () => widget.coordinator.navigateUri(Uri.parse('/gallery/grid')),
      ),
    ],
  );
}

class PalettePicker extends StatefulWidget {
  const PalettePicker({
    super.key,
    required this.coordinator,
    required this.initialColor,
  });
  final Coordinator<AppRoute> coordinator;
  final Color initialColor;

  @override
  State<PalettePicker> createState() => _PalettePickerState();
}

class _PalettePickerState extends State<PalettePicker> {
  late Color _color = widget.initialColor;

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Choose a color',
    children: [
      ColorPreview(color: _color, label: 'Live preview'),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final color in palette)
            GestureDetector(
              onTap: () => setState(() => _color = color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    color.value == _color.value ? '✓' : '',
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      action('Use this color', () => widget.coordinator.pop(_color.value)),
      action('Cancel', () => widget.coordinator.pop()),
    ],
  );
}

class ColorPreview extends StatelessWidget {
  const ColorPreview({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final luma =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    final onColor = luma < 0.55
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1C1C1E);
    final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: onColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text('#$hex', style: TextStyle(color: onColor, fontSize: 16)),
        ],
      ),
    );
  }
}
