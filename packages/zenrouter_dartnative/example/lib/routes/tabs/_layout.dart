import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part '_layout.g.dart';

@ZenLayout(type: LayoutType.indexed, routes: [FeedRoute, ProfileRoute])
class TabsLayout extends _$TabsLayout {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) =>
      IndexedStackPathBuilder<AppRoute>(
        coordinator: coordinator,
        path: resolvePath(coordinator),
        builder: (_, layout) =>
            IndexedStack(index: layout.activeIndex, children: layout.children),
      );
}
