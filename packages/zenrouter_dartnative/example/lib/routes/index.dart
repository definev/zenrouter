import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_dartnative_devtools/zenrouter_dartnative_devtools.dart';

import 'routes.zen.dart';

part 'index.g.dart';

@ZenRoute()
class IndexRoute extends _$IndexRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => Scaffold(
    floatingActionButton: const NativeDevToolsLauncher(),
    appBar: AppBar(title: const Text('File routing')),
    body: Column(
      children: [
        Button(
          title: 'Open item 42',
          onPressed: () => coordinator.pushItemId(id: '42'),
        ),
        Button(
          title: 'Open profile tab',
          onPressed: coordinator.recoverProfile,
        ),
      ],
    ),
  );
}
