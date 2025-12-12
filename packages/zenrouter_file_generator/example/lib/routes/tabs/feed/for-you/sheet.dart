import 'dart:async';

import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';
import 'package:flutter/cupertino.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part 'sheet.g.dart';

@ZenRoute(transition: true, deepLink: DeeplinkStrategyType.custom)
class ForYouSheetRoute extends _$ForYouSheetRoute {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return CupertinoPageScaffold(child: Center(child: Text('For You Sheet')));
  }

  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    await coordinator.replaceFollowing();
    coordinator.pushForYou();
    coordinator.push(this);
  }

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    AppCoordinator coordinator,
  ) => StackTransition.sheet(build(coordinator, coordinator.navigator.context));
}
