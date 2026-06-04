import 'package:flutter/widgets.dart';

/// Holds the current pixel heights of the top-bar area and the bottom-bar area
/// as measured by [ChatShell].
///
/// Body routes should read these values and apply them as [ListView] padding so
/// that message content is never hidden under a floating bar:
///
/// ```dart
/// final metrics = ChatMetrics.of(context);
/// return ListView.builder(
///   padding: EdgeInsets.only(
///     top:    metrics.topInset,
///     bottom: metrics.bottomInset,
///   ),
///   ...
/// );
/// ```
class ChatMetrics extends InheritedWidget {
  const ChatMetrics({
    super.key,
    required this.topInset,
    required this.bottomInset,
    required super.child,
  });

  /// Combined height of the top-bar slot + pinned slot (in logical pixels).
  final double topInset;

  /// Height of the bottom-bar slot (in logical pixels).
  final double bottomInset;

  static final _zero = ChatMetrics(
    topInset: 0,
    bottomInset: 0,
    child: const SizedBox.shrink(),
  );

  static ChatMetrics? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatMetrics>();

  /// Returns [ChatMetrics] for [context], or zero-insets when no ancestor
  /// [ChatShell] is found.
  static ChatMetrics of(BuildContext context) => maybeOf(context) ?? _zero;

  @override
  bool updateShouldNotify(ChatMetrics oldWidget) =>
      topInset != oldWidget.topInset || bottomInset != oldWidget.bottomInset;
}

/// Measures the natural height of its [child] and reports it via [onSize].
///
/// Used internally by [ChatShell] to track bar heights.
class MeasuredBar extends StatefulWidget {
  const MeasuredBar({super.key, required this.child, required this.onSize});

  final Widget child;
  final ValueChanged<double> onSize;

  @override
  State<MeasuredBar> createState() => _MeasuredBarState();
}

class _MeasuredBarState extends State<MeasuredBar> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(_) {
    if (!mounted) return;
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      widget.onSize(renderBox.size.height);
    }
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// Internal state holder for bar heights; notifies listeners on change.
///
/// Exposed publicly so [ChatShell] and tests can reference heights directly.
class ChatShellMetricsNotifier extends ChangeNotifier {
  double _topBarHeight = 0;
  double _pinnedHeight = 0;
  double _bottomHeight = 0;

  /// Height of the top-bar slot only (excluding pinned).
  double get topBarHeight => _topBarHeight;

  /// Combined height that the body must offset from the top.
  double get topInset => _topBarHeight + _pinnedHeight;

  /// Height that the body must offset from the bottom.
  double get bottomInset => _bottomHeight;

  void updateTopBar(double h) {
    if (_topBarHeight == h) return;
    _topBarHeight = h;
    notifyListeners();
  }

  void updatePinned(double h) {
    if (_pinnedHeight == h) return;
    _pinnedHeight = h;
    notifyListeners();
  }

  void updateBottom(double h) {
    if (_bottomHeight == h) return;
    _bottomHeight = h;
    notifyListeners();
  }
}
