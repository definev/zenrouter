/// File-Based Routing Example for ZenRouter
///
/// This example demonstrates a file-system-based routing convention
/// for the Coordinator paradigm, similar to Next.js or SvelteKit.
///
/// File naming convention:
/// - `index.dart` - Route at the directory path
/// - `:parameter.dart` - Route with path parameter
/// - `+layout.dart` - Layout layout for the directory
///
/// Directory structure = URL structure:
/// ```
/// routes/
/// ├── home/
/// │   ├── +layout.dart          → Layout for /home/*
/// │   └── index.dart            → /home
/// ├── products/
/// │   ├── +layout.dart          → Layout for /products/*
/// │   ├── index.dart            → /products
/// │   └── :id.dart              → /products/:id
/// └── settings/
///     ├── +layout.dart          → Layout for /settings/*
///     ├── index.dart            → /settings
///     ├── account.dart          → /settings/account
///     └── privacy.dart          → /settings/privacy
/// ```
///
/// Run this example:
/// ```bash
/// flutter run -t lib/file_based_routing/main.dart
/// ```
library;

import 'package:flutter/material.dart';
import 'coordinator.dart';

void main() {
  runApp(const FileBasedRoutingApp());
}

class FileBasedRoutingApp extends StatelessWidget {
  const FileBasedRoutingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final coordinator = AppCoordinator();

    return MaterialApp.router(
      title: 'ZenRouter File-Based Routing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}
