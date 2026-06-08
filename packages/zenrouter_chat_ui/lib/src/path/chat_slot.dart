import 'package:zenrouter/zenrouter.dart';

/// A [NavigationPath] used as a single independently-swappable UI region
/// (a "slot") in a [ChatShell].
///
/// This is a plain typedef — every [NavigationPath] is already a [ChatSlot].
/// The [ChatSlotOps] extension adds the slot-centric vocabulary on top of the
/// existing push/pop/activateRoute/reset API.
typedef ChatSlot<T extends RouteTarget> = NavigationPath<T>;

/// Slot-centric operations on top of [NavigationPath].
///
/// Each slot in a [ChatShell] independently manages a stack of routes.
/// Three fundamental operations cover all chat-UI transitions:
///
/// | Verb     | Effect                                         | Under the hood       |
/// |----------|------------------------------------------------|----------------------|
/// | `fill`   | Push a route onto the slot's back-stack.       | [NavigationPath.push]|
/// | `swap`   | Replace the slot with a single new route.      | [NavigationPath.activateRoute] (reset + push) |
/// | `clearSlot` | Empty the slot (renders nothing).           | [NavigationPath.reset] |
///
/// `pop()` is inherited directly from [NavigationPath] / [StackMutatable].
extension ChatSlotOps<T extends RouteTarget> on NavigationPath<T> {
  /// Push [route] onto this slot's back-stack.
  ///
  /// Use when you want the user to be able to go **back** to the previous
  /// content (e.g. drilling into a thread from the message list).
  Future<R?> fill<R extends Object>(T route) => push<R>(route);

  /// Replace the slot's entire content with [route] (single-occupant swap).
  ///
  /// Use when the new content is a **peer replacement** with no back navigation
  /// (e.g. switching the composer bar to a recording bar, or changing the top
  /// bar between default ↔ selection-mode ↔ search).
  Future<void> swap(T route) => navigate(route);

  /// Remove all routes from this slot.
  ///
  /// An empty slot renders [SizedBox.shrink] — use this to hide optional
  /// regions such as the pinned-message banner.
  void clearSlot() {
    reset();
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    notifyListeners();
  }
}

/// Restoration IDs for [ChatSlot] navigators inside [ChatShell].
extension ChatSlotRestoration<T extends RouteUnique> on NavigationPath<T> {
  /// Stack-level scope for a slot's [NavigationStack] / Navigator.
  String stackRestorationId(Coordinator<T> coordinator) {
    final label = debugLabel;
    assert(
      label != null,
      'ChatSlot paths must have a debugLabel for restoration',
    );
    return '${coordinator.rootRestorationId}_$label';
  }

  /// Page-level scope for an individual route in a slot stack.
  String routeRestorationId(Coordinator<T> coordinator, RouteUnique route) =>
      '${stackRestorationId(coordinator)}_${route.identifier}';
}
