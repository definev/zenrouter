import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part 'profile.g.dart';

/// Profile tab at /tabs/profile
@ZenRoute()
class TabProfileRoute extends _$TabProfileRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          const Text('Profile Tab', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                coordinator.pushProfileId(profileId: 'current-user'),
            child: const Text('View Full Profile'),
          ),
        ],
      ),
    );
  }
}
