import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

/// Mixin that provides a list of observers for the coordinator's navigator.
mixin CoordinatorNavigatorObserver<T extends RouteUnique> on Coordinator<T> {
  /// A list of observers that apply for every [NavigationPath] in the coordinator.
  List<NavigatorObserver> get observers;
}

typedef NavigatorObserverListGetter = List<NavigatorObserver> Function();

List<NavigatorObserver> kEmptyNavigatorObserverList() => [];
