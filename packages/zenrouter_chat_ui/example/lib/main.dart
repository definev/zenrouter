import 'package:flutter/cupertino.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/zenrouter_chat_ui.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

// ============================================================================
// Entry point
// ============================================================================

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  static final coordinator = DemoCoordinator();

  @override
  Widget build(BuildContext context) {
    return CupertinoApp.router(
      title: 'ZenRouter Chat UI Demo',
      theme: const CupertinoThemeData(primaryColor: Color(0xFF007AFF)),
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
// Root coordinator
// ============================================================================
//
// The outer coordinator only deals with top-level routing. It owns the
// [ChatShellPath] (which holds the chat-shell sub-coordinator) and registers
// the [ChatLayout] that renders the shell. Navigating to `/chat` resolves the
// layout, which in turn renders a [ChatShell] driven by [DemoChatShellCoordinator].

class DemoCoordinator extends Coordinator<DemoChatRoute> with CoordinatorDebug {
  /// The path the [ChatLayout] resolves to. Owns the shell sub-coordinator.
  final chatShellPath = ChatShellPath<DemoChatRoute>(
    shell: DemoChatShellCoordinator(),
  );

  @override
  List<StackPath> get paths => [...super.paths, chatShellPath, ...chatShellPath.shell.paths];

  @override
  void defineLayout() {
    super.defineLayout();
    // Register the layout constructor so routes whose `parentLayoutKey` is
    // `ChatLayout.key` resolve into the chat shell …
    defineLayoutParent(ChatLayout.new);
    // … and teach the coordinator how to render a `ChatShellPath`.
    ChatShellPath.defineBuilder(this);
  }

  @override
  void dispose() {
    chatShellPath.dispose();
    super.dispose();
  }

  @override
  DemoChatRoute parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['chat', 'thread', final id] => ThreadRoute(id: id),
    [] || ['chat'] => ChatRoute(),
    _ => ChatRoute(),
  };
}

// ============================================================================
// Shell coordinator — owns the four slots and the chat data
// ============================================================================
//
// [DemoChatShellCoordinator] is a [ChatShellCoordinator], so it already exposes
// `topBarSlot` / `pinnedSlot` / `bodySlot` / `bottomSlot`. Slot routes are built
// with *this* coordinator, and `parseRouteFromUri` lets each slot route be
// restored after a relaunch.

class DemoChatShellCoordinator extends ChatShellCoordinator<DemoChatRoute> {
  DemoChatShellCoordinator() {
    listController.addAll(const [
      ChatMessage(
        id: 'welcome',
        text: 'Hey! Welcome to #general 👋',
        sender: 'Guest',
        isMe: false,
      ),
      ChatMessage(
        id: 'intro',
        text: 'Long-press a message to select. Tap more to select multiple.',
        sender: 'Guest',
        isMe: false,
      ),
    ]);
  }

  final listController = ChatListController<ChatMessage>();

  /// Thread replies keyed by parent message id.
  final threadReplies = <String, List<ChatMessage>>{};

  ChatMessage? messageById(String id) {
    for (final msg in listController.items) {
      if (msg.id == id) return msg;
    }
    return null;
  }

  int threadReplyCount(String messageId) =>
      threadReplies[messageId]?.length ?? 0;

  /// Multi-select state for the message list.
  final selectedMessageIds = <String>{};

  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  int get selectedCount => selectedMessageIds.length;

  bool isMessageSelected(String id) => selectedMessageIds.contains(id);

  void beginSelecting(String messageId) {
    selectedMessageIds
      ..clear()
      ..add(messageId);
    notifyListeners();
    topBarSlot.swap(SelectionTopBar());
    bottomSlot.swap(ActionBar());
  }

  void toggleMessageSelection(String messageId) {
    if (selectedMessageIds.contains(messageId)) {
      selectedMessageIds.remove(messageId);
      if (selectedMessageIds.isEmpty) {
        exitSelectionMode();
        return;
      }
    } else {
      selectedMessageIds.add(messageId);
    }
    notifyListeners();
  }

  void exitSelectionMode() {
    if (selectedMessageIds.isEmpty &&
        topBarSlot.activeRoute is! SelectionTopBar) {
      return;
    }
    selectedMessageIds.clear();
    notifyListeners();
    topBarSlot.swap(DefaultTopBar());
    bottomSlot.swap(ComposerBar());
  }

  void deleteSelectedMessages() {
    for (final id in selectedMessageIds.toList()) {
      final msg = messageById(id);
      if (msg != null) listController.remove(msg);
      threadReplies.remove(id);
    }
    exitSelectionMode();
  }

  void addThreadReply(String messageId, ChatMessage reply) {
    threadReplies.putIfAbsent(messageId, () => []).add(reply);
    notifyListeners();
  }

  @override
  DemoChatRoute parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['slots', 'top', 'default'] => DefaultTopBar(),
    ['slots', 'top', 'selection'] => SelectionTopBar(),
    ['slots', 'top', 'search'] => SearchTopBar(),
    ['slots', 'top', 'thread', final id] => ThreadTopBar(id: id),
    ['slots', 'pinned'] => PinnedBanner(text: 'Pinned message'),
    ['slots', 'body', 'thread', final id] => ThreadBody(id: id),
    ['slots', 'body', 'search'] => SearchResultsBody(),
    ['slots', 'bottom', 'composer'] => ComposerBar(),
    ['slots', 'bottom', 'thread', final id] => ThreadComposerBar(id: id),
    ['slots', 'bottom', 'action'] => ActionBar(),
    ['slots', 'bottom', 'recording'] => RecordingBar(),
    _ => MessageListBody(),
  };

  /// Pops the thread-specific top bar, body and composer together, returning
  /// every slot to whatever was underneath (the message list + default chrome).
  void closeThread() {
    topBarSlot.pop();
    bodySlot.pop();
    bottomSlot.pop();
  }

  @override
  void dispose() {
    listController.dispose();
    super.dispose();
  }
}

