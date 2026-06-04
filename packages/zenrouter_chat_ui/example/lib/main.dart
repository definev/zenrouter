// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/zenrouter_chat_ui.dart';

// ============================================================================
// Entry point
// ============================================================================

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  static final coordinator = DemoChatCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Chat UI Demo',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// ============================================================================
// Route base
// ============================================================================

abstract class DemoChatRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Coordinator
// ============================================================================

class DemoChatCoordinator extends Coordinator<DemoChatRoute>
    with ChatCoordinatorMixin<DemoChatRoute> {
  DemoChatCoordinator() {
    // Seed the initial slot content once.
    topBarSlot.swap(DefaultTopBar());
    bodySlot.swap(MessageListBody());
    bottomSlot.swap(ComposerBar());
    // pinnedSlot is intentionally left empty — renders nothing until filled.
  }

  final listController = ChatListController<ChatMessage>();

  @override
  DemoChatRoute parseRouteFromUri(Uri uri) => ChatShellRoute();

  @override
  void dispose() {
    listController.dispose();
    super.dispose();
  }
}

// ============================================================================
// Data model
// ============================================================================

class ChatMessage {
  const ChatMessage({required this.id, required this.text, required this.sender});
  final String id;
  final String text;
  final String sender;
}

// ============================================================================
// Shell route — the root route that builds the ChatShell layout
// ============================================================================

class ChatShellRoute extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/chat');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return ChatShell<DemoChatRoute>(coordinator: coordinator);
  }
}

// ============================================================================
// TOP BAR slot routes
// ============================================================================

class DefaultTopBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/top/default');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      elevation: 2,
      child: Container(
        height: kToolbarHeight,
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '#general',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () {
                coordinator.topBarSlot.swap(SearchTopBar());
                coordinator.bodySlot.swap(SearchResultsBody());
              },
            ),
            IconButton(
              icon: const Icon(Icons.push_pin_outlined),
              tooltip: 'Pin a message',
              onPressed: () {
                coordinator.pinnedSlot.swap(
                  PinnedBanner(text: 'Important pinned message!'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionTopBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/top/selection');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel selection',
              onPressed: () {
                coordinator.topBarSlot.swap(DefaultTopBar());
                coordinator.bottomSlot.swap(ComposerBar());
              },
            ),
            const Expanded(
              child: Text(
                '1 selected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchTopBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/top/search');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      elevation: 2,
      child: Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Close search',
              onPressed: () {
                coordinator.topBarSlot.swap(DefaultTopBar());
                coordinator.bodySlot.swap(MessageListBody());
              },
            ),
            const Expanded(
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search messages…',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PINNED slot route
// ============================================================================

class PinnedBanner extends DemoChatRoute {
  PinnedBanner({required this.text});
  final String text;

  @override
  Uri toUri() => Uri.parse('/slots/pinned');

  @override
  List<Object?> get props => [text];

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: InkWell(
        onTap: () {
          // Tapping a pinned banner could drill into the pinned message.
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Unpin',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => coordinator.pinnedSlot.clearSlot(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BODY slot routes
// ============================================================================

/// Message list — the default body content.
class MessageListBody extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/body/messages');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    final metrics = ChatMetrics.of(context);
    return ListenableBuilder(
      listenable: coordinator.listController,
      builder: (context, _) {
        final controller = coordinator.listController;
        final items = controller.items;

        return Stack(
          children: [
            // SuperListView gives accurate jump-to-index for variable-height
            // items via the ListController extent estimation.
            SuperListView.builder(
              controller: controller.scrollController,
              listController: controller.listController,
              // Pad so content is never hidden under floating bars.
              padding: EdgeInsets.only(
                top: metrics.topInset + 8,
                bottom: metrics.bottomInset + 8,
              ),
              itemCount: items.isEmpty ? 1 : items.length,
              itemBuilder: (context, index) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No messages yet.\nTap + to add some.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                final msg = items[index];
                return _MessageTile(
                  message: msg,
                  onTap: () => coordinator.bodySlot.fill(ThreadBody(id: msg.id)),
                  onLongPress: () {
                    coordinator.topBarSlot.swap(SelectionTopBar());
                    coordinator.bottomSlot.swap(ActionBar());
                  },
                );
              },
            ),

            // Unread badge — tap to animate to the newest message.
            Positioned(
              bottom: metrics.bottomInset + 12,
              right: 16,
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final count = controller.unreadCount;
                  if (count == 0) return const SizedBox.shrink();
                  return FloatingActionButton.extended(
                    mini: true,
                    onPressed: () {
                      controller.scrollToBottom();
                      controller.markAllRead();
                    },
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: Text('$count new'),
                  );
                },
              ),
            ),

            // Demo: jump-to-first button (shows jumpToIndex API).
            if (items.length > 1)
              Positioned(
                bottom: metrics.bottomInset + 12,
                left: 72,
                child: FloatingActionButton.small(
                  heroTag: 'jump_first',
                  tooltip: 'Jump to first message',
                  onPressed: () => controller.jumpToIndex(0),
                  child: const Icon(Icons.vertical_align_top),
                ),
              ),

            // FAB to add demo messages.
            Positioned(
              bottom: metrics.bottomInset + 12,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'add_msg',
                tooltip: 'Add message',
                onPressed: () {
                  final id = DateTime.now().millisecondsSinceEpoch.toString();
                  coordinator.listController.add(
                    ChatMessage(id: id, text: 'Message $id', sender: 'Alice'),
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Thread detail view — pushed onto the body slot's back-stack.
class ThreadBody extends DemoChatRoute {
  ThreadBody({required this.id});
  final String id;

  @override
  Uri toUri() => Uri.parse('/slots/body/thread/$id');

  @override
  List<Object?> get props => [id];

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    final metrics = ChatMetrics.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: ListView(
        padding: EdgeInsets.only(
          top: metrics.topInset + 8,
          bottom: metrics.bottomInset + 8,
          left: 16,
          right: 16,
        ),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => coordinator.bodySlot.pop(),
              ),
              Text(
                'Thread: $id',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Thread replies would appear here.'),
        ],
      ),
    );
  }
}

/// Search results — swapped into the body slot when search is active.
class SearchResultsBody extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/body/search');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    final metrics = ChatMetrics.of(context);
    return ListView(
      padding: EdgeInsets.only(
        top: metrics.topInset + 8,
        bottom: metrics.bottomInset + 8,
        left: 16,
        right: 16,
      ),
      children: const [
        Text(
          'Search results',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text('Results would appear here as the user types.'),
      ],
    );
  }
}

// ============================================================================
// BOTTOM BAR slot routes
// ============================================================================

class ComposerBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/bottom/composer');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Message #general…',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.mic),
              tooltip: 'Record',
              onPressed: () => coordinator.bottomSlot.swap(RecordingBar()),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Send',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                coordinator.listController.add(
                  ChatMessage(id: id, text: 'Sent message $id', sender: 'Me'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ActionBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/bottom/action');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.reply),
              tooltip: 'Reply',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.forward),
              tooltip: 'Forward',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy',
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/bottom/recording');

  @override
  Widget build(DemoChatCoordinator coordinator, BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.fiber_manual_record, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Recording…', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () => coordinator.bottomSlot.swap(ComposerBar()),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('Send'),
              onPressed: () {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                coordinator.listController.add(
                  ChatMessage(id: id, text: '🎤 Voice message $id', sender: 'Me'),
                );
                coordinator.bottomSlot.swap(ComposerBar());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper widgets
// ============================================================================

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatMessage message;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(message.sender[0])),
      title: Text(message.sender),
      subtitle: Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
