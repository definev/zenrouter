import 'package:flutter/material.dart';
import 'package:navigator_resizable/navigator_resizable.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/src/coordinator/chat_coordinator_mixin.dart';
import 'package:zenrouter_chat_ui/src/widgets/chat_metrics.dart';
import 'package:zenrouter_chat_ui/src/widgets/slot_bar_view.dart';

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
/// [NavigationStack]. Pages are created with [ResizableMaterialPage] so the
/// bar animates its height smoothly when routes swap (e.g. default header →
/// selection header → search field).
///
/// ## Pinned slot — LayerLink
///
/// A [CompositedTransformTarget] wraps the top-bar container. The pinned slot
/// is rendered inside a [CompositedTransformFollower] with
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
/// ```dart
/// class MyChatCoordinator extends Coordinator<MyChatRoute>
///     with ChatCoordinatorMixin<MyChatRoute> {
///   MyChatCoordinator() {
///     topBarSlot.swap(DefaultTopBar());
///     bottomSlot.swap(ComposerBar());
///     bodySlot.swap(MessageListBody());
///   }
///   @override MyChatRoute parseRouteFromUri(Uri uri) => ChatShellRoute();
/// }
///
/// // In the shell route's build():
/// @override
/// Widget build(MyChatCoordinator coordinator, BuildContext context) =>
///     ChatShell(coordinator: coordinator);
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
  /// Defaults to a material transition. Routes mixing [RouteTransition] supply
  /// their own transition and take priority over this resolver.
  final StackTransitionResolver<T>? bodyTransition;

  @override
  State<ChatShell<T>> createState() => _ChatShellState<T>();
}

class _ChatShellState<T extends RouteUnique> extends State<ChatShell<T>> {
  final _metrics = ChatShellMetricsNotifier();

  /// [LayerLink] connecting the top-bar [CompositedTransformTarget] to the
  /// pinned-slot [CompositedTransformFollower].
  final _topBarLayerLink = LayerLink();

  ChatCoordinatorMixin<T> get _chat =>
      widget.coordinator as ChatCoordinatorMixin<T>;

  // ── resolvers ───────────────────────────────────────────────────────────────

  /// Body slot resolver: material or cupertino depending on route mixin,
  /// or a user-supplied override.
  StackTransitionResolver<T> get _bodyResolver {
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

  /// Top-bar slot resolver: always uses [ResizableMaterialPage] so
  /// [NavigatorResizable] can animate the bar's height during route transitions.
  StackTransitionResolver<T> get _topBarResolver {
    final coordinator = widget.coordinator;
    return (route) => StackTransition.custom(
      builder: (c) => route.build(coordinator, c),
      pageBuilder: (context, key, child) =>
          ResizableMaterialPage(key: key, child: child),
    );
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
                  resolver: _bodyResolver,
                ),
              ),

              // ── TOP BAR — NavigatorResizable, height animates on swap ─────
              //
              // CompositedTransformTarget establishes the LayerLink leader that
              // the pinned-slot follower tracks.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MeasuredBar(
                  onSize: _metrics.updateTopBar,
                  child: SafeArea(
                    bottom: false,
                    child: CompositedTransformTarget(
                      link: _topBarLayerLink,
                      child: NavigatorResizable(
                        child: NavigationStack<T>(
                          path: _chat.topBarSlot,
                          coordinator: widget.coordinator,
                          resolver: _topBarResolver,
                        ),
                      ),
                    ),
                  ),
                ),
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
              CompositedTransformFollower(
                link: _topBarLayerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                child: MeasuredBar(
                  onSize: _metrics.updatePinned,
                  child: SlotBarView<T>(
                    slot: _chat.pinnedSlot,
                    coordinator: widget.coordinator,
                  ),
                ),
              ),

              // ── BOTTOM BAR — content-sized, floats at bottom ──────────────
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
