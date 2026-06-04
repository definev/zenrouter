import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Manages a chat message list together with its scroll position and unread
/// count.
///
/// Attach one instance to your coordinator and pass [scrollController] to the
/// [ListView] (or equivalent) that renders [items].
///
/// ```dart
/// class MyChatCoordinator extends Coordinator<MyChatRoute>
///     with ChatCoordinatorMixin<MyChatRoute> {
///   final listController = ChatListController<ChatMessage>();
///
///   @override
///   void dispose() {
///     listController.dispose();
///     super.dispose();
///   }
/// }
/// ```
///
/// In the body route's build method:
/// ```dart
/// ListView.builder(
///   controller: coordinator.listController.scrollController,
///   itemCount:   coordinator.listController.items.length,
///   itemBuilder: (context, i) => MessageTile(coordinator.listController.items[i]),
/// )
/// ```
class ChatListController<Item extends Object> extends ChangeNotifier {
  ChatListController({double _atBottomThreshold = 40.0})
      : _atBottomThreshold = _atBottomThreshold {
    scrollController.addListener(_onScroll);
  }

  final double _atBottomThreshold;
  final List<Item> _items = [];
  int _unreadCount = 0;

  /// A [ScrollController] to attach to the body list widget.
  final ScrollController scrollController = ScrollController();

  // ── item ownership ──────────────────────────────────────────────────────────

  /// The current list of items (unmodifiable view).
  UnmodifiableListView<Item> get items => UnmodifiableListView(_items);

  /// Append [item] to the end of the list.
  ///
  /// If the user has scrolled up (not at bottom), [unreadCount] is incremented.
  void add(Item item) {
    _items.add(item);
    if (!isAtBottom) _unreadCount++;
    notifyListeners();
    if (isAtBottom) _scheduleScrollToBottom();
  }

  /// Append all [items] to the end of the list.
  void addAll(Iterable<Item> items) {
    final hadBottom = isAtBottom;
    final newCount = items.length;
    _items.addAll(items);
    if (!hadBottom) _unreadCount += newCount;
    notifyListeners();
    if (hadBottom) _scheduleScrollToBottom();
  }

  /// Insert [item] at [index].
  void insert(int index, Item item) {
    _items.insert(index, item);
    notifyListeners();
  }

  /// Remove [item] from the list.
  void remove(Item item) {
    _items.remove(item);
    notifyListeners();
  }

  /// Replace the entire list with [newItems].
  void replaceAll(List<Item> newItems) {
    _items
      ..clear()
      ..addAll(newItems);
    _unreadCount = 0;
    notifyListeners();
  }

  // ── scroll control ──────────────────────────────────────────────────────────

  /// Whether the scroll position is at (or very near) the bottom of the list.
  bool get isAtBottom {
    if (!scrollController.hasClients) return true;
    final pos = scrollController.position;
    return pos.pixels >= pos.maxScrollExtent - _atBottomThreshold;
  }

  /// Animate the list to the bottom.
  void scrollToBottom({
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    if (!scrollController.hasClients) return;
    if (animate) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: duration,
        curve: curve,
      );
    } else {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }

  /// Ensure [itemContext] is visible in the scroll view.
  ///
  /// Convenience wrapper around [Scrollable.ensureVisible].
  Future<void> ensureVisible(
    BuildContext itemContext, {
    double alignment = 0.0,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) => Scrollable.ensureVisible(
    itemContext,
    alignment: alignment,
    duration: duration,
    curve: curve,
  );

  // ── unread badge ────────────────────────────────────────────────────────────

  /// Number of items added to the end of the list while the user was not at
  /// the bottom of the scroll view.
  int get unreadCount => _unreadCount;

  /// Reset [unreadCount] to zero (call after scrolling to bottom or tapping
  /// the unread badge).
  void markAllRead() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  // ── internals ───────────────────────────────────────────────────────────────

  void _onScroll() {
    if (isAtBottom && _unreadCount > 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _scheduleScrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) => scrollToBottom());
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}
