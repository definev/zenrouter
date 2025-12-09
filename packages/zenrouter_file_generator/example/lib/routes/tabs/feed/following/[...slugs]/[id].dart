import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

part '[id].g.dart';

@ZenRoute()
class FeedDynamicIdRoute extends _$FeedDynamicIdRoute {
  FeedDynamicIdRoute({required super.slugs, required super.id});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed Dynamic Id')),
      body: Center(child: Text('Feed Dynamic Id: ${slugs.join('/')}')),
    );
  }
}
