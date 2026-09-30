import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';
import 'package:zenrouter_dartnative_devtools/zenrouter_dartnative_devtools.dart';

import 'app_coordinator.dart';
import 'app_route.dart';
import 'demo_widgets.dart';
import 'navigation_demo.dart';

class PlaygroundLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  BranchedStackPath<AppRoute> resolvePath(Coordinator<AppRoute> coordinator) =>
      moduleOf<AppCoordinator>(coordinator).sections;

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      IndexedStackPathBuilder<AppRoute>(
        coordinator: coordinator,
        path: resolvePath(coordinator),
        builder: (context, layout) => Scaffold(
          brightness: Brightness.light,
          backgroundColor: pageBackground,
          floatingActionButton: const NativeDevToolsLauncher(
            brightness: Brightness.light,
          ),
          appBar: AppBar(
            title: Text(layout.activeIndex == 0 ? 'Controls' : 'Gallery'),
            actions: [
              Button(
                child: Icon(CupertinoIcons.plus),
                automaticTint: true,
                height: 44,
                width: 44,
                variant: ButtonVariant.clearGlass,
                onPressed: () =>
                    unawaited(coordinator.pushSilently(HomeRoute())),
              ),
            ],
          ),
          body: Column(
            children: [
              _CurrentLocation(coordinator: coordinator),
              Expanded(
                child: IndexedStack(
                  index: layout.activeIndex,
                  children: layout.children,
                ),
              ),
            ],
          ),
          extendBody: false,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: layout.activeIndex,
            onTap: (index) => unawaited(layout.selectIndex(index)),
            items: const [
              BottomNavigationBarItem(
                label: 'Controls',
                icon: Icon(CupertinoIcons.slider_horizontal_3),
              ),
              BottomNavigationBarItem(
                label: 'Gallery',
                icon: Icon(CupertinoIcons.square_grid_2x2),
              ),
            ],
          ),
        ),
      );
}

/// Shows the committed URI when either level of the layout changes.
class _CurrentLocation extends StatefulWidget {
  const _CurrentLocation({required this.coordinator});
  final Coordinator<AppRoute> coordinator;

  @override
  State<_CurrentLocation> createState() => _CurrentLocationState();
}

class _CurrentLocationState extends State<_CurrentLocation> {
  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      '${widget.coordinator.currentUri}',
      style: const TextStyle(fontSize: 13, color: Color(0xFF666A7A)),
    ),
  );

  @override
  void dispose() {
    widget.coordinator.removeListener(_changed);
    super.dispose();
  }
}
