import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';
import 'package:zenrouter_dartnative_devtools/zenrouter_dartnative_devtools.dart';

import 'app_coordinator.dart';
import 'app_route.dart';
import 'dartnative_plugin_registrant.dart';

Future<void> main() async {
  DartNativePluginRegistrant.registerAll();
  final coordinator = AppCoordinator();
  // Resolve the initial layout hierarchy before mounting the single host.
  const initialUri = String.fromEnvironment(
    'INITIAL_URI',
    defaultValue: '/controls/counter',
  );
  await coordinator.recoverUri(Uri.parse(initialUri));
  final devTools = NativeDevToolsController();
  runApp(
    CoordinatorView<AppRoute>(
      coordinator: coordinator,
      onError: (error, stack) => dnLog('ZENROUTER ERROR: $error\n$stack'),
      presentationBuilder: (context, child) {
        if (const bool.fromEnvironment('dart.vm.product')) return child;
        return NativeDevTools<AppRoute>(
          coordinator: coordinator,
          controller: devTools,
          debugRoutes: [
            Uri.parse('/'),
            Uri.parse('/controls/counter'),
            Uri.parse('/tabs/profile'),
          ],
          child: child,
        );
      },
    ),
  );
}
