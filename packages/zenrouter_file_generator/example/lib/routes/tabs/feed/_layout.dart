import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

part '_layout.g.dart';

@ZenLayout(type: LayoutType.indexed, routes: [FollowingLayout, ForYouLayout])
class FeedTabLayout extends _$FeedTabLayout {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) {
      return Column(
        children: [
          Expanded(child: path.stack[0].build(coordinator, context)),
          Divider(height: 1),
          Expanded(child: path.stack[1].build(coordinator, context)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: path.stack[0].build(coordinator, context)),
        VerticalDivider(width: 1),
        Expanded(child: path.stack[1].build(coordinator, context)),
      ],
    );
  }
}
