import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:dartnative/plugin.dart';

import 'sheet_lifecycle.dart';

/// Owns DevTools' native sheet independently of Navigator's presentation stacks.
///
/// A separate reconciler keeps the sheet mounted when its opening route is
/// removed. Closing targets its native root ID; router pops target app routes.
final class DevToolsSheetHost implements DevToolsSheetSession {
  DevToolsSheetHost(BuildContext context)
    : _media = MediaQuery.of(context),
      _bindings = (context as Element).reconciler.bindings;

  final MediaQueryData _media;
  final NativeBindings _bindings;
  late final DartNativeReconciler _reconciler = DartNativeReconciler(_bindings);
  final _closed = Completer<void>();
  int? _rootId;
  bool _closing = false;
  bool _rootAttached = false;

  @override
  Future<void> get closed => _closed.future;

  void show({required Widget child, required Brightness brightness}) {
    if (_rootId != null || _closed.isCompleted) {
      throw StateError('A DevTools sheet host can only be presented once.');
    }
    final android = Platform.isAndroid;
    // showModalSheet registers in Navigator's global sheet stack, which would
    // intercept the router's programmatic pop. Own the same native primitive
    // directly so route actions cannot accidentally dismiss DevTools.
    // Let the native sheet choose its adaptive material and background.
    final rootId = _bindings.presentDartSheet(
      detent: SheetDetent.adaptive.index,
      prefersGrabber: true,
      headerTitle: android ? '' : 'ZenRouter',
      headerLeadingIcon: android ? '' : 'xmark',
      onHeaderTap: (_) => close(),
      onDismissed: _didDismiss,
    );
    if (rootId <= 0 || _closed.isCompleted) {
      dispose();
      throw StateError('Native DevTools sheet could not be presented.');
    }
    _rootId = rootId;
    _reconciler.rootViewId = rootId;
    _reconciler.onPopRoute = close;
    try {
      if (!android) {
        // UIUserInterfaceStyle: 1 = light, 2 = dark.
        _bindings.setViewInterfaceStyle(
          rootId,
          brightness == Brightness.dark ? 2 : 1,
        );
      }
      _rootAttached = true;
      _reconciler.attachRoot(
        android
            ? MediaQuery(
                data: _media.copyWith(platformBrightness: brightness),
                child: SizedBox.expand(child: child),
              )
            : child,
      );
      _reconciler.flushMutationsNow();
    } catch (_) {
      close();
      rethrow;
    }
  }

  @override
  void close() {
    final rootId = _rootId;
    if (_closing || _closed.isCompleted || rootId == null) return;
    _closing = true;
    try {
      _bindings.dismissDartSheet(rootId);
    } catch (error, stack) {
      // An externally dismissed sheet may already have lost its native root.
      dnLog('ZenRouter DevTools sheet close failed: $error\n$stack');
      dispose();
    }
  }

  void _didDismiss() => dispose();

  @override
  void dispose() {
    if (_closed.isCompleted) return;
    try {
      if (_rootAttached) {
        _rootAttached = false;
        _reconciler.detachRoot();
        _reconciler.flushMutationsNow();
      }
    } catch (error, stack) {
      dnLog('ZenRouter DevTools sheet cleanup failed: $error\n$stack');
    } finally {
      _closed.complete();
    }
  }
}
