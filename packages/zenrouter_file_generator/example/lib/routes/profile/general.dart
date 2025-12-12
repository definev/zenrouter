import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_file_generator_example/routes/routes.zen.dart';

part 'general.g.dart';

@ZenRoute(deferredImport: true)
class ProfileGeneralRoute extends _$ProfileGeneralRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Profile General')));
  }
}
