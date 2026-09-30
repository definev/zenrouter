import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';
import 'routes/routes.zen.dart';

/// Alternate entry point demonstrating file-based routing on DartNative.
void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(
    CoordinatorView<AppRoute>(
      coordinator: AppCoordinator(),
      onError: (error, stack) => dnLog('$error\n$stack'),
    ),
  );
}
