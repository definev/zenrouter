import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part 'profile.g.dart';

@ZenRoute()
class ProfileRoute extends _$ProfileRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) =>
      const Text('Cupping logbook');
}
