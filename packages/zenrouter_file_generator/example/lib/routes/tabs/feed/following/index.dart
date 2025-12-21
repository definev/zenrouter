import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../../../routes.zen.dart';

part 'index.g.dart';

/// Feed tab at /tabs/feed
@ZenRoute()
class FollowingRoute extends _$FollowingRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Post ${index + 1}'),
            subtitle: const Text('Tap to view details'),
            onTap: () => coordinator.pushFeedPost(postId: 'post-$index'),
          );
        },
      ),
    );
  }
}
