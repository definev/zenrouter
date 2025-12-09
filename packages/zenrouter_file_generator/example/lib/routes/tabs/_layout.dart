import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part '_layout.g.dart';

/// Tab layout at /tabs
///
/// The annotation only specifies which routes belong to this layout.
/// All UI decisions are left to you in the build() method.
@ZenLayout(
  type: LayoutType.indexed,
  routes: [FeedTabLayout, TabProfileRoute, TabSettingsRoute],
)
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return Scaffold(
      body: RouteLayout.buildPrimitivePath(
        IndexedStackPath,
        coordinator,
        path,
        this,
      ),
      // User has full control over the navigation UI
      bottomNavigationBar: NavigationBar(
        selectedIndex: path.activeIndex,
        onDestinationSelected: (index) => coordinator.push(path.stack[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
