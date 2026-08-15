import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final coordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter File-Based Routing Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: coordinator,
    );
  }
}
