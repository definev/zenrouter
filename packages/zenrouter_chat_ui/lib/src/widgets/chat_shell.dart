import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/src/coordinator/chat_coordinator_mixin.dart';
import 'package:zenrouter_chat_ui/src/widgets/chat_metrics.dart';
import 'package:zenrouter_chat_ui/src/widgets/slot_bar_view.dart';

/// The root layout for a slot-based chat screen.
///
/// [ChatShell] renders four independent [ChatSlot]s in a z-ordered [Stack]:
///
/// ```
/// ┌────────────────────────────────────┐  ← floating top bar (SafeArea top)
/// │ topBarSlot                         │
/// ├────────────────────────────────────┤  ← optional pinned banner
/// │ pinnedSlot  (hidden when empty)    │
/// ├────────────────────────────────────┤
/// │                                    │
/// │   bodySlot (full-screen, z=0)      │  ← Navigator-backed, animated push/pop
/// │                                    │
/// ├────────────────────────────────────┤  ← floating bottom bar (SafeArea bottom)
/// │ bottomSlot                         │
/// └────────────────────────────────────┘
/// ```
///
/// [ChatMetrics] is provided to all descendants so body routes can read
/// `ChatMetrics.of(context).topInset` / `.bottomInset` and pad their scroll
/// views accordingly.
///
/// ## Minimal usage
///
/// Your coordinator must mix [ChatCoordinatorMixin]. Seed the slots once, then
/// hand the coordinator to [ChatShell]:
///
/// ```dart
/// class MyChatCoordinator extends Coordinator<MyChatRoute>
///     with ChatCoordinatorMixin<MyChatRoute> {
///   MyChatCoordinator() {
///     topBarSlot.swap(DefaultTopBar());
///     bottomSlot.swap(ComposerBar());
///     bodySlot.swap(MessageListBody());
///     // pinnedSlot left empty — renders nothing until filled
///   }
///   @override MyChatRoute parseRouteFromUri(Uri uri) => ChatScreenRoute();
/// }
///
/// // In the shell route's build():
/// @override
/// Widget build(MyChatCoordinator coordinator, BuildContext context) =>
///     ChatShell(coordinator: coordinator);
/// ```
///
/// ## Custom body transitions
///
/// Supply [bodyTransition] to override the default material page animation:
///
/// ```dart
/// ChatShell(
///   coordinator: coordinator,
///   bodyTransition: (route) => StackTransition.cupertino(
///     Builder(builder: (c) => route.build(coordinator, c)),
///   ),
/// )
/// ```
class ChatShell<T extends RouteUnique> extends StatefulWidget {
  const ChatShell({
    super.key,
    required this.coordinator,
    this.bodyTransition,
  });

  final Coordinator<T> coordinator;

  /// Optional resolver mapping body routes to their [StackTransition].
  ///
  /// Defaults to a material transition. Routes that mix [RouteTransition]
  /// supply their own transition via [RouteTransition.transition], which takes
  /// priority over this resolver.
  final StackTransitionResolver<T>? bodyTransition;

  @override
  State<ChatShell<T>> createState() => _ChatShellState<T>();
}

class _ChatShellState<T extends RouteUnique> extends State<ChatShell<T>> {
  final _metrics = ChatShellMetricsNotifier();

  ChatCoordinatorMixin<T> get _chat =>
      widget.coordinator as ChatCoordinatorMixin<T>;

  StackTransitionResolver<T> get _resolver {
    final custom = widget.bodyTransition;
    if (custom != null) return custom;
    final coordinator = widget.coordinator;
    return (route) => switch (route) {
      RouteTransition() => route.transition(coordinator),
      _ => StackTransition.material(
          Builder(builder: (c) => route.build(coordinator, c)),
        ),
    };
  }

  @override
  void dispose() {
    _metrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _metrics,
      builder: (context, _) {
        return ChatMetrics(
          topInset: _metrics.topInset,
          bottomInset: _metrics.bottomInset,
          child: Stack(
            children: [
              // ── BODY — full-screen, bottom of z-order ─────────────────────
              Positioned.fill(
                child: NavigationStack<T>(
                  path: _chat.bodySlot,
                  coordinator: widget.coordinator,
                  resolver: _resolver,
                ),
              ),

              // ── TOP BAR — floats at top, content-sized ────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MeasuredBar(
                  onSize: _metrics.updateTopBar,
                  child: SafeArea(
                    bottom: false,
                    child: SlotBarView<T>(
                      slot: _chat.topBarSlot,
                      coordinator: widget.coordinator,
                    ),
                  ),
                ),
              ),

              // ── PINNED — floats directly below the top bar ────────────────
              Positioned(
                top: _metrics.topBarHeight,
                left: 0,
                right: 0,
                child: MeasuredBar(
                  onSize: _metrics.updatePinned,
                  child: SlotBarView<T>(
                    slot: _chat.pinnedSlot,
                    coordinator: widget.coordinator,
                  ),
                ),
              ),

              // ── BOTTOM BAR — floats at bottom, content-sized ──────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MeasuredBar(
                  onSize: _metrics.updateBottom,
                  child: SafeArea(
                    top: false,
                    child: SlotBarView<T>(
                      slot: _chat.bottomSlot,
                      coordinator: widget.coordinator,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
