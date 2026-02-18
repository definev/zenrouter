import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: appCoordinator);
  }
}

// ============================================================================
// Coordinator
// ============================================================================

final appCoordinator = AppCoordinator();

class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug {
  late final tabPath = IndexedStackPath.createWith(
    coordinator: this,
    label: 'tabs',
    [HomeTab(), SearchTab(), ProfileTab()],
  );

  @override
  void defineLayout() {
    defineLayoutParent(TabLayout.new);
  }

  @override
  List<StackPath> get paths => [...super.paths, tabPath];

  @override
  List<AppRoute> get debugRoutes => [HomeTab(), SearchTab(), ProfileTab()];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] || ['home'] => HomeTab(),
      ['search'] => SearchTab(),
      ['profile'] => ProfileTab(),
      ['settings'] => SettingsRoute(),
      _ => HomeTab(),
    };
  }
}

// ============================================================================
// Route Base
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Tab Layout
// ============================================================================

class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: ListenableBuilder(
        listenable: path,
        builder: (context, _) => BottomNavigationBar(
          currentIndex: path.activeIndex,
          onTap: (index) => path.goToIndexed(index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Tab Routes
// ============================================================================

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Settings', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class HomeTab extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(child: Text('Home', style: TextStyle(fontSize: 24)));
  }
}

class SearchTab extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/search');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(child: Text('Search', style: TextStyle(fontSize: 24)));
  }
}

class ProfileTab extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/profile');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(child: Text('Profile', style: TextStyle(fontSize: 24)));
  }
}
