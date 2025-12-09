import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../../../routes.zen.dart';

part '[postId].g.dart';

/// Feed post detail at /tabs/feed/:postId
@ZenRoute(guard: true)
class FeedPostRoute extends _$FeedPostRoute {
  FeedPostRoute({required super.postId});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post: $postId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Post ID: $postId', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<bool> popGuard() async {
    // Example: Always allow pop for this demo
    return true;
  }
}
