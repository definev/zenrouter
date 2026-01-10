import 'package:flutter/foundation.dart';
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
    return MaterialApp.router(
      routerConfig: appCoordinator,
      // routerDelegate: appCoordinator.routerDelegate,
      // routeInformationParser: appCoordinator.routeInformationParser,
    );
  }
}

// Observers

class DebugNavigationObserver extends NavigatorObserver {
  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
    _log(
      'didChangeTop',
      previousRoute: previousTopRoute,
      incomingRoute: topRoute,
    );
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _log('didPop', previousRoute: previousRoute, incomingRoute: route);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _log('didPush', previousRoute: previousRoute, incomingRoute: route);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _log('didRemove', previousRoute: previousRoute, incomingRoute: route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _log('didReplace', previousRoute: oldRoute, incomingRoute: newRoute);
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    _log(
      'didStartUserGesture',
      previousRoute: previousRoute,
      incomingRoute: route,
    );
  }

  @override
  void didStopUserGesture() {}

  void _log(
    String action, {
    required Route? previousRoute,
    required Route? incomingRoute,
  }) {
    if (kDebugMode) {
      print(
        'Action: $action, Previous: ${previousRoute?.settings.name}, Incoming: ${incomingRoute?.settings.name}',
      );
    }
  }
}

// ============================================================================
// Coordinator
// ============================================================================

final appCoordinator = AppCoordinator();

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug, CoordinatorNavigatorObserver {
  late final tabPath = IndexedStackPath.createWith(
    coordinator: this,
    label: 'tabs',
    [HomeTab(), SearchLayout(), ProfileTab()],
  )..bindLayout(TabLayout.new);
  late final searchPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'search',
  )..bindLayout(SearchLayout.new);

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
      ['p', 'profile'] => ProfileRoute(),
      _ => HomeTab(),
    };
  }

  @override
  List<NavigatorObserver> get observers => [DebugNavigationObserver()];
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
          onTap: (index) async {
            path.goToIndexed(index);
            if (index == 1) {
              if (coordinator.searchPath.stack.isEmpty) {
                coordinator.push(SearchTab());
              }
            }
          },
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

class ProfileRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/p/profile');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text('Profile', style: TextStyle(fontSize: 24)),
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
    return Center(
      child: GestureDetector(
        onTap: () => coordinator.push(ProfileRoute()),
        child: Text('Home', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class SearchLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type? get layout => TabLayout;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.searchPath;
}

class SearchTab extends AppRoute {
  @override
  Type get layout => SearchLayout;

  @override
  Uri toUri() => Uri.parse('/search');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Search', style: TextStyle(fontSize: 24)),
          ElevatedButton(
            onPressed: () => coordinator.push(SearchResult()),
            child: const Text('Result'),
          ),
        ],
      ),
    );
  }
}

class SearchResult extends AppRoute {
  @override
  Type? get layout => SearchLayout;

  @override
  Uri toUri() => Uri.parse('/search/result');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const Center(
      child: Text('Search Result', style: TextStyle(fontSize: 24)),
    );
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