// ============================================================================
// Chat layout + entry route
// ============================================================================

/// The layout that renders the [ChatShell]. It resolves to the root
/// coordinator's [DemoCoordinator.chatShellPath].
class ChatLayout extends DemoChatRoute
    with RouteLayout<DemoChatRoute>, ChatShellRouteLayout<DemoChatRoute> {
  static const key = 'ChatLayout';

  @override
  Object get layoutKey => key;

  @override
  ChatShellPath<DemoChatRoute> resolvePath(
    covariant DemoCoordinator coordinator,
  ) => coordinator.chatShellPath;
}

/// The route that enters the chat shell. Its `handler` seeds the slots with
/// their default content instead of building a widget directly.
class ChatRoute extends DemoChatRoute with ChatShellRoute<DemoChatRoute> {
  @override
  Uri toUri() => Uri.parse('/chat');

  @override
  Object get parentLayoutKey => ChatLayout.key;

  @override
  void navigate(covariant DemoChatShellCoordinator coordinator) {
    coordinator.topBarSlot.swap(DefaultTopBar());
    coordinator.bodySlot.swap(MessageListBody());
    coordinator.bottomSlot.swap(ComposerBar());
    // pinnedSlot is intentionally left empty — renders nothing until filled.
  }
}

/// A second [ChatShellRoute] that demonstrates *pushing* an inner slot instead
/// of swapping it.
///
/// Navigating to `/chat/thread/:id` reuses the already-active [ChatLayout], and
/// this route's `handler` runs against the same shell coordinator. It uses
/// `fill` (a slot back-stack push) rather than `swap`, so the thread view
/// animates in over the message list and can be popped back.
class ThreadRoute extends DemoChatRoute with ChatShellRoute<DemoChatRoute> {
  ThreadRoute({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/chat/thread/$id');

  @override
  Object get parentLayoutKey => ChatLayout.key;

  @override
  void navigate(covariant DemoChatShellCoordinator coordinator) {
    // `fill` == push onto each slot's back-stack (vs `swap`, which replaces the
    // whole slot). The previous routes stay underneath, so popping returns to
    // them. All three slots get a thread-specific route so the chrome (top bar
    // and composer) matches the detail view, then reverts together on close.
    coordinator.topBarSlot.swap(ThreadTopBar(id: id));
    coordinator.bodySlot.fill(ThreadBody(id: id));
    coordinator.bottomSlot.swap(ThreadComposerBar(id: id));
  }
}

// ============================================================================
// Data model
// ============================================================================

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.isMe,
  });

  final String id;
  final String text;
  final String sender;
  final bool isMe;
}

