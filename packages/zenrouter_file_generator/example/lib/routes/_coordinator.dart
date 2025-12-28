import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

@ZenCoordinator(
  name: 'AppCoordinator',
  routeBase: 'AppRoute',
  routeBasePath: '_route.dart',
  deferredImport: true,
)
class CoordinatorConfig {}
