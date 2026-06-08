import 'package:flutter/widgets.dart';
import 'package:navigator_resizable/navigator_resizable.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/src/path/chat_slot.dart';
import 'package:zenrouter_chat_ui/src/transition/vertical_slide_transition.dart';
import 'package:zenrouter_chat_ui/src/widgets/chat_metrics.dart';

/// Content-sized renderer for a bar [ChatSlot].
///
/// Unlike [NavigationStack], this widget has **no** Navigator and does not
/// require bounded height. It is suitable for the top-bar, pinned, and
/// bottom-bar slots, which are positioned as floating overlays.
///
/// Renders [SizedBox.shrink] when [slot] is empty, so optional slots (e.g. the
/// pinned-message banner) simply disappear without any conditional logic in the
/// parent.
///
/// ```dart
/// Positioned(
///   bottom: 0, left: 0, right: 0,
///   child: SlotBarView(
///     slot: coordinator.bottomSlot,
///     coordinator: coordinator,
///   ),
/// )
/// ```
///
/// The active route is swapped instantly (no transition). If you need an
/// animated bar transition, wrap [SlotBarView] in an [AnimatedSwitcher].
class SlotBarView<T extends RouteUnique> extends StatelessWidget {
  const SlotBarView({
    super.key,
    required this.slot,
    required this.onSize,
    required this.coordinator,
    this.slideDirections = VerticalSlideDirections.chatBar,
  });

  final ChatSlot<T> slot;
  final Coordinator<T> coordinator;
  final ValueChanged<double> onSize;

  /// Vertical slide directions for bar slot pushes and pops.
  final VerticalSlideDirections slideDirections;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 1000),
      child: ListenableBuilder(
        listenable: slot,
        builder: (context, child) {
          final isEmpty = slot.stack.isEmpty;

          return MeasuredBar(
            onSize: onSize,
            measureCount: !isEmpty ? 10 : null,
            child: NavigatorResizable(
              onSize: (size) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onSize(size.height),
                );
              },
              child: NavigationStack(
                path: slot,
                coordinator: coordinator,
                restorationId: slot.stackRestorationId(coordinator),
                resolver: (route) => switch (route) {
                  RouteTransition() => route.transition(coordinator),
                  _ => ChatStackTransition.verticalSlide(
                    (context) => route.build(coordinator, context),
                    directions: slideDirections,
                    restorationId: slot.routeRestorationId(
                      coordinator,
                      route,
                    ),
                  ),
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
