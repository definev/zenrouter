import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Manages a chat message list together with its scroll position and unread
/// count.
///
/// Attach one instance to your coordinator and pass [scrollController] and
/// [listController] to the [SuperListView] that renders [items]:
///
/// ```dart
/// SuperListView.builder(
///   controller:     coordinator.listController.scrollController,
///   listController: coordinator.listController.listController,
///   itemCount:      coordinator.listController.items.length,
///   itemBuilder:    (context, i) =>
///       MessageTile(coordinator.listController.items[i]),
/// )
/// ```
///
/// [listController] (the inner `super_sliver_list` [ListController]) enables
/// accurate jump/animate-to-index even before the target item has been laid
/// out, using extent estimation.
class ChatListController<Item extends Object> extends ChangeNotifier {
  ChatListController({double atBottomThreshold = 40.0})
      : _atBottomThreshold = atBottomThreshold {
    scrollController.addListener(_onScroll);
  }

  final double _atBottomThreshold;
  final List<Item> _items = [];
  int _unreadCount = 0;

  /// A [ScrollController] to attach to the body list widget.
  final ScrollController scrollController = ScrollController();

  /// The [super_sliver_list] [ListController] for item-accurate navigation.
  ///
  /// Pass this to `SuperListView.builder(listController: ...)`.
  /// Use [jumpToIndex] / [animateToIndex] rather than calling methods on this
  /// directly, since those wrappers include the [scrollController] binding.
  final ListController listController = ListController();

  // ── item ownership ──────────────────────────────────────────────────────────

  /// The current list of items (unmodifiable view).
  UnmodifiableListView<Item> get items => UnmodifiableListView(_items);

  /// Append [item] to the end of the list.
  ///
  /// Increments [unreadCount] if the user is not at the bottom. Auto-scrolls
  /// to the new item if the user was already at the bottom.
  void add(Item item) {
    final wasAtBottom = isAtBottom;
    _items.add(item);
    if (!wasAtBottom) _unreadCount++;
    notifyListeners();
    if (wasAtBottom) _scheduleScrollToBottom();
  }

  /// Append all [items] to the end of the list.
  void addAll(Iterable<Item> items) {
    final wasAtBottom = isAtBottom;
    final newCount = items.length;
    _items.addAll(items);
    if (!wasAtBottom) _unreadCount += newCount;
    notifyListeners();
    if (wasAtBottom) _scheduleScrollToBottom();
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

  /// Scroll to the bottom of the list.
  ///
  /// Uses [listController.animateToItem] so the position is accurate even
  /// for a list with variable-height items.
  void scrollToBottom({
    bool animate = true,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    if (_items.isEmpty) return;
    _scrollToIndex(
      _items.length - 1,
      alignment: 1.0,
      animate: animate,
      duration: duration,
      curve: curve,
    );
  }

  /// Instantly scroll to the item at [index].
  void jumpToIndex(int index, {double alignment = 0.0}) {
    _scrollToIndex(index, alignment: alignment, animate: false);
  }

  /// Animate to the item at [index].
  void animateToIndex(
    int index, {
    double alignment = 0.0,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    _scrollToIndex(
      index,
      alignment: alignment,
      animate: true,
      duration: duration,
      curve: curve,
    );
  }

  /// Ensure [itemContext] is visible in the scroll view (e.g. for
  /// scroll-to-reply that resolves a BuildContext from a GlobalKey).
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

  // ── internals ───────────────────────────────────────────────────────────────

  void _scrollToIndex(
    int index, {
    required double alignment,
    required bool animate,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    if (!scrollController.hasClients) return;
    if (animate) {
      listController.animateToItem(
        index: index,
        scrollController: scrollController,
        alignment: alignment,
        duration: (_) => duration,
        curve: (_) => curve,
      );
    } else {
      listController.jumpToItem(
        index: index,
        scrollController: scrollController,
        alignment: alignment,
      );
    }
  }

  void _onScroll() {
    if (isAtBottom && _unreadCount > 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void _scheduleScrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => scrollToBottom(),
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    listController.dispose();
    super.dispose();
  }
}
