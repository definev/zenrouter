import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import 'coordinator.dart';
import 'route.dart';
import 'session.dart';

/// Mount once for the app's lifetime, below App or directly inside runApp.
///
/// This host exclusively owns the ordered DartNative presentation stack. Do
/// not mix raw Navigator calls, native hot-restart replay, nested hosts, or
/// unmanaged overlays with coordinator navigation.
/// The caller owns/disposes [coordinator]. A failed native command stops the
/// session and reports through [onError]; restart the app to recover.
class CoordinatorView<T extends RouteUnique> extends StatefulWidget {
  const CoordinatorView({
    super.key,
    required this.coordinator,
    required this.onError,
    this.onExitRequested,
    this.presentationBuilder,
    this.confirmationTimeout = const Duration(seconds: 10),
  });

  final Coordinator<T> coordinator;
  final void Function(Object error, StackTrace stackTrace) onError;

  /// Invoked for Android root back after a root guard allows exit. Defaults to
  /// SystemNavigator.pop (backgrounds Android; no-op on iOS).
  final void Function()? onExitRequested;

  /// Decorates every native presentation's content, including pushed screens.
  /// Useful for debug UI that must remain visible across route pushes. The
  /// builder must keep [child] mounted for the presentation's lifetime.
  final Widget Function(BuildContext context, Widget child)?
  presentationBuilder;

  /// Failure deadline, not an animation duration or a scheduling delay.
  final Duration confirmationTimeout;

  @override
  State<CoordinatorView<T>> createState() => _CoordinatorViewState<T>();
}

/// Installed separately in every native presentation's widget tree.
class CoordinatorScope extends InheritedWidget {
  const CoordinatorScope({
    super.key,
    required this.coordinator,
    required super.child,
  });

  final Coordinator coordinator;

  static Coordinator<T> of<T extends RouteUri>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CoordinatorScope>();
    if (scope == null) throw StateError('No CoordinatorScope in this screen.');
    return scope.coordinator as Coordinator<T>;
  }

  @override
  bool updateShouldNotify(CoordinatorScope oldWidget) =>
      !identical(coordinator, oldWidget.coordinator);
}

Object? _activeHost;

class _CoordinatorViewState<T extends RouteUnique>
    extends State<CoordinatorView<T>> {
  final _token = Object();
  late final _NavigatorDriver<T> _driver;
  late final NavigationSession<T> _session;
  _PresentationRecord<T>? _root;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.coordinator.isRouteModule) {
      throw StateError('Mount CoordinatorView with the root coordinator.');
    }
    if (_activeHost != null) {
      throw StateError('Only one CoordinatorView may own the native stack.');
    }
    _activeHost = _token;
    _driver = _NavigatorDriver(this);
    _session = NavigationSession(
      coordinator: widget.coordinator,
      driver: _driver,
      onError: widget.onError,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _session.start();
    });
  }

  @override
  void didUpdateWidget(CoordinatorView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.coordinator, widget.coordinator)) {
      throw StateError(
        'CoordinatorView.coordinator cannot change after mount.',
      );
    }
  }

  Future<void> requestBack(
    _PresentationRecord<T> presentation,
    Object? result,
  ) async {
    try {
      if (!mounted || _session.failure != null) return;
      if (!presentation.isRoot) {
        await _session.requestPop(presentation.entry, result);
        return;
      }
      if (_exiting || widget.coordinator.root.stack.length != 1) return;
      _exiting = true;
      try {
        final route = presentation.entry.route;
        final guard = route is RouteGuard ? route as RouteGuard : null;
        if (!identical(widget.coordinator.root.activeRoute, route)) return;
        if (guard != null &&
            !guard.canPopWith(widget.coordinator) &&
            !await guard.popGuardWith(widget.coordinator)) {
          return;
        }
        if (mounted &&
            widget.coordinator.root.stack.length == 1 &&
            identical(widget.coordinator.root.activeRoute, route)) {
          (widget.onExitRequested ?? SystemNavigator.pop)();
        }
      } finally {
        _exiting = false;
      }
    } catch (error, stackTrace) {
      if (mounted) widget.onError(error, stackTrace);
    }
  }

  Widget presentationWidget(_PresentationRecord<T> presentation) =>
      _RouteContent<T>(
        key: ValueKey(presentation.entry.token),
        presentation: presentation,
        coordinator: widget.coordinator,
        presentationBuilder: widget.presentationBuilder,
        onBack: (result) => unawaited(requestBack(presentation, result)),
      );

  @override
  Widget build(BuildContext context) =>
      _root == null ? const SizedBox.shrink() : presentationWidget(_root!);

  @override
  void dispose() {
    _session.dispose();
    _driver.dispose();
    if (identical(_activeHost, _token)) _activeHost = null;
    super.dispose();
  }
}

class _PresentationRecord<T extends RouteUnique> {
  _PresentationRecord(this.entry, {this.isRoot = false});
  final NavigationEntry<T> entry;
  final bool isRoot;
  final mounted = Completer<void>();
  final removed = Completer<void>();
  final allowProgrammaticPop = ValueNotifier(false);
  PresentationHandle? handle;
  void Function(Object? result)? onDismissed;
  bool didReportDismissal = false;
  Object? requestedResult;

  void reportDismissed(Object? result) {
    if (didReportDismissal) return;
    didReportDismissal = true;
    if (!removed.isCompleted) removed.complete();
    onDismissed?.call(result);
  }
}

