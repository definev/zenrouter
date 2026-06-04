import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_chat_ui/src/path/chat_slot.dart';

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
    required this.coordinator,
  });

  final ChatSlot<T> slot;
  final Coordinator<T> coordinator;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: slot,
      builder: (context, _) {
        final route = slot.activeRoute;
        if (route == null) return const SizedBox.shrink();
        return route.build(coordinator, context);
      },
    );
  }
}
