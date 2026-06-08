import 'package:flutter/widgets.dart';
import 'package:navigator_resizable/navigator_resizable.dart';
import 'package:zenrouter/zenrouter.dart';

/// Vertical edge used for slide transitions.
enum VerticalSlideEdge {
  /// Toward / from the top of the viewport (negative Y offset).
  top,

  /// Toward / from the bottom of the viewport (positive Y offset).
  bottom,
}

/// Configures vertical slide directions for push, pop, and covered routes.
///
/// Typical chat-style bars: enter from [bottom], exit to [bottom], and the
/// route underneath moves [bottom] when another bar is pushed.
class VerticalSlideDirections {
  const VerticalSlideDirections({
    this.pushEnter = VerticalSlideEdge.bottom,
    this.popExit = VerticalSlideEdge.bottom,
    this.coveredOnPush = VerticalSlideEdge.bottom,
  });

  /// Edge the incoming route slides in from on push.
  final VerticalSlideEdge pushEnter;

  /// Edge the outgoing route slides toward on pop.
  final VerticalSlideEdge popExit;

  /// Edge the route underneath moves toward when a new route is pushed on top.
  final VerticalSlideEdge coveredOnPush;

  /// Slides up on enter, down on push-over and pop (common for bottom-anchored bars).
  static const chatBar = VerticalSlideDirections(
    pushEnter: VerticalSlideEdge.bottom,
    popExit: VerticalSlideEdge.bottom,
    coveredOnPush: VerticalSlideEdge.bottom,
  );

  /// Slides down on enter, up when covered or popped.
  static const fromTop = VerticalSlideDirections(
    pushEnter: VerticalSlideEdge.top,
    popExit: VerticalSlideEdge.top,
    coveredOnPush: VerticalSlideEdge.top,
  );
}

/// Builds a [ResizablePageRoutePageBuilder] slide transition.
///
/// - **Push:** the entering route moves from [VerticalSlideDirections.pushEnter]
///   into place.
/// - **Push (covered):** the route below moves toward
///   [VerticalSlideDirections.coveredOnPush].
/// - **Pop:** the exiting route moves toward [VerticalSlideDirections.popExit];
///   the revealed route reverses the covered motion.
Widget buildResizableVerticalSlideTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
  VerticalSlideDirections directions = VerticalSlideDirections.chatBar,
  Curve curve = Curves.easeInOutCubic,
}) {
  final curvedPrimary = CurvedAnimation(parent: animation, curve: curve);
  final curvedSecondary = CurvedAnimation(
    parent: secondaryAnimation,
    curve: curve,
  );

  final primaryPosition = directions.pushEnter == directions.popExit
      ? curvedPrimary.drive(
          Tween<Offset>(
            begin: _edgeOffset(directions.pushEnter),
            end: Offset.zero,
          ),
        )
      : curvedPrimary.drive(
          _VerticalPrimaryTween(directions),
        );

  final secondaryPosition = curvedSecondary.drive(
    Tween<Offset>(
      begin: Offset.zero,
      end: _edgeOffset(directions.coveredOnPush),
    ),
  );

  return SlideTransition(
    position: primaryPosition,
    child: SlideTransition(
      position: secondaryPosition,
      child: child,
    ),
  );
}

Offset _edgeOffset(VerticalSlideEdge edge) => switch (edge) {
  VerticalSlideEdge.bottom => const Offset(0, 1),
  VerticalSlideEdge.top => const Offset(0, -1),
};

/// Primary slide when [VerticalSlideDirections.popExit] differs from [pushEnter].
class _VerticalPrimaryTween extends Animatable<Offset> {
  const _VerticalPrimaryTween(this.directions);

  final VerticalSlideDirections directions;

  @override
  Offset transform(double t) {
    return Offset.lerp(
      _edgeOffset(directions.pushEnter),
      Offset.zero,
      t,
    )!;
  }

  @override
  Offset evaluate(Animation<double> animation) {
    if (animation.status == AnimationStatus.reverse) {
      return Offset.lerp(
        Offset.zero,
        _edgeOffset(directions.popExit),
        1.0 - animation.value,
      )!;
    }
    return transform(animation.value);
  }
}

/// Returns a [ResizablePageRoutePageBuilder] with a vertical slide transition.
@optionalTypeArgs
ResizablePageRoutePageBuilder<T> resizableVerticalSlidePage<T>({
  LocalKey? key,
  String? name,
  Object? arguments,
  String? restorationId,
  required Widget child,
  VerticalSlideDirections directions = VerticalSlideDirections.chatBar,
  Curve curve = Curves.easeInOutCubic,
  Duration transitionDuration = const Duration(milliseconds: 300),
  Duration reverseTransitionDuration = const Duration(milliseconds: 300),
  bool opaque = true,
  bool maintainState = true,
  bool fullscreenDialog = false,
  bool allowSnapshotting = true,
}) {
  return ResizablePageRoutePageBuilder<T>(
    key: key,
    name: name,
    arguments: arguments,
    restorationId: restorationId,
    child: child,
    opaque: opaque,
    maintainState: maintainState,
    fullscreenDialog: fullscreenDialog,
    allowSnapshotting: allowSnapshotting,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: reverseTransitionDuration,
    transitionsBuilder: (route, context, animation, secondaryAnimation, child) {
      return buildResizableVerticalSlideTransition(
        context: context,
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
        directions: directions,
        curve: curve,
      );
    },
  );
}

/// [StackTransition] helpers for [NavigatorResizable] slot navigators.
abstract final class ChatStackTransition {
  /// Vertical slide using [resizableVerticalSlidePage].
  static StackTransition<T> verticalSlide<T extends RouteTarget>(
    WidgetBuilder builder, {
    VerticalSlideDirections directions = VerticalSlideDirections.chatBar,
    Curve curve = Curves.easeInOutCubic,
    Duration transitionDuration = const Duration(milliseconds: 300),
    RouteGuard? guard,
    String? restorationId,
  }) => StackTransition.custom(
    builder: builder,
    pageBuilder: (context, routeKey, pageChild) => resizableVerticalSlidePage(
      key: routeKey,
      restorationId: restorationId,
      directions: directions,
      curve: curve,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: transitionDuration,
      child: pageChild,
    ),
    guard: guard,
  );
}
