import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/src/path/chat_slot.dart';

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
  late final ChatSlot<T> topBarSlot = NavigationPath.createWith(
    coordinator: this,
    label: 'slot.topbar',
  );

  late final ChatSlot<T> pinnedSlot = NavigationPath.createWith(
    coordinator: this,
    label: 'slot.pinned',
  );

  late final ChatSlot<T> bodySlot = NavigationPath.createWith(
    coordinator: this,
    label: 'slot.body',
  );

  late final ChatSlot<T> bottomSlot = NavigationPath.createWith(
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
