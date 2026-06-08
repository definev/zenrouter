import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/zenrouter_chat_ui.dart';

/// The root layout for a slot-based chat screen.
///
/// [ChatShell] renders four independent [ChatSlot]s in a z-ordered [Stack]:
///
/// ```
/// ┌────────────────────────────────────┐  ← NavigatorResizable top-bar slot
/// │ topBarSlot  (variable height)      │    Height animates as routes swap.
/// ├────────────────────────────────────┤  ← pinned slot via LayerLink follower
/// │ pinnedSlot  (hidden when empty)    │    Tracks top-bar's bottom edge.
/// ├────────────────────────────────────┤
/// │                                    │
/// │   bodySlot (full-screen, z=0)      │  ← Navigator-backed, animated push/pop
/// │                                    │
/// ├────────────────────────────────────┤
/// │ bottomSlot                         │  ← content-sized SlotBarView
/// └────────────────────────────────────┘
/// ```
///
/// ## Top-bar slot — NavigatorResizable
///
/// The top-bar [ChatSlot] is rendered through a [NavigatorResizable]-wrapped
/// [NavigationStack]. Pages use [ChatStackTransition.verticalSlide] so the
/// bar animates its height smoothly when routes swap (e.g. default header →
/// selection header → search field).
///
/// ## Pinned slot
///
/// `targetAnchor: Alignment.bottomLeft` so it automatically tracks the bottom
/// edge of the top bar — including during the [NavigatorResizable] resize
/// animation — without any polling or manual height measurement for positioning.
///
/// ## ChatMetrics
///
/// [ChatMetrics] is provided to all descendants so body routes can read
/// `ChatMetrics.of(context).topInset` / `.bottomInset` and pad their scroll
/// views accordingly. Heights are tracked by [MeasuredBar] callbacks.
///
/// ## Minimal usage
///
/// Back the shell with a [ChatShellCoordinator] and hand it to [ChatShell]:
///
/// ```dart
/// class MyChatShell extends ChatShellCoordinator<MyChatRoute> {
///   @override
///   MyChatRoute parseRouteFromUri(Uri uri) => MessageListBody();
/// }
///
/// // Rendered for you by ChatShellRouteLayout, or directly:
/// ChatShell<MyChatRoute>(shell: myChatShell);
/// ```
///
/// See [ChatShellRoute] / [ChatShellRouteLayout] for wiring the shell into an
/// outer [Coordinator] through `parseRouteFromUri`.
class ChatShell<T extends RouteUnique> extends StatefulWidget {
  const ChatShell({super.key, required this.shell});

  final ChatShellCoordinator<T> shell;

  @override
  State<ChatShell<T>> createState() => _ChatShellState<T>();
}

class _ChatShellState<T extends RouteUnique> extends State<ChatShell<T>> {
  final _metrics = ChatShellMetricsNotifier();

  ChatShellCoordinator<T> get _shell => widget.shell;

  // ── resolvers ───────────────────────────────────────────────────────────────

  /// Body slot resolver: material or cupertino depending on route mixin,
  /// or a user-supplied override.
  StackTransitionResolver<T> get _bodyResolver {
    final coordinator = widget.shell;
    final slot = coordinator.bodySlot;
    return (route) => switch (route) {
      RouteTransition() => route.transition(coordinator),
      _ => StackTransition.none(
        Builder(builder: (c) => route.build(coordinator, c)),
        restorationId: slot.routeRestorationId(coordinator, route),
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
                  path: _shell.bodySlot,
                  coordinator: widget.shell,
                  restorationId: _shell.bodySlot.stackRestorationId(
                    widget.shell,
                  ),
                  resolver: _bodyResolver,
                ),
              ),

              Align(
                alignment: .topCenter,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    // ── TOP BAR — NavigatorResizable, height animates on swap ─────
                    //
                    // CompositedTransformTarget establishes the LayerLink leader that
                    // the pinned-slot follower tracks.
                    SlotBarView<T>(
                      onSize: _metrics.updateTopBar,
                      slot: _shell.topBarSlot,
                      coordinator: widget.shell,
                      slideDirections: VerticalSlideDirections.fromTop,
                    ),

                    // ── PINNED SLOT — LayerLink follower, tracks top-bar bottom ───
                    //
                    // No Positioned wrapper — CompositedTransformFollower positions
                    // itself relative to the CompositedTransformTarget above, placing
                    // its top-left at the top-bar's bottom-left edge (including
                    // during NavigatorResizable resize animations).
                    //
                    // showWhenUnlinked: false ensures it hides before the top bar has
                    // been laid out in the first frame.
                    IntrinsicHeight(
                      child: SlotBarView<T>(
                        onSize: _metrics.updatePinned,
                        slot: _shell.pinnedSlot,
                        coordinator: widget.shell,
                      ),
                    ),
                  ],
                ),
              ),

              // ── BOTTOM BAR — content-sized, floats at bottom ──────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SlotBarView<T>(
                      onSize: _metrics.updateBottom,
                      slot: _shell.bottomSlot,
                      coordinator: widget.shell,
                      slideDirections: VerticalSlideDirections.chatBar,
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
