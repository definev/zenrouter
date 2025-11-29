import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  runApp(const MainApp());
}

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug<AppRoute> {
  /// HOME Shell
  final NavigationPath<HomeTabShell> home = NavigationPath();

  @override
  late final List<NavigationPath> paths = List.unmodifiable([root, home]);

  @override
  AppRoute parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    /// HOME Shell
    ['idea', final id, 'settings'] => IdeaDetailSettings(id: id),
    ['idea', final id] => IdeaDetail(id: id),
    ['idea'] => IdeaTab(),
    ['note'] => NoteTab(),

    /// ROOT Shell
    ['settings'] => SettingsRoute(),
    [] => NoteTab(),
    _ => NoteTab(),
  };

  @override
  List<AppRoute> get debugRoutes => [
    NoteTab(),
    IdeaTab(),
    SettingsRoute(),
    IdeaDetail(id: '123'),
    IdeaDetailSettings(id: '123', q: 'test'),
  ];

  @override
  String debugLabel(NavigationPath path) {
    if (path == home) return 'Home';
    if (path == root) return 'Root';
    return super.debugLabel(path);
  }
}

final coordinator = AppCoordinator();

sealed class AppRoute extends RouteTarget with RouteUnique {
  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.root;
}

class SettingsRoute extends AppRoute with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings')),
    );
  }
}

/// Home Shell
class _$DefaultHomeTabShell extends HomeTabShell
    with RouteShellHost<HomeTabShell>, RouteBuilder {
  @override
  NavigationPath<HomeTabShell> getPath(AppCoordinator coordinator) =>
      coordinator.home;

  @override
  NavigationPath<AppRoute> getHostPath(AppCoordinator coordinator) =>
      coordinator.root;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final shellPath = getPath(coordinator);

    return ListenableBuilder(
      listenable: shellPath,
      builder: (context, _) {
        final index = switch (shellPath.stack.lastOrNull) {
          IdeaTab() => 0,
          NoteTab() => 1,
          _ => 0,
        };

        return Scaffold(
          body: NavigationStack(
            path: shellPath,
            resolver: (route) => resolver(coordinator, route),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (index) => switch (index) {
              0 => coordinator.replace(IdeaTab()),
              1 => coordinator.replace(NoteTab()),
              2 => coordinator.push(RandomRedirectTab()),
              _ => coordinator.push(IdeaTab()),
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb),
                label: 'Idea',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Note'),
              BottomNavigationBarItem(
                icon: Icon(Icons.refresh),
                label: 'Random',
              ),
            ],
          ),
        );
      },
    );
  }
}

sealed class HomeTabShell extends AppRoute with RouteShell<HomeTabShell> {
  static final host = _$DefaultHomeTabShell();

  @override
  HomeTabShell get shellHost => host;

  @override
  NavigationPath getPath(AppCoordinator coordinator) => coordinator.home;
}

class IdeaTab extends HomeTabShell with RouteBuilder {
  @override
  Uri toUri() => Uri.parse('/idea');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idea Tab')),
      body: ListView.builder(
        itemBuilder: (context, index) => ListTile(
          title: Text('Idea $index'),
          onTap: () => coordinator.push(IdeaDetail(id: index.toString())),
        ),
      ),
    );
  }
}

class NoteTab extends HomeTabShell with RouteBuilder, RouteGuard {
  @override
  Uri toUri() => Uri.parse('/note');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Note Tab')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Note Tab'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.push(SettingsRoute()),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  FutureOr<bool> popGuard() async {
    final context = coordinator.routerDelegate.navigatorKey.currentContext!;

    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to pop this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class IdeaDetail extends HomeTabShell with RouteBuilder, RouteDeepLink {
  IdeaDetail({required this.id});

  @override
  Uri? toUri() => Uri.parse('/idea/$id');

  final String id;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idea Detail')),
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            Text('Idea Detail for $id'),
            ElevatedButton(
              onPressed: () => coordinator.push(IdeaDetailSettings(id: id)),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) {
    coordinator.replace(IdeaTab());
    coordinator.push(IdeaDetail(id: id));
  }
}

class IdeaDetailSettings extends HomeTabShell with RouteBuilder, RouteDeepLink {
  IdeaDetailSettings({required this.id, this.q});

  final String id;

  /// Query parameters
  final String? q;

  @override
  Uri? toUri() => Uri.parse(
    '/idea/$id/settings',
  ).replace(queryParameters: {if (q != null) 'q': q});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idea Detail Settings')),
      body: Center(child: Text('Idea Detail for $id')),
    );
  }

  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) {
    final prevRoute = IdeaDetail(id: id);
    prevRoute.deeplinkHandler(coordinator, uri);
    coordinator.push(IdeaDetailSettings(id: id, q: q));
  }
}

class RandomRedirectTab extends HomeTabShell with RouteRedirect<HomeTabShell> {
  @override
  FutureOr<HomeTabShell> redirect() {
    return NoteTab();
  }
}

/// END Home Shell

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final routerDelegate = CoordinatorRouterDelegate(
    coordinator: coordinator,
  );
  static final routeInformationParser = CoordinatorRouteParser(
    coordinator: coordinator,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: routerDelegate,
      routeInformationParser: routeInformationParser,
    );
  }
}
