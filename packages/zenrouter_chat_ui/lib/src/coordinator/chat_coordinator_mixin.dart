import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/zenrouter_chat_ui.dart';

/// Mixin that equips any [Coordinator] with the four standard chat-UI slots.
///
/// Mix this into your [Coordinator] subclass and you instantly get four
/// independently-swappable [ChatSlot]s:
///
/// | Slot          | Purpose                                             |
/// |---------------|-----------------------------------------------------|
/// | [topBarSlot]  | Channel header, selection header, search field, … |
/// | [pinnedSlot]  | Optional pinned-message banner (empty = hidden).   |
/// | [bodySlot]    | Scrollable message list, thread view, search results. |
/// | [bottomSlot]  | Composer, action bar, recording bar, …              |
///
/// ```dart
/// class MyChatCoordinator extends Coordinator<MyChatRoute>
///     with ChatCoordinatorMixin<MyChatRoute> {
///   final listController = ChatListController<ChatMessage>();
///
///   @override
///   MyChatRoute parseRouteFromUri(Uri uri) => ChatScreenRoute();
///
///   @override
///   void dispose() {
///     listController.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// Then seed the slots once (e.g. in the coordinator's constructor or in a
/// one-time init method called from [ChatShell]):
///
/// ```dart
/// void seedDefaultSlots() {
///   topBarSlot.swap(DefaultTopBar());
///   bottomSlot.swap(ComposerBar());
///   bodySlot.swap(MessageListBody());
///   // pinnedSlot intentionally left empty
/// }
/// ```
///
/// Use [fill] / [swap] / [clearSlot] (from [ChatSlotOps]) on any slot to
/// drive navigation independently of the others.
mixin ChatCoordinatorMixin<T extends RouteUnique> on Coordinator<T> {
  late final topBarSlot = NavigationPath<T>.createWith(
    coordinator: this,
    label: 'slot.topbar',
  );

  late final pinnedSlot = NavigationPath<T>.createWith(
    coordinator: this,
    label: 'slot.pinned',
  );

  late final bodySlot = NavigationPath<T>.createWith(
    coordinator: this,
    label: 'slot.body',
  );

  late final bottomSlot = NavigationPath<T>.createWith(
    coordinator: this,
    label: 'slot.bottom',
  );

  @override
  List<StackPath> get paths => [
    ...super.paths,
    topBarSlot,
    pinnedSlot,
    bodySlot,
    bottomSlot,
  ];
}

// ============================================================================
// Standardized ChatShell integration
// ============================================================================
//
// [ChatCoordinatorMixin] is the quickest way to add the four slots to a single
// coordinator. For larger apps you usually want the chat screen to be just one
// destination among many, reachable through the normal
// `parseRouteFromUri` -> route -> layout flow.
//
// These primitives let you wire the shell into an *outer* [Coordinator] without
// returning a [ChatShell] widget from a route's `build`:
//
// | Type                   | Role                                                   |
// |------------------------|--------------------------------------------------------|
// | [ChatShellCoordinator] | Dedicated sub-coordinator that owns the four slots.    |
// | [ChatShellRoute]       | Route whose `handler` seeds / drives the shell slots.  |
// | [ChatShellRouteLayout] | The [RouteLayout] that renders the [ChatShell].        |
// | [ChatShellPath]        | The [StackPath] the layout resolves to.                |
//
// Wiring (inside your root coordinator):
//
// ```dart
// class AppCoordinator extends Coordinator<AppRoute> {
//   final chatShellPath = ChatShellPath<AppRoute>(shell: AppChatShell());
//
//   @override
//   void defineLayout() {
//     super.defineLayout();
//     defineLayoutParent(ChatLayout.new);  // register the layout constructor
//     ChatShellPath.defineBuilder(this);   // teach the coordinator to build it
//   }
//
//   @override
//   void dispose() {
//     chatShellPath.dispose();
//     super.dispose();
//   }
//
//   @override
//   FutureOr<AppRoute> parseRouteFromUri(Uri uri) => ChatScreenRoute();
// }
// ```

