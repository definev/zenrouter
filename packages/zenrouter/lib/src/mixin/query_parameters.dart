import 'package:flutter/widgets.dart';
import 'package:zenrouter/src/coordinator/base.dart';

import 'unique.dart';

/// Mixin for routes that support query parameters.
///
/// This mixin provides a [ValueNotifier] for queries that allows widgets to
/// rebuild only when query parameters change, not on every coordinator update.
///
/// **Example usage:**
/// ```dart
/// class ProductListRoute extends RouteTarget
///     with RouteUnique, RouteQueryParameter {
///   @override
///   final ValueNotifier<Map<String, String>> queryNotifier =
///       ValueNotifier({});
///
///   void setPage(int page, AppCoordinator coordinator) {
///     updateQueries(coordinator, queries: {'page': '$page'});
///   }
/// }
///
/// // In build method, use ValueListenableBuilder for targeted rebuilds:
/// ValueListenableBuilder(
///   valueListenable: queryNotifier,
///   builder: (context, queries, child) => Text('Page: ${queries['page']}'),
/// )
/// ```
///
/// **Note:** Query parameters are intentionally excluded from [RouteTarget.props]
/// so that changing queries does not affect route identity. This allows updating
/// the URL without triggering navigation transitions.
mixin RouteQueryParameters on RouteUnique {
  /// ValueNotifier for query parameters.
  ///
  /// Use this with [ValueListenableBuilder] to rebuild widgets only when
  /// queries change, rather than listening to the entire coordinator.
  ValueNotifier<Map<String, String>> get queryNotifier;

  /// Current query parameters.
  Map<String, String> get queries => queryNotifier.value;

  /// Sets new query parameters.
  set queries(Map<String, String> value) => queryNotifier.value = value;

  /// Get a query parameter by name.
  ///
  /// Returns null if the parameter is not present.
  String? query(String name) => queries[name];

  Widget selectorBuilder<T>({
    required T Function(Map<String, String> queries) selector,
    required Widget Function(BuildContext context, T value) builder,
  }) => _QuerySelectorBuilder<T>(
    notifier: queryNotifier,
    selector: selector,
    builder: builder,
  );

  /// Updates the query parameters and notifies listeners.
  ///
  /// This updates both:
  /// - [queryNotifier] for widget rebuilds (targeted)
  /// - [coordinator] for URL sync
  ///
  /// **Example:**
  /// ```dart
  /// // Replace all queries
  /// updateQueries(coordinator, queries: {'page': '2', 'sort': 'asc'});
  ///
  /// // Add/modify a single query while keeping others
  /// updateQueries(coordinator, queries: {...queries, 'filter': 'active'});
  /// ```
  void updateQueries(
    covariant Coordinator coordinator, {
    required Map<String, String> queries,
  }) {
    queryNotifier.value = queries;
    // If current route is not active, navigate to it
    if (coordinator.activePath.activeRoute != this) {
      coordinator.navigate(this);
    }
    coordinator.markNeedRebuild(); // Sync browser URL
  }

  @override
  void onDidPop(
    Object? result,
    covariant Coordinator<RouteUnique>? coordinator,
  ) {
    super.onDidPop(result, coordinator);
    queryNotifier.dispose();
  }
}

class _QuerySelectorBuilder<T> extends StatefulWidget {
  const _QuerySelectorBuilder({
    required this.notifier,
    required this.selector,
    required this.builder,
  });

  final ValueNotifier<Map<String, String>> notifier;
  final T Function(Map<String, String>) selector;
  final Widget Function(BuildContext, T) builder;

  @override
  State<_QuerySelectorBuilder<T>> createState() =>
      _QuerySelectorBuilderState<T>();
}

class _QuerySelectorBuilderState<T> extends State<_QuerySelectorBuilder<T>> {
  late T _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.notifier.value);
    widget.notifier.addListener(_onNotifierChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onNotifierChanged);
    super.dispose();
  }

  void _onNotifierChanged() {
    final newValue = widget.selector(widget.notifier.value);
    if (newValue != _selectedValue) {
      setState(() => _selectedValue = newValue);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _selectedValue);
}
