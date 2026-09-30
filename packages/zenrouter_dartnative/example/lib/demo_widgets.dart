import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';
import 'package:zenrouter_dartnative_devtools/zenrouter_dartnative_devtools.dart';

import 'app_route.dart';

const paper = Color(0xFFF9F6F0);
const cardColor = Color(0xFFFFFFFF);
const ink = Color(0xFF231F1C);
const muted = Color(0xFF7A7269);
const coffee = Color(0xFF6F4E37);
const roastAmber = Color(0xFFB45309);
const scoreGreen = Color(0xFF2E7D32);

Widget action(
  String label,
  FutureOr<void> Function() callback, {
  bool secondary = false,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Button(
    title: label,
    variant: secondary ? ButtonVariant.bordered : ButtonVariant.filled,
    color: secondary ? muted : coffee,
    onPressed: () async {
      try {
        await callback();
      } catch (error, stack) {
        dnLog('STUDIO ACTION ERROR: $error\n$stack');
      }
    },
  ),
);

class StudioPage extends StatelessWidget {
  const StudioPage({
    super.key,
    required this.title,
    required this.eyebrow,
    required this.children,
  });

  final String title;
  final String eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    brightness: Brightness.light,
    backgroundColor: paper,
    floatingActionButton: const NativeDevToolsLauncher(
      brightness: Brightness.light,
    ),
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            eyebrow.toUpperCase(),
            style: const TextStyle(
              color: roastAmber,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    ),
  );
}

class StudioCard extends StatelessWidget {
  const StudioCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Card(
      color: cardColor,
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: muted, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

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
    builder: (context, layout) => Scaffold(
      backgroundColor: paper,
      body: IndexedStack(index: layout.activeIndex, children: layout.children),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: layout.activeIndex,
        onTap: (index) => unawaited(layout.selectIndex(index)),
        items: const [
          BottomNavigationBarItem(
            label: "Today's Lots",
            icon: Icon(CupertinoIcons.sun_max),
          ),
          BottomNavigationBarItem(
            label: 'Cupping Log',
            icon: Icon(CupertinoIcons.book),
          ),
        ],
      ),
    ),
  );
}