/// A route that *enters* the chat shell and drives its slots, instead of
/// building a widget of its own.
///
/// When the route is activated, [navigate] is invoked with the owning
/// [ChatShellCoordinator] so it can seed (or reconfigure) the four slots:
///
/// ```dart
/// class ChatScreenRoute extends AppRoute with ChatShellRoute<AppRoute> {
///   @override
///   Object get parentLayoutKey => ChatLayout.key;
///
///   @override
///   Uri toUri() => Uri.parse('/chat');
///
///   @override
///   void handler(AppChatShell coordinator) {
///     coordinator.topBarSlot.swap(DefaultTopBar());
///     coordinator.bodySlot.swap(MessageListBody());
///     coordinator.bottomSlot.swap(ComposerBar());
///   }
/// }
/// ```
mixin ChatShellRoute<T extends RouteUnique> on RouteUnique {
  /// Called when this route is activated.
  ///
  /// Use the [coordinator]'s slots ([ChatShellCoordinator.topBarSlot],
  /// [ChatShellCoordinator.bodySlot], …) to drive the shell.
  FutureOr<void> navigate(covariant ChatShellCoordinator<T> coordinator) {}

  FutureOr<void> push(covariant ChatShellCoordinator<T> coordinator) =>
      navigate(coordinator);

  FutureOr<void> pop(covariant ChatShellCoordinator<T> coordinator) {}

  @override
  Object get parentLayoutKey;

  /// A [ChatShellRoute] never renders directly — the [ChatShellRouteLayout]
  /// renders the [ChatShell]. This is intentionally a no-op.
  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();
}

/// The [RouteLayout] that renders a [ChatShell] for a [ChatShellCoordinator].
///
/// Implement [resolvePath] to return the [ChatShellPath] held by your root
/// coordinator.
mixin ChatShellRouteLayout<T extends RouteUnique> on RouteLayout<T> {
  @override
  ChatShellPath<T> resolvePath(covariant CoordinatorCore coordinator);
}

/// The [StackPath] a [ChatShellRouteLayout] resolves to.
///
/// It does not hold a real navigation stack. Its only responsibilities are to
/// (1) own the [ChatShellCoordinator] that backs the shell and (2) forward
/// route activation to [ChatShellRoute.navigate].
///
/// Register its builder once via [defineBuilder] so the coordinator knows to
/// render a [ChatShell] for this path.
class ChatShellPath<T extends RouteUnique> extends StackPath<T>
    with ChangeNotifier, StackNavigatable<T>, StackMutatable<T> {
  ChatShellPath({required this.shell}) : super([]);

  static const key = PathKey('ChatShellPath');

  /// Registers the layout builder that renders a [ChatShell] for any
  /// [ChatShellPath]. Call once from your coordinator's
  /// [Coordinator.defineLayout].
  static void defineBuilder(Coordinator coordinator) =>
      coordinator.defineLayoutBuilder(
        key,
        (coordinator, path, layout) =>
            ChatShell(shell: (path as ChatShellPath).shell),
      );

  /// The coordinator that owns the four shell slots.
  final ChatShellCoordinator<T> shell;

  @override
  Future<void> activateRoute(T route) async => navigate(route);

  @override
  T? get activeRoute => null;

  @override
  PathKey get pathKey => ChatShellPath.key;

  @override
  void reset() {}

  @override
  void dispose() {
    shell.dispose();
    super.dispose();
  }

  @override
  Future<void> navigate(T route) async =>
      (route as ChatShellRoute).navigate(shell);
  
  @override
  Future<R?> push<R extends Object>(T element) async {
    final route = element as ChatShellRoute;
    await route.push(shell);
    return null;
  }
}

/// A dedicated sub-coordinator that owns the four [ChatShell] slots.
///
/// Where [ChatCoordinatorMixin] adds the slots directly onto *your* coordinator,
/// [ChatShellCoordinator] keeps the shell's state isolated so the outer
/// coordinator only deals with top-level routing. Implement [parseRouteFromUri]
/// so slot routes can be restored and deep-linked.
abstract class ChatShellCoordinator<T extends RouteUnique>
    extends Coordinator<T>
    with ChatCoordinatorMixin<T> {
  @override
  FutureOr<T> parseRouteFromUri(Uri uri);

  @override
  Widget layoutBuilder(BuildContext context) => ChatShell<T>(shell: this);
}
