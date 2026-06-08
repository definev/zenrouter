/// Slot-based chat UI components for ZenRouter.
///
/// This library provides a four-slot shell layout backed by [NavigationPath]
/// instances, a [ChatListController] for item-list and scroll management, and
/// two ways to wire the shell onto a [Coordinator].
///
/// ## Quick start
///
/// There are two integration styles:
///
/// - **Single coordinator** — mix [ChatCoordinatorMixin] into your own
///   [Coordinator] to get the four slots directly on it.
/// - **Standardized** — back the shell with a dedicated [ChatShellCoordinator]
///   and reach it through the normal `parseRouteFromUri` → route → layout flow
///   using [ChatShellRoute] / [ChatShellRouteLayout] / [ChatShellPath]. See the
///   `example/` app for a complete walkthrough.
///
/// 1. Create a [ChatShellCoordinator] that owns the slots and your chat data:
///    ```dart
///    class AppChatShell extends ChatShellCoordinator<AppRoute> {
///      final listController = ChatListController<Message>();
///      @override AppRoute parseRouteFromUri(Uri uri) => MessageListBody();
///    }
///    ```
///
/// 2. Seed slots from a [ChatShellRoute.handler] when the chat screen opens:
///    ```dart
///    @override
///    void handler(AppChatShell coordinator) {
///      coordinator.topBarSlot.swap(DefaultTopBar());
///      coordinator.bodySlot.swap(MessageListBody());
///      coordinator.bottomSlot.swap(ComposerBar());
///      // pinnedSlot left empty — renders nothing until filled
///    }
///    ```
///
/// 3. Drive slots from anywhere that has coordinator access:
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
library;

export 'package:navigator_resizable/navigator_resizable.dart';
export 'src/path/chat_slot.dart';
export 'src/list/chat_list_controller.dart';
export 'src/coordinator/chat_coordinator_mixin.dart';
export 'src/widgets/chat_metrics.dart';
export 'src/widgets/slot_bar_view.dart';
export 'src/widgets/chat_shell.dart';
export 'src/transition/vertical_slide_transition.dart';
