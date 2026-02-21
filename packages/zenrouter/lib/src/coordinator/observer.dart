import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

/// Mixin that provides a list of observers for the coordinator's navigator.
///
/// ## Role in Navigation Flow
///
/// [CoordinatorNavigatorObserver] enables observability of navigation events:
/// 1. Observers are attached to each [NavigationStack] in the coordinator
/// 2. Flutter's Navigator notifies observers of route changes
/// 3. Useful for analytics, logging, or custom behavior on navigation events
///
/// Common observers include:
/// - [NavigatorObserver] - Base class for navigation observation
/// - [RouteObserver] - Notifies when routes are pushed/popped
mixin CoordinatorNavigatorObserver<T extends RouteUnique> on Coordinator<T> {
  /// A list of observers that apply for every [NavigationPath] in the coordinator.
  List<NavigatorObserver> get observers;
}

typedef NavigatorObserverListGetter = List<NavigatorObserver> Function();

List<NavigatorObserver> kEmptyNavigatorObserverList() => [];
