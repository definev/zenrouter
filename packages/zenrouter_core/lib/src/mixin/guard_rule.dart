import 'dart:async';

import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/src/mixin/guard.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

/// Base class for composable pop-guard logic.
///
/// Guard rules extract leave-confirmation logic from routes into reusable,
/// testable components. Rules are executed in order until one returns a
/// non-null result.
///
/// ## Role in Navigation Flow
///
/// When a [RouteGuardRule] route is about to be popped:
///
/// 1. [RouteGuard.popGuardWith] iterates through [RouteGuardRule.guardRules]
/// 2. Each rule's [guard] is called in sequence
/// 3. Based on the result:
///    - `null`: Next rule is processed
///    - `false`: Pop is blocked, stack unchanged
///    - `true`: Pop is allowed, chain stops
/// 4. If every rule returns `null`, the pop is allowed
///
/// Rules can be composed for complex scenarios: unsaved-changes prompts,
/// permission checks, logging, etc.
abstract class GuardRule<T extends RouteTarget> {
  const GuardRule();

  /// Sync hint for [RouteGuard.canPop].
  ///
  /// Return `false` to force `PopScope` interception. Default `true` means
  /// this rule does not require interception on its own.
  /// [RouteGuardRule.canPop] is `true` only when every rule returns `true`.
  bool canPop(covariant T route) => true;

  /// Optional [ListenableMixin] that invalidates [canPop] for [route].
  ListenableMixin? canPopListenable(covariant T route) => null;

  /// Determines whether the pop should proceed for [route].
  ///
  /// Return `null` to continue to the next rule.
  /// Return `true` to allow the pop (stops the chain).
  /// Return `false` to block the pop (stops the chain).
  FutureOr<bool?> guard(
    covariant CoordinatorCore coordinator,
    covariant T route,
  );
}

/// Mixin for routes that use a list of guard rules.
///
/// Routes with this mixin delegate their pop-guard logic to a list of
/// [GuardRule] instances, enabling composable and testable guard chains.
mixin RouteGuardRule<T extends RouteTarget> on RouteTarget
    implements RouteGuard {
  /// The list of rules applied to this route, in order.
  ///
  /// Rules are processed sequentially. The first non-null result wins.
  List<GuardRule> get guardRules;

  @override
  bool get canPop => guardRules.every((rule) => rule.canPop(this as T));

  @override
  ListenableMixin? get canPopListenable {
    final listenables = <ListenableMixin>[
      for (final rule in guardRules)
        if (rule.canPopListenable(this as T) case final listenable?)
          listenable,
    ];
    return switch (listenables) {
      [] => null,
      [final only] => only,
      final many => ListenableMixin.merge(many),
    };
  }

  // coverage:ignore-start
  @override
  FutureOr<bool> popGuard() => true;
  // coverage:ignore-end

  /// Implements [RouteGuard.popGuardWith] by running all rules in sequence.
  ///
  /// Processing stops when any rule returns a non-null [bool].
  /// If all rules return `null`, the pop is allowed.
  @override
  FutureOr<bool> popGuardWith(covariant CoordinatorCore coordinator) async {
    assert(stackPath?.coordinator == coordinator, '''
[RouteGuard] The path [${stackPath.toString()}] is associated with a different coordinator (or null) than the one currently handling the navigation.
Expected coordinator: $coordinator
Path's coordinator: ${stackPath?.coordinator}
Ensure that the path is created with the correct coordinator using `.createWith()` and that routes are being managed by the correct coordinator.
''');

    for (final rule in guardRules) {
      final result = await rule.guard(coordinator, this as T);
      if (result != null) return result;
    }
    return true;
  }
}