class _NavigatorDriver<T extends RouteUnique> implements PresentationDriver<T> {
  _NavigatorDriver(this.host);
  final _CoordinatorViewState<T> host;
  final _presentations = <Object, _PresentationRecord<T>>{};
  bool _disposed = false;
  bool _checkedInitialStack = false;

  Duration get timeout => host.widget.confirmationTimeout;

  @override
  Future<void> mountRoot(NavigationEntry<T> entry) async {
    _checkMounted();
    if (!_checkedInitialStack) {
      _checkedInitialStack = true;
      if (Navigator.canPop(host.context)) {
        throw StateError(
          'Existing native routes/replay cannot be adopted. '
          'Cold-start the app without registerRoutes for managed screens.',
        );
      }
    }
    final presentation = _PresentationRecord(entry, isRoot: true);
    host.setState(() => host._root = presentation);
    await presentation.mounted.future.timeout(timeout);
  }

  @override
  Future<void> present(
    NavigationEntry<T> entry,
    void Function(Object? result) onDismissed,
  ) async {
    _checkMounted();
    final record = _PresentationRecord(entry);
    _presentations[entry.token] = record;
    record.onDismissed = (value) {
      _presentations.remove(entry.token);
      if (!_disposed) onDismissed(value);
    };
    try {
      record.handle = entry.route.presentation.present(
        PresentationContext(
          hostContext: host.context,
          builder: (_) => host.presentationWidget(record),
          route: entry.route,
          entryToken: entry.token,
        ),
      );
    } catch (_) {
      _presentations.remove(entry.token);
      rethrow;
    }
    final result = record.handle!.result;
    unawaited(
      result.then(
        (value) {
          record.reportDismissed(value);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!record.removed.isCompleted) {
            // Observe through the session even when nobody awaits a result.
            record.removed.complete();
          }
          if (!_disposed) host._session.reportFailure(error, stackTrace);
        },
      ),
    );
    // Some platform-specific adapters legitimately dismiss before building
    // (e.g. an unsupported keyboard overlay). That is a removal, not a mount
    // timeout or a reason to resurrect the logical route.
    await Future.any([
      record.mounted.future,
      record.removed.future,
    ]).timeout(timeout);
  }

  @override
  Future<void> dismiss(NavigationEntry<T> entry, Object? result) async {
    _checkMounted();
    final record = _presentations[entry.token];
    if (record == null) {
      throw StateError('Native presentation is no longer tracked.');
    }
    // The logical guard already ran. Update our PopScope before issuing the
    // authorized pop. A nested application PopScope may still veto it; timeout
    // reports the resulting desynchronization rather than popping another page.
    record.allowProgrammaticPop.value = true;
    record.requestedResult = result;
    await _afterBuild().timeout(timeout);
    _checkMounted();
    if (!record.removed.isCompleted) record.handle!.dismiss(result);
    await record.removed.future.timeout(timeout);
  }

  Future<void> _afterBuild() {
    final done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => done.complete());
    return done.future;
  }

  void _checkMounted() {
    if (_disposed || !host.mounted)
      throw StateError('Native host was disposed.');
  }

  void dispose() {
    _disposed = true;
    _presentations.clear();
  }
}

class _RouteContent<T extends RouteUnique> extends StatefulWidget {
  const _RouteContent({
    super.key,
    required this.presentation,
    required this.coordinator,
    required this.presentationBuilder,
    required this.onBack,
  });
  final _PresentationRecord<T> presentation;
  final Coordinator<T> coordinator;
  final Widget Function(BuildContext context, Widget child)?
  presentationBuilder;
  final void Function(Object?) onBack;

  @override
  State<_RouteContent<T>> createState() => _RouteContentState<T>();
}

class _RouteContentState<T extends RouteUnique>
    extends State<_RouteContent<T>> {
  ListenableMixin? _guardChanges;

  @override
  void initState() {
    super.initState();
    widget.presentation.allowProgrammaticPop.addListener(_changed);
    final route = widget.presentation.entry.route;
    if (route is RouteGuard) {
      _guardChanges = (route as RouteGuard).canPopListenableWith(
        widget.coordinator,
      );
      _guardChanges?.addListener(_changed);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.presentation.mounted.isCompleted) {
        widget.presentation.mounted.complete();
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    final route = presentation.entry.route;
    final guard = route is RouteGuard ? route as RouteGuard : null;
    final canPop =
        !presentation.isRoot &&
        (presentation.allowProgrammaticPop.value ||
            guard == null ||
            guard.canPopWith(widget.coordinator));
    return CoordinatorScope(
      coordinator: widget.coordinator,
      child: PopScope(
        canPop: canPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            // Some DartNative presentation primitives report physical system
            // dismissal here without completing their returned result Future.
            // The record merges both signals into one dismissal event.
            presentation.reportDismissed(result);
          } else {
            widget.onBack(result);
          }
        },
        child: Builder(
          builder: (context) {
            final content = route.build(widget.coordinator, context);
            return widget.presentationBuilder?.call(context, content) ??
                content;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // A native detent sheet can disappear through its system grabber without
    // completing the returned Future or invoking PopScope. Subtree disposal is
    // the final public lifecycle signal shared by every presentation adapter.
    if (!widget.presentation.isRoot) {
      widget.presentation.reportDismissed(widget.presentation.requestedResult);
    }
    _guardChanges?.removeListener(_changed);
    widget.presentation.allowProgrammaticPop.removeListener(_changed);
    widget.presentation.allowProgrammaticPop.dispose();
    super.dispose();
  }
}
