import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_dartnative_devtools/zenrouter_dartnative_devtools.dart';

import '../routes.zen.dart';

part '[id].g.dart';

@ZenRoute()
class ItemIdRoute extends _$ItemIdRoute {
  ItemIdRoute({required super.id});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    floatingActionButton: const NativeDevToolsLauncher(),
    appBar: AppBar(title: Text('Item $id')),
    body: Text('URI: ${toUri()}'),
  );
}
