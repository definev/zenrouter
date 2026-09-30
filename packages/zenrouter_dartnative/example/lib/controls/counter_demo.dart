// Adapted from DartNative playground/lib/screens/state_basics_demo.dart.
// The signals/effect belong to the mounted demo instead of process globals.
import 'package:dartnative/dartnative.dart';

import '../app_route.dart';
import '../demo_widgets.dart';
import '../gallery/gallery_coordinator.dart';
import '../navigation_demo.dart';
import 'controls_coordinator.dart';

class CounterDemo extends StatefulWidget {
  const CounterDemo({super.key, required this.coordinator});
  final ControlsCoordinator coordinator;

  @override
  State<CounterDemo> createState() => _CounterDemoState();
}

class _CounterDemoState extends State<CounterDemo> {
  final _counter = signal<int>(0);
  late final _label = computed<String>(
    () => switch (_counter.value) {
      0 => 'Press + to start',
      1 => 'Tapped once',
      final n => 'Tapped $n times',
    },
  );
  late final VoidCallback _stopLogging;
  String _lastResult = 'No detail result yet';

  @override
  void initState() {
    super.initState();
    _stopLogging = effect(() => dnLog('[Counter] ${_counter.value}'));
  }

  Future<void> _openDetail() async {
    // The feature coordinator can push directly onto the shared root stack.
    final result = await widget.coordinator.push<String>(
      DetailRoute('counter-${_counter.value}'),
    );
    if (mounted) {
      setState(() => _lastResult = result ?? 'Back without a result');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      DemoCard(
        title: 'A little state',
        children: [
          Text(
            '${_counter.watch(context)}',
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          Text(_label.watch(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: action('−', () => _counter.update((n) => n - 1))),
              const SizedBox(width: 12),
              Expanded(child: action('+', () => _counter.update((n) => n + 1))),
            ],
          ),
          action('Reset counter', () => _counter.value = 0),
          const Text(
            'Switch sections or tabs and come back. Your count stays here.',
          ),
        ],
      ),
      DemoCard(
        title: 'Keep exploring',
        children: [
          Text(_lastResult),
          action('Open detail and return a result', _openDetail),
          action(
            'Go to Gallery / Grid',
            () => moduleOf<GalleryCoordinator>(
              widget.coordinator,
            ).navigate(GridRoute()),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _stopLogging();
    _label.dispose();
    _counter.dispose();
    super.dispose();
  }
}
