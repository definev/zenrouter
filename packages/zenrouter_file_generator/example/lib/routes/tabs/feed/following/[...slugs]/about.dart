import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

part 'about.g.dart';

@ZenRoute()
class FeedDynamicAboutRoute extends _$FeedDynamicAboutRoute {
  FeedDynamicAboutRoute({required super.slugs});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed Dynamic About')),
      body: Center(child: Text('Feed Dynamic About: ${slugs.join('/')}')),
    );
  }
}
