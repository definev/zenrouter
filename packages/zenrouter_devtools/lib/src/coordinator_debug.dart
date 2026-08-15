import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

import 'debug_overlay.dart';
import 'graph/navigation_flow.dart';

/// Mixin to add debug capabilities to a [Coordinator].
///
/// This adds a floating debug button that opens an overlay showing:
/// - Current navigation stacks for all paths
/// - Declarative route and layout graph with the active URI flow highlighted
/// - Observed route-to-route transitions recorded from navigation commits
/// - Ability to push routes by URI
/// - Ability to push pre-defined debug routes
///
/// ## Usage
///
/// ```dart
/// class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug<AppRoute> {
///   @override
///   bool get debugEnabled => kDebugMode;
///
///   @override
///   List<AppRoute> get debugRoutes => [
///     AppRoute.home(),
///     AppRoute.settings(),
///     AppRoute.profile(userId: 'test'),
///   ];
///
///   @override
///   String debugLabel(StackPath path) {
///     // Return human-readable labels for paths
///     return path.toString();
///   }
/// }
/// ```
mixin CoordinatorDebug<T extends RouteUnique> on Coordinator<T> {
  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  /// Toggle debug overlay visibility.
  ///
  /// Defaults to `kDebugMode`. Override this to conditionally enable/disable
  /// the debug overlay (e.g., only in debug mode).
  bool get debugEnabled => kDebugMode;

  /// Override this to provide a list of routes that can be quickly pushed
  /// from the debug overlay.
  ///
  /// This is useful for testing specific screens or flows without navigating
  /// through the app manually.
  List<T> get debugRoutes => [];

  /// Override this to provide a custom label for a navigation path.
  ///
  /// By default, it returns `path.toString()`. You can override this to
  /// provide more human-readable names for your paths in the debug overlay.
  String debugLabel(StackPath path) => path.debugLabel ?? path.toString();

  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _debugOverlayOpen = false;
  NavigationFlowRecorder<Object>? _debugNavigationFlow;
  bool _debugNavigationFlowAttached = false;
  String? _debugFlowActionLabel;

  /// Whether the debug overlay is currently open.
  bool get debugOverlayOpen => _debugOverlayOpen;

  /// Runtime route transitions observed after the debug UI is attached.
  ///
  /// The recorder is created lazily and seeded with the current route. It
  /// deduplicates coordinator notifications by navigation commit revision.
  NavigationFlowRecorder<Object> get debugNavigationFlow {
    final recorder =
        _debugNavigationFlow ??= NavigationFlowRecorder<Object>(
          manifest: routeManifest,
          initialUri: currentUri,
          initialRevision: lastNavigationCommit?.revision ?? -1,
        );
    if (!_debugNavigationFlowAttached) {
      addListener(_recordDebugNavigationCommit);
      _debugNavigationFlowAttached = true;
    }
    return recorder;
  }

  /// Returns the number of "problems" or items that need attention.
  ///
  /// Currently, this counts the number of [debugRoutes] that fail to convert
  /// to a URI (i.e., [toUri] throws an exception). This helps identify
  /// routes that might be missing proper URI generation logic.
  int get problems =>
      debugRoutes.where((r) {
        try {
          r.toUri();
          return false;
        } catch (_) {
          return true;
        }
      }).length;

  // ===========================================================================
  // METHODS
  // ===========================================================================

  /// Toggles the visibility of the debug overlay.
  ///
  /// This method notifies listeners, which triggers a rebuild of the
  /// [layoutBuilder] to show or hide the overlay.
  void toggleDebugOverlay() {
    _debugOverlayOpen = !_debugOverlayOpen;
    notifyListeners();
  }

  /// Runs [action] while attaching a human-readable cause to its next commit.
  ///
  /// Recording works without annotations. Use this helper when the graph
  /// should say `Open profile` instead of the inferred history intent.
  Future<R> debugFlowAction<R>(
    String label,
    FutureOr<R> Function() action,
  ) async {
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be empty');
    }
    final normalizedLabel = label.trim();
    final previousLabel = _debugFlowActionLabel;
    _debugFlowActionLabel = normalizedLabel;
    try {
      return await action();
    } finally {
      if (_debugFlowActionLabel == normalizedLabel) {
        _debugFlowActionLabel = previousLabel;
      }
    }
  }

  /// Clears the observed flow and seeds it at the current route.
  void clearDebugNavigationFlow() {
    debugNavigationFlow.clear(initialUri: currentUri);
  }

  void _recordDebugNavigationCommit() {
    final commit = lastNavigationCommit;
    if (commit == null) return;
    final recorder = _debugNavigationFlow;
    if (recorder == null || commit.revision <= recorder.lastRecordedRevision) {
      return;
    }
    final actionLabel = _debugFlowActionLabel;
    _debugFlowActionLabel = null;
    recorder.record(commit, actionLabel: actionLabel);
  }

  @override
  void dispose() {
    if (_debugNavigationFlowAttached) {
      removeListener(_recordDebugNavigationCommit);
    }
    _debugNavigationFlow?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LAYOUT BUILDER OVERRIDE
  // ===========================================================================

  @override
  /// Wraps the application layout with the debug overlay.
  ///
  /// If [debugEnabled] is `false`, it simply returns the result of
  /// `super.layoutBuilder(context)`. Otherwise, it wraps the layout with
  /// a [ToastProvider] and an [Overlay] containing the [DebugOverlay].
  Widget layoutBuilder(BuildContext context) {
    if (!debugEnabled) return super.layoutBuilder(context);
    debugNavigationFlow;

    return Stack(
      children: [
        Builder(builder: (context) => super.layoutBuilder(context)),
        Overlay(
          initialEntries: [
            OverlayEntry(
              builder:
                  (context) => MediaQuery.fromView(
                    view: View.of(context),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Inter',
                        height: 1.4,
                        decoration: TextDecoration.none,
                      ),
                      child: Builder(
                        builder: (context) {
                          final viewInsets = MediaQuery.viewInsetsOf(context);
                          final viewPadding = MediaQuery.viewPaddingOf(context);
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: switch (viewInsets.bottom) {
                                > 0 => viewInsets.bottom,
                                _ => viewPadding.bottom,
                              },
                            ),
                            child: DebugOverlay(coordinator: this),
                          );
                        },
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
