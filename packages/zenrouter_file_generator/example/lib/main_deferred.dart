import 'package:flutter/material.dart';
import 'package:zenrouter_file_generator_example/flutter_scan.dart';
import 'routes/routes.zen.dart' deferred as routes hide AppCoordinatorNav;

void main() {
  runApp(FlutterScan(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: routes.loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox();
        }
        final coordinator = routes.AppCoordinator();
        return MaterialApp.router(
          title: 'ZenRouter File-Based Routing Example',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          routerDelegate: coordinator.routerDelegate,
          routeInformationParser: coordinator.routeInformationParser,
        );
      },
    );
  }
}
