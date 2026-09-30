// Adapted from DartNative playground/lib/screens/grid_demo.dart:
// the local GridView.count / GridView.builder examples and tile palette.
import 'package:dartnative/dartnative.dart';

import '../demo_widgets.dart';
import 'gallery_coordinator.dart';

const palette = [
  Color(0xFFE74C3C),
  Color(0xFF3498DB),
  Color(0xFF2ECC71),
  Color(0xFFF39C12),
  Color(0xFF9B59B6),
  Color(0xFF1ABC9C),
  Color(0xFFE67E22),
  Color(0xFF2980B9),
  Color(0xFF27AE60),
];

class GridDemo extends StatefulWidget {
  const GridDemo({super.key, required this.coordinator});
  final GalleryCoordinator coordinator;

  @override
  State<GridDemo> createState() => _GridDemoState();
}

class _GridDemoState extends State<GridDemo> {
  int? _selectedTile;

  Future<void> _open(int id) async {
    final result = await widget.coordinator.push<int>(TileRoute(id));
    if (mounted && result != null) setState(() => _selectedTile = result);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      DemoCard(
        title: 'A pocket gallery',
        children: [
          const Text(
            'Tap a tile to open it. Choose it, then return to this grid.',
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTile == null
                ? 'No tile chosen yet'
                : 'Chosen tile: $_selectedTile',
          ),
        ],
      ),
      const Text('Square tiles · 3 columns'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (var i = 1; i <= 9; i++) _tile(i)],
      ),
      const SizedBox(height: 24),
      const Text('Wide tiles · 2 columns'),
      const SizedBox(height: 12),
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 16 / 9,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        itemBuilder: (context, index) => _tile(index + 1),
      ),
      const SizedBox(height: 24),
    ],
  );

  Widget _tile(int id) => GestureDetector(
    onTap: () => _open(id),
    child: Container(
      decoration: BoxDecoration(
        color: palette[(id - 1) % palette.length],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _selectedTile == id ? '✓ $id' : '$id',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
