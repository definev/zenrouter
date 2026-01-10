import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Main App Entry Point
// ============================================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppCoordinator coordinator;

  @override
  void initState() {
    super.initState();
    // Pass the observer to the coordinator via a getter function
    coordinator = AppCoordinator(observers: () => [LoggingNavigatorObserver()]);
  }

  @override
  void dispose() {
    coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Observer Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// ============================================================================
// Custom Navigator Observer
// ============================================================================

/// A custom NavigatorObserver that logs all navigation events.
/// This demonstrates how observers passed to the Coordinator receive
/// navigation callbacks.
class LoggingNavigatorObserver extends NavigatorObserver {
  final List<String> navigationLog = [];

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    navigationLog.add(logEntry);
    developer.log(logEntry, name: 'NavigatorObserver');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(
      'PUSH: ${route.settings.name ?? 'unnamed'} (from: ${previousRoute?.settings.name ?? 'none'})',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(
      'POP: ${route.settings.name ?? 'unnamed'} (back to: ${previousRoute?.settings.name ?? 'none'})',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log('REMOVE: ${route.settings.name ?? 'unnamed'}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log(
      'REPLACE: ${oldRoute?.settings.name ?? 'unnamed'} -> ${newRoute?.settings.name ?? 'unnamed'}',
    );
  }
}

// ============================================================================
// Route Definitions
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      HomeView(coordinator: coordinator);

  @override
  Uri toUri() => Uri.parse('/home');
}

class DetailRoute extends AppRoute {
  DetailRoute({required this.id});

  final String id;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      DetailView(coordinator: coordinator, id: id);

  @override
  Uri toUri() => Uri.parse('/detail/$id');

  @override
  List<Object?> get props => [id];
}

class SettingsRoute extends AppRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      SettingsView(coordinator: coordinator);

  @override
  Uri toUri() => Uri.parse('/settings');
}

// ============================================================================
// Views
// ============================================================================

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.coordinator});

  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Navigation Log',
            onPressed: () => _showNavigationLog(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 24),
            const Text(
              'Observer Example',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Navigation events are being logged by the observer.\n'
                'Check the app logs or tap the history icon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => coordinator.push(DetailRoute(id: '1')),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Go to Detail 1'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => coordinator.push(DetailRoute(id: '2')),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Go to Detail 2'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => coordinator.push(SettingsRoute()),
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNavigationLog(BuildContext context) {
    final observer = coordinator.observers.first as LoggingNavigatorObserver;
    showModalBottomSheet(
      context: context,
      builder: (context) => NavigationLogSheet(log: observer.navigationLog),
    );
  }
}

class DetailView extends StatelessWidget {
  const DetailView({super.key, required this.coordinator, required this.id});

  final AppCoordinator coordinator;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail $id'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, size: 64, color: Colors.deepPurple.shade300),
            const SizedBox(height: 24),
            Text(
              'Detail Page $id',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => coordinator.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                final nextId = int.tryParse(id) ?? 0;
                coordinator.push(DetailRoute(id: '${nextId + 1}'));
              },
              icon: const Icon(Icons.add),
              label: Text('Push Detail ${(int.tryParse(id) ?? 0) + 1}'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.coordinator});

  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Navigation Log',
            onPressed: () => _showNavigationLog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Observers'),
              subtitle: const Text(
                'NavigatorObservers can be passed to the Coordinator '
                'using the CoordinatorNavigatorObserver mixin.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Implementation'),
              subtitle: const Text(
                '1. Mix in CoordinatorNavigatorObserver\n'
                '2. Override the observers getter\n'
                '3. Pass observers via constructor',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => coordinator.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigationLog(BuildContext context) {
    final observer = coordinator.observers.first as LoggingNavigatorObserver;
    showModalBottomSheet(
      context: context,
      builder: (context) => NavigationLogSheet(log: observer.navigationLog),
    );
  }
}

/// Bottom sheet that displays the navigation log
class NavigationLogSheet extends StatelessWidget {
  const NavigationLogSheet({super.key, required this.log});

  final List<String> log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.deepPurple),
              const SizedBox(width: 8),
              const Text(
                'Navigation Log',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${log.length} events',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: log.isEmpty
                ? const Center(
                    child: Text(
                      'No navigation events yet.\nNavigate around to see logs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: log.length,
                    itemBuilder: (context, index) {
                      final entry =
                          log[log.length - 1 - index]; // Reverse order
                      final isRecent = index < 3;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          entry,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isRecent ? Colors.black : Colors.grey,
                            fontWeight: isRecent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Coordinator with Observer Support
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorNavigatorObserver {
  AppCoordinator({
    NavigatorObserverListGetter observers = kEmptyNavigatorObserverList,
  }) : _observersGetter = observers;

  final NavigatorObserverListGetter _observersGetter;

  /// The observers getter is called by the navigator to get the list
  /// of observers. Using a getter function allows for dynamic observer lists.
  ///
  /// CAUTION:
  /// Don't reuse the same observer inside the getter function unless you know
  /// what you are doing.
  ///
  /// Each time the getter is called, it's expected to return a fresh instance
  /// of the observer. And inner `Coordinator` will handle caching of the observers
  /// for you.
  @override
  List<NavigatorObserver> get observers => _observersGetter();

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['home'] => HomeRoute(),
      ['detail', final id] => DetailRoute(id: id),
      ['settings'] => SettingsRoute(),
      _ => HomeRoute(),
    };
  }
}
