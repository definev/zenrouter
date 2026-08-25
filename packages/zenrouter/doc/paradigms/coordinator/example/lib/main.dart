import 'package:flutter/material.dart';
import 'routes/coordinator.dart';

void main() {
  runApp(const MainApp());
}

/// The entrypoint of your app
///
/// It wire up the `Coordinator` inside your `MaterialApp`.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  // We use a singleton access pattern or just a static final for simplicity in this example
  // to avoid recreation. Ideally, use a Provider or InheritedWidget.
  // But strictly following the guide's pattern where it's a field in a StatelessWidget...
  // Since MainApp is const, we can't initialize non-final non-const fields.
  // The guide had: final coordinator = AppCoordinator();
  // We'll stick to making it working.

  static final appCoordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appCoordinator,
      title: 'Coordinator Example',
    );
  }
}
