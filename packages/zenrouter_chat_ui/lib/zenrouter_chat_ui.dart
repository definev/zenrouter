/// Slot-based chat UI components for ZenRouter.
///
/// This library provides a four-slot shell layout backed by [NavigationPath]
/// instances, a [ChatListController] for item-list and scroll management, and
/// a [ChatCoordinatorMixin] that wires everything onto any [Coordinator].
///
/// ## Quick start
///
/// 1. Mix [ChatCoordinatorMixin] into your [Coordinator]:
///    ```dart
///    class AppCoordinator extends Coordinator<AppRoute>
///        with ChatCoordinatorMixin<AppRoute> {
///      final listController = ChatListController<Message>();
///      @override AppRoute parseRouteFromUri(Uri uri) => ChatShellRoute();
///    }
///    ```
///
/// 2. Seed slots once (e.g. in the coordinator's constructor):
///    ```dart
///    topBarSlot.swap(DefaultTopBar());
///    bodySlot.swap(MessageListBody());
///    bottomSlot.swap(ComposerBar());
///    // pinnedSlot left empty — renders nothing until filled
///    ```
///
/// 3. Return [ChatShell] from your shell route's `build`:
///    ```dart
///    @override
///    Widget build(AppCoordinator coordinator, BuildContext context) =>
///        ChatShell(coordinator: coordinator);
///    ```
///
/// 4. Drive slots from anywhere that has coordinator access:
///    ```dart
///    // drill into thread (back-stackable)
///    coordinator.bodySlot.fill(ThreadBody(id: msg.id));
///
///    // enter selection mode (two slots swap atomically)
///    coordinator.topBarSlot.swap(SelectionTopBar());
///    coordinator.bottomSlot.swap(ActionBar());
///
///    // show / hide pinned banner
///    coordinator.pinnedSlot.swap(PinnedBanner(text: msg.text));
///    coordinator.pinnedSlot.clearSlot();
///    ```
library zenrouter_chat_ui;

export 'src/path/chat_slot.dart';
export 'src/list/chat_list_controller.dart';
export 'src/coordinator/chat_coordinator_mixin.dart';
export 'src/widgets/chat_metrics.dart';
export 'src/widgets/slot_bar_view.dart';
export 'src/widgets/chat_shell.dart';
