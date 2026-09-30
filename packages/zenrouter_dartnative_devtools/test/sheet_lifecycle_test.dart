import 'dart:async';

import 'package:test/test.dart';
import 'package:zenrouter_dartnative_devtools/src/sheet_lifecycle.dart';

final class _Sheet implements DevToolsSheetSession {
  final completion = Completer<void>();
  final closeRequested = Completer<void>();
  int closeCalls = 0;
  bool disposed = false;

  @override
  Future<void> get closed => completion.future;

  @override
  void close() {
    closeCalls++;
    if (!closeRequested.isCompleted) closeRequested.complete();
  }

  void nativeDismissed() {
    if (!completion.isCompleted) completion.complete();
  }

  @override
  void dispose() {
    disposed = true;
    nativeDismissed();
  }
}

void main() {
  test('reopens after a missing native dismissal callback', () async {
    final lifecycle = DevToolsSheetLifecycle(
      dismissalTimeout: const Duration(milliseconds: 1),
    );
    final old = _Sheet();
    final replacement = _Sheet();
    await lifecycle.open(() => old);

    await lifecycle.open(() => replacement);

    expect(old.closeCalls, 1);
    expect(old.disposed, isTrue);
    expect(replacement.closeCalls, 0);
    expect(replacement.disposed, isFalse);
    replacement.nativeDismissed();
    lifecycle.dispose();
  });

  test('presentation failure releases the opening lock', () async {
    final lifecycle = DevToolsSheetLifecycle();
    await expectLater(
      lifecycle.open(() => throw StateError('No native root')),
      throwsStateError,
    );
    final replacement = _Sheet();
    var presented = false;
    await lifecycle.open(() {
      presented = true;
      return replacement;
    });
    expect(presented, isTrue);
    replacement.nativeDismissed();
    lifecycle.dispose();
  });

  test('coalesces taps while the previous sheet is closing', () async {
    final lifecycle = DevToolsSheetLifecycle();
    final old = _Sheet();
    final replacement = _Sheet();
    await lifecycle.open(() => old);
    var presentations = 0;
    final reopening = lifecycle.open(() {
      presentations++;
      return replacement;
    });
    await old.closeRequested.future;
    await lifecycle.open(() {
      presentations++;
      return _Sheet();
    });
    old.nativeDismissed();
    await reopening;

    expect(presentations, 1);
    replacement.nativeDismissed();
    lifecycle.dispose();
  });

  test('old completion cannot release a newly presented sheet', () async {
    final lifecycle = DevToolsSheetLifecycle();
    final old = _Sheet();
    final replacement = _Sheet();
    await lifecycle.open(() => old);
    final reopening = lifecycle.open(() => replacement);
    await old.closeRequested.future;
    old.nativeDismissed();
    await reopening;
    old.nativeDismissed();
    await Future<void>.delayed(Duration.zero);

    final third = _Sheet();
    final nextOpening = lifecycle.open(() => third);
    await replacement.closeRequested.future;
    expect(replacement.closeCalls, 1);
    replacement.nativeDismissed();
    await nextOpening;
    third.nativeDismissed();
    lifecycle.dispose();
  });

  test('disposing during reopening prevents a new native sheet', () async {
    final lifecycle = DevToolsSheetLifecycle();
    final old = _Sheet();
    await lifecycle.open(() => old);
    var presentations = 0;
    final reopening = lifecycle.open(() {
      presentations++;
      return _Sheet();
    });
    await old.closeRequested.future;
    lifecycle.dispose();
    old.nativeDismissed();
    await reopening;
    expect(presentations, 0);
  });
}
