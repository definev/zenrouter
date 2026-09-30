import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part 'feed.g.dart';

@ZenRoute()
class FeedRoute extends _$FeedRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) =>
      const Text('Feed');
}