void openThread(String messageId) {
  DemoApp.coordinator.push(ThreadRoute(id: messageId));
}

// ============================================================================
// Shared chrome
// ============================================================================

const _kBarHeight = 44.0;

Color _barBackground(BuildContext context) =>
    CupertinoTheme.of(context).barBackgroundColor;

Border _barBottomBorder(BuildContext context) => Border(
  bottom: BorderSide(
    color: CupertinoColors.separator.resolveFrom(context),
    width: 0.5,
  ),
);

Widget _barIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color? color,
}) {
  return CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(_kBarHeight, _kBarHeight),
    onPressed: onPressed,
    child: Icon(icon, color: color),
  );
}

// ============================================================================
// TOP BAR slot routes
// ============================================================================

class DefaultTopBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/top/default');

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _barBackground(context),
        border: _barBottomBorder(context),
      ),
      child: SizedBox(
        height: _kBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(CupertinoIcons.chat_bubble_2),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '#general',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              _barIconButton(
                icon: CupertinoIcons.search,
                onPressed: () {
                  coordinator.topBarSlot.swap(SearchTopBar());
                  coordinator.bodySlot.swap(SearchResultsBody());
                },
              ),
              _barIconButton(
                icon: CupertinoIcons.pin,
                onPressed: () {
                  coordinator.pinnedSlot.swap(
                    PinnedBanner(text: 'Important pinned message!'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionTopBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/top/selection');

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        border: _barBottomBorder(context),
      ),
      child: SizedBox(
        height: _kBarHeight,
        child: ListenableBuilder(
          listenable: coordinator,
          builder: (context, _) {
            final count = coordinator.selectedCount;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _barIconButton(
                    icon: CupertinoIcons.xmark,
                    onPressed: coordinator.exitSelectionMode,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: _motionDuration(context),
                        switchInCurve: _kSelectionCurve,
                        switchOutCurve: _kSelectionCurve,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Text(
                          count == 1 ? '1 selected' : '$count selected',
                          key: ValueKey<int>(count),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class SearchTopBar extends DemoChatRoute with RouteTransition {
  @override
  Uri toUri() => Uri.parse('/slots/top/search');

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _barBackground(context),
        border: _barBottomBorder(context),
      ),
      child: SizedBox(
        height: _kBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _barIconButton(
                icon: CupertinoIcons.back,
                onPressed: () {
                  coordinator.topBarSlot.swap(DefaultTopBar());
                  coordinator.bodySlot.swap(MessageListBody());
                  coordinator.bottomSlot.swap(ComposerBar());
                },
              ),
              const Expanded(
                child: CupertinoTextField(
                  autofocus: true,
                  placeholder: 'Search messages…',
                  decoration: null,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    DemoChatShellCoordinator coordinator,
  ) {
    return StackTransition.custom(
      builder: (context) => build(coordinator, context),
      pageBuilder: (context, routeKey, child) =>
          ResizableMaterialPage(child: child),
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
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tapping a pinned banner could drill into the pinned message.
      },
      child: ColoredBox(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(CupertinoIcons.pin_fill, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(24, 24),
                onPressed: () => coordinator.pinnedSlot.clearSlot(),
                child: const Icon(CupertinoIcons.xmark, size: 16),
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
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    final metrics = ChatMetrics.of(context);
    return CupertinoPageScaffold(
      child: ListenableBuilder(
        listenable: Listenable.merge([coordinator.listController, coordinator]),
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
                reverse: true,
                itemBuilder: (context, index) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No messages yet.\nSend a message or tap + for a guest reply.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                      ),
                    );
                  }
                  final msg = items[items.length - index - 1];
                  final isSelectionMode = coordinator.isSelectionMode;
                  return _ChatBubble(
                    message: msg,
                    threadReplyCount: coordinator.threadReplyCount(msg.id),
                    isSelected: coordinator.isMessageSelected(msg.id),
                    isSelectionMode: isSelectionMode,
                    onTap: () {
                      if (isSelectionMode) {
                        coordinator.toggleMessageSelection(msg.id);
                      } else {
                        openThread(msg.id);
                      }
                    },
                    onOpenThread: () => openThread(msg.id),
                    onLongPress: () => coordinator.beginSelecting(msg.id),
                  );
                },
              ),

              // Demo: jump-to-first button (shows jumpToIndex API).
              if (items.length > 1)
                Positioned(
                  top: metrics.topInset + 12,
                  left: 72,
                  child: _RoundIconButton(
                    icon: CupertinoIcons.arrow_up_to_line,
                    onPressed: () => controller.scrollController.animateTo(
                      0,
                      curve: Curves.ease,
                      duration: Duration(milliseconds: 250),
                    ),
                  ),
                ),

              // Button to add demo messages.
              Positioned(
                top: metrics.topInset + 12,
                right: 16,
                child: _RoundIconButton(
                  icon: CupertinoIcons.add,
                  onPressed: () {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    coordinator.listController.add(
                      ChatMessage(
                        id: id,
                        text: 'Guest reply $id',
                        sender: 'Guest',
                        isMe: false,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Thread detail view — pushed onto the body slot's back-stack.
///
/// The back action and title live in the dedicated [ThreadTopBar], so the body
/// only renders the thread content.
class ThreadBody extends DemoChatRoute with RouteTransition {
  ThreadBody({required this.id});
  final String id;

  @override
  Uri toUri() => Uri.parse('/slots/body/thread/$id');

  @override
  List<Object?> get props => [id];

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    final metrics = ChatMetrics.of(context);
    final parent = coordinator.messageById(id);

    return ColoredBox(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: ListenableBuilder(
        listenable: coordinator,
        builder: (context, _) {
          final replies = coordinator.threadReplies[id] ?? const [];
          return ListView(
            padding: EdgeInsets.only(
              top: metrics.topInset + 12,
              bottom: metrics.bottomInset + 8,
              right: 16,
              left: 16,
            ),
            children: [
              if (parent != null) ...[
                Text(
                  'Thread',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 8),
                _ChatBubble(
                  message: parent,
                  threadReplyCount: 0,
                  showThreadAction: false,
                  onTap: () {},
                  onOpenThread: () {},
                  onLongPress: () {},
                ),
                const SizedBox(height: 16),
                if (replies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
              ] else
                Text(
                  'Message not found.',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              for (final reply in replies)
                _ChatBubble(
                  message: reply,
                  threadReplyCount: 0,
                  showThreadAction: false,
                  onTap: () {},
                  onOpenThread: () {},
                  onLongPress: () {},
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    DemoChatShellCoordinator coordinator,
  ) {
    return StackTransition.custom(
      builder: (context) => build(coordinator, context),
      pageBuilder: (context, routeKey, child) =>
          CupertinoSheetPage(builder: (context) => child),
    );
  }
}

/// Thread-specific top bar — back button + thread title. Pushed by
/// [ThreadRoute.navigate] so the header matches the detail view.
class ThreadTopBar extends DemoChatRoute {
  ThreadTopBar({required this.id});
  final String id;

  @override
  Uri toUri() => Uri.parse('/slots/top/thread/$id');

  @override
  List<Object?> get props => [id];

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    final parent = coordinator.messageById(id);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _barBackground(context),
        border: _barBottomBorder(context),
      ),
      child: SizedBox(
        height: _kBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _barIconButton(
                icon: CupertinoIcons.back,
                // Pops the top bar, body and composer together.
                onPressed: coordinator.closeThread,
              ),
              const Icon(CupertinoIcons.chat_bubble_text, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  parent != null ? 'Thread · ${parent.sender}' : 'Thread: $id',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search results — swapped into the body slot when search is active.
class SearchResultsBody extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/body/search');

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    final metrics = ChatMetrics.of(context);
    return CupertinoPageScaffold(
      child: ListView(
        padding: EdgeInsets.only(
          top: metrics.topInset + 8,
          bottom: metrics.bottomInset + 8,
          right: 16,
          left: 16,
        ),
        children: const [
          Text(
            'Search results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('Results would appear here as the user types.'),
        ],
      ),
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
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return _ComposerBarContent(
      placeholder: 'Message #general…',
      onSend: (text) {
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        coordinator.listController.add(
          ChatMessage(id: id, text: text, sender: 'Me', isMe: true),
        );
      },
      onMic: () => coordinator.bottomSlot.swap(RecordingBar()),
    );
  }
}

/// Thread-specific composer — pushed by [ThreadRoute.navigate] so the bottom bar
/// reflects that replies go to the thread rather than the main channel.
class ThreadComposerBar extends DemoChatRoute {
  ThreadComposerBar({required this.id});
  final String id;

  @override
  Uri toUri() => Uri.parse('/slots/bottom/thread/$id');

  @override
  List<Object?> get props => [id];

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return _ComposerBarContent(
      placeholder: 'Reply in thread…',
      onSend: (text) {
        final replyId = DateTime.now().millisecondsSinceEpoch.toString();
        coordinator.addThreadReply(
          id,
          ChatMessage(id: replyId, text: text, sender: 'Me', isMe: true),
        );
      },
    );
  }
}

class ActionBar extends DemoChatRoute {
  @override
  Uri toUri() => Uri.parse('/slots/bottom/action');

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _barIconButton(
              icon: CupertinoIcons.arrowshape_turn_up_left,
              onPressed: () {},
            ),
            _barIconButton(
              icon: CupertinoIcons.arrowshape_turn_up_right,
              onPressed: () {},
            ),
            _barIconButton(icon: CupertinoIcons.doc_on_doc, onPressed: () {}),
            _barIconButton(
              icon: CupertinoIcons.delete,
              onPressed: coordinator.deleteSelectedMessages,
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

  static const _minHeight = 56.0;
  static const _maxHeight = 112.0;

  @override
  Widget build(DemoChatShellCoordinator coordinator, BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: RepeatingAnimationBuilder<double>(
        animatable: Tween<double>(begin: _minHeight, end: _maxHeight),
        duration: const Duration(milliseconds: 1200),
        repeatMode: RepeatMode.reverse,
        curve: Curves.easeInOut,
        builder: (context, height, child) {
          return SizedBox(
            height: height,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.circle_fill,
                    color: CupertinoColors.systemRed,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recording…',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Height ${height.toStringAsFixed(0)} — NavigatorResizable',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => coordinator.bottomSlot.swap(ComposerBar()),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    onPressed: () {
                      final id = DateTime.now().millisecondsSinceEpoch
                          .toString();
                      coordinator.listController.add(
                        ChatMessage(
                          id: id,
                          text: '🎤 Voice message',
                          sender: 'Me',
                          isMe: true,
                        ),
                      );
                      coordinator.bottomSlot.swap(ComposerBar());
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.stop_fill, size: 18),
                        SizedBox(width: 4),
                        Text('Send'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// Helper widgets
// ============================================================================

const _kSelectionDuration = Duration(milliseconds: 220);
const _kSelectionCurve = Curves.easeOutCubic;

Duration _motionDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : _kSelectionDuration;

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(10),
      color: CupertinoTheme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(22),
      onPressed: onPressed,
      child: Icon(icon, color: CupertinoColors.white, size: 20),
    );
  }
}

class _ComposerBarContent extends StatefulWidget {
  const _ComposerBarContent({
    required this.placeholder,
    required this.onSend,
    this.onMic,
  });

  final String placeholder;
  final ValueChanged<String> onSend;
  final VoidCallback? onMic;

  @override
  State<_ComposerBarContent> createState() => _ComposerBarContentState();
}

class _ComposerBarContentState extends State<_ComposerBarContent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _barBackground(context),
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                placeholder: widget.placeholder,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill.resolveFrom(
                    context,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.onMic != null)
              _barIconButton(
                icon: CupertinoIcons.mic,
                onPressed: widget.onMic!,
              ),
            _barIconButton(
              icon: CupertinoIcons.arrow_up_circle_fill,
              color: CupertinoTheme.of(context).primaryColor,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.threadReplyCount,
    required this.onTap,
    required this.onOpenThread,
    required this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.showThreadAction = true,
  });

  final ChatMessage message;
  final int threadReplyCount;
  final VoidCallback onTap;
  final VoidCallback onOpenThread;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;
  final bool showThreadAction;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final duration = _motionDuration(context);
    final bubbleColor = isMe
        ? CupertinoTheme.of(context).primaryColor
        : CupertinoColors.tertiarySystemFill.resolveFrom(context);
    final textColor = isMe
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowAlignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );
    final selectionBorderColor = isMe
        ? CupertinoColors.white
        : CupertinoColors.activeBlue.resolveFrom(context);
    final highlightColor = CupertinoColors.activeBlue.resolveFrom(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: duration,
        curve: _kSelectionCurve,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: highlightColor.withValues(alpha: isSelected ? 0.14 : 0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: rowAlignment,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _SelectionCheckmarkSlot(
              visible: isSelectionMode && !isMe,
              isSelected: isSelected,
              alignment: Alignment.centerLeft,
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: alignment,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        message.sender,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    textDirection: isMe ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 0.98 : 1,
                        duration: duration,
                        curve: _kSelectionCurve,
                        child: AnimatedContainer(
                          duration: duration,
                          curve: _kSelectionCurve,
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                          ),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: borderRadius,
                            border: Border.all(
                              color: isSelected
                                  ? selectionBorderColor
                                  : CupertinoColors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: highlightColor.withValues(
                                  alpha: isSelected ? 0.35 : 0,
                                ),
                                blurRadius: isSelected ? 8 : 0,
                                offset: Offset(0, isSelected ? 2 : 0),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Text(
                              message.text,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (showThreadAction)
                        AnimatedOpacity(
                          duration: duration,
                          curve: _kSelectionCurve,
                          opacity: isSelectionMode ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: isSelectionMode,
                            child: _ThreadChip(
                              threadReplyCount: threadReplyCount,
                              onOpenThread: onOpenThread,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _SelectionCheckmarkSlot(
              visible: isSelectionMode && isMe,
              isSelected: isSelected,
              alignment: Alignment.centerRight,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadChip extends StatelessWidget {
  const _ThreadChip({
    required this.threadReplyCount,
    required this.onOpenThread,
  });

  final int threadReplyCount;
  final VoidCallback onOpenThread;

  @override
  Widget build(BuildContext context) {
    final label = threadReplyCount > 0
        ? '$threadReplyCount ${threadReplyCount == 1 ? 'reply' : 'replies'}'
        : '';

    return CupertinoButton(
      padding: const EdgeInsets.only(left: 6, right: 4, bottom: 2),
      minimumSize: Size.zero,
      onPressed: onOpenThread,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_text,
            size: 14,
            color: CupertinoColors.activeBlue.resolveFrom(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.activeBlue.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionCheckmarkSlot extends StatelessWidget {
  const _SelectionCheckmarkSlot({
    required this.visible,
    required this.isSelected,
    required this.alignment,
  });

  final bool visible;
  final bool isSelected;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final duration = _motionDuration(context);

    return AnimatedSize(
      duration: duration,
      curve: _kSelectionCurve,
      alignment: alignment,
      clipBehavior: Clip.hardEdge,
      child: visible
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _SelectionCheckmark(isSelected: isSelected),
            )
          : const SizedBox(width: 0, height: 24),
    );
  }
}

class _SelectionCheckmark extends StatelessWidget {
  const _SelectionCheckmark({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final duration = _motionDuration(context);
    final activeBlue = CupertinoColors.activeBlue.resolveFrom(context);

    return AnimatedContainer(
      duration: duration,
      curve: _kSelectionCurve,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? activeBlue
            : CupertinoColors.tertiarySystemFill.resolveFrom(context),
        border: Border.all(
          color: isSelected
              ? activeBlue
              : CupertinoColors.separator.resolveFrom(context),
          width: 1.5,
        ),
      ),
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: _kSelectionCurve,
        switchOutCurve: _kSelectionCurve,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: isSelected
            ? const Icon(
                CupertinoIcons.checkmark,
                key: ValueKey('selected'),
                size: 14,
                color: CupertinoColors.white,
              )
            : SizedBox(key: const ValueKey('empty'), width: 24, height: 24),
      ),
    );
  }
}
