import 'package:flutter/material.dart';
import 'package:zenrouter/src/coordinator/layout.dart';
import 'package:zenrouter/zenrouter.dart';

/// Headless coordinator host: builds [coordinator.layoutBuilder] without a
/// root [Router].
///
/// [initialUri] is applied **once per empty coordinator**: when the root
/// [NavigationPath] has no routes yet, the URI is parsed and navigation runs.
/// If the coordinator already has stack state (user navigated, or this is the
/// same instance after a widget remount), [initialUri] is ignored so the
/// embed does not reset navigation.
class CoordinatorView<T extends RouteUri> extends StatefulWidget {
  const CoordinatorView({
    super.key,
    this.initialUri,
    required this.coordinator,
  });

  /// When non-null and [coordinator] still has an empty [Coordinator.root]
  /// stack, parsed with [Coordinator.parseRouteFromUri] and passed to
  /// [Coordinator.navigate].
  final Uri? initialUri;

  /// The coordinator to build the layout for.
  final CoordinatorLayoutBuilder<T> coordinator;

  @override
  State<CoordinatorView<T>> createState() => _CoordinatorViewState<T>();
}

class _CoordinatorViewState<T extends RouteUri>
    extends State<CoordinatorView<T>> {
  void _initializeCoordinatorIfNeeded() async {
    if (widget.initialUri == null) return;
    if (widget.coordinator.root.stack.isNotEmpty) return;

    final route = await widget.coordinator.parseRouteFromUri(
      widget.initialUri!,
    );
    if (route == null) return;
    await widget.coordinator.navigate(route);
    // coverage:ignore-start
    if (mounted) setState(() {});
    // coverage:ignore-end
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initializeCoordinatorIfNeeded(),
    );
  }

  @override
  void didUpdateWidget(covariant CoordinatorView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final coordinatorChanged = widget.coordinator != oldWidget.coordinator;
    final initialUriChanged = widget.initialUri != oldWidget.initialUri;
    if (coordinatorChanged || initialUriChanged) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _initializeCoordinatorIfNeeded(),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.coordinator.layoutBuilder(context);
}
