import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../../routes.zen.dart';

part 'index.g.dart';

/// Profile route at /profile/:id
@ZenRoute()
class ProfileIdRoute extends _$ProfileIdRoute {
  ProfileIdRoute({required super.profileId});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile: $profileId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Text('User ID: $profileId', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () => coordinator.pushCollectionsCollectionId(
                profileId,
                '123',
                {'search': 'test'},
              ),
              child: const Text('Go to Collections'),
            ),
          ],
        ),
      ),
    );
  }
}
