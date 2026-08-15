import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

part '_layout.g.dart';

@ZenLayout(type: LayoutType.branched, branches: [FollowingLayout, ForYouLayout])
class FeedTabLayout extends _$FeedTabLayout {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    return Column(
      children: [
        ListenableBuilder(
          listenable: path,
          builder: (context, _) => SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Following')),
              ButtonSegment(value: 1, label: Text('For you')),
            ],
            selected: {path.activeBranchIndex},
            onSelectionChanged: (selection) =>
                path.goToBranch(selection.single),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: buildPath(coordinator)),
      ],
    );
  }
}
