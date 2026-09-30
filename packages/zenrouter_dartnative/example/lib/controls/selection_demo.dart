// Adapted from DartNative playground/lib/screens/radio_check_demo.dart.
import 'package:dartnative/dartnative.dart';

import '../demo_widgets.dart';

class SelectionDemo extends StatefulWidget {
  const SelectionDemo({super.key});

  @override
  State<SelectionDemo> createState() => _SelectionDemoState();
}

class _SelectionDemoState extends State<SelectionDemo> {
  bool? _notifications = true;
  bool? _newsletter = false;
  String _density = 'comfortable';

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      DemoCard(
        title: 'Make it yours',
        children: [
          _checkbox(
            'Notifications',
            _notifications,
            (value) => setState(() => _notifications = value),
          ),
          _checkbox(
            'Weekly newsletter',
            _newsletter,
            (value) => setState(() => _newsletter = value),
          ),
        ],
      ),
      DemoCard(
        title: 'Reading density',
        children: [
          for (final value in ['comfortable', 'compact'])
            Row(
              children: [
                Radio<String>(
                  value: value,
                  groupValue: _density,
                  activeColor: accent,
                  onChanged: (value) => setState(() => _density = value!),
                ),
                const SizedBox(width: 12),
                Text(value == 'comfortable' ? 'Comfortable' : 'Compact'),
              ],
            ),
          const SizedBox(height: 12),
          Text('Selected: $_density'),
        ],
      ),
      const Text(
        'Your choices stay selected while you explore the other tabs.',
      ),
    ],
  );

  Widget _checkbox(String label, bool? value, ValueChanged<bool?> onChanged) =>
      Row(
        children: [
          Checkbox(value: value, onChanged: onChanged, activeColor: accent),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      );
}
