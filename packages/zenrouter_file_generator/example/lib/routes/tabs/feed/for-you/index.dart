import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part 'index.g.dart';

@ZenRoute()
class ForYouRoute extends _$ForYouRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('For You'),
            ElevatedButton(
              onPressed: () => coordinator.pushForYouSheet(),
              child: Text('Show Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}
