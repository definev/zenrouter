import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';
import 'package:zenrouter_dartnative_devtools/zenrouter_dartnative_devtools.dart';

import 'app_route.dart';

const pageBackground = Color(0xFFF3F4F8);
const accent = Color(0xFF4355DB);

Widget action(String label, FutureOr<void> Function() callback) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Button(
    title: label,
    variant: ButtonVariant.filled,
    onPressed: () async {
      try {
        await callback();
      } catch (error, stack) {
        dnLog('ZENROUTER ACTION ERROR: $error\n$stack');
      }
    },
  ),
);

class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    brightness: Brightness.light,
    backgroundColor: pageBackground,
    floatingActionButton: const NativeDevToolsLauncher(
      brightness: Brightness.light,
    ),
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(20), children: children),
  );
}

class DemoCard extends StatelessWidget {
  const DemoCard({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

/// A custom layout renderer shared by feature coordinators. Selection comes
/// exclusively from the path snapshot; this widget has no selected-tab state.
class FeatureTabs extends StatelessWidget {
  const FeatureTabs({
    super.key,
    required this.coordinator,
    required this.path,
    required this.labels,
  });

  final Coordinator<AppRoute> coordinator;
  final IndexedStackPath<AppRoute> path;
  final List<String> labels;

  @override
  Widget build(BuildContext context) => IndexedStackPathBuilder<AppRoute>(
    coordinator: coordinator,
    path: path,
    builder: (context, layout) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Button(
                      title: labels[i],
                      variant: layout.activeIndex == i
                          ? ButtonVariant.filled
                          : ButtonVariant.bordered,
                      onPressed: () => unawaited(layout.selectIndex(i)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: layout.activeIndex,
            children: layout.children,
          ),
        ),
      ],
    ),
  );
}
