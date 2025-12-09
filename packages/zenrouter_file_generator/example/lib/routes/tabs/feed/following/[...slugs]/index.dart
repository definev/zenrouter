import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

part 'index.g.dart';

@ZenRoute()
class FeedDynamicRoute extends _$FeedDynamicRoute {
  FeedDynamicRoute({required super.slugs});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed Dynamic')),
      body: Center(child: Text('Feed Dynamic: ${slugs.join('/')}')),
    );
  }
}
