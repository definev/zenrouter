import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

import 'coordinator.dart';

/// Everything a presentation adapter needs to show one route entry.
///
/// A custom adapter must render [builder]. It already contains the coordinator
/// scope, route guard, mount acknowledgement, and the route's widget subtree.
/// [entryToken] is stable for this presentation and distinct for equal routes.
final class PresentationContext {
  const PresentationContext({
    required this.hostContext,
    required this.builder,
    required this.route,
    required this.entryToken,
  });

  final BuildContext hostContext;
  final WidgetBuilder builder;
  final RouteUnique route;
  final Object entryToken;
}

/// The live result of presenting one route.
///
/// [result] must complete after the presentation has physically disappeared.
/// The router also observes PopScope and subtree disposal from
/// [PresentationContext.builder]. These signals are merged by entry
/// identity, but adapters must explicitly complete [result] from a controller
/// or native callback when their primitive provides no other reliable signal.
/// [dismiss] only requests removal; its acknowledgement still comes through a
/// dismissal signal.
abstract interface class PresentationHandle {
  Future<Object?> get result;
  void dismiss([Object? result]);
}

/// Convenience handle for custom adapters backed by callbacks or controllers.
final class PresentationHandleAdapter implements PresentationHandle {
  const PresentationHandleAdapter({
    required this.result,
    required void Function(Object? result) dismiss,
  }) : _dismiss = dismiss;

  @override
  final Future<Object?> result;

  final void Function(Object? result) _dismiss;

  @override
  void dismiss([Object? result]) => _dismiss(result);
}

/// Open seam between route state and a DartNative/native presentation.
///
/// Implement this for a plugin-backed controller, a custom overlay, or another
/// presentation primitive. The router does not switch on concrete adapter
/// types. Keep [PresentationContext.builder] mounted for exactly the
/// visible lifetime of the presentation. Interactive adapters must also apply
/// any route guard decision before allowing the native dismissal when the
/// gesture needs to be vetoable.
abstract interface class Presentation {
  /// Whether this presentation has a meaningful inline persistent-root form.
  /// Non-root presentations are rejected before replace/reset mutates state.
  bool get canMountAsRoot;

  PresentationHandle present(PresentationContext context);
}

/// Presents a route as a native screen.
///
/// Route names are intentionally absent: native hot-restart replay cannot
/// reconstruct coordinator state yet. The default matches DartNative's
/// standard native push transition. The SDK currently exposes no transition
/// completion hook, so subtree mounting acknowledges presentation readiness,
/// not animation completion.
final class ScreenPresentation implements Presentation {
  const ScreenPresentation({
    this.transition = RouteTransition.slideFromRight,
    this.duration = const Duration(milliseconds: 350),
    this.zoomSourceTag,
  });

  final int transition;
  final Duration duration;
  final Object? zoomSourceTag;

  @override
  bool get canMountAsRoot => true;

  @override
  PresentationHandle present(PresentationContext context) {
    final result = Navigator.push<Object?>(
      context.hostContext,
      PageRoute<Object?>(
        builder: context.builder,
        transition: transition,
        duration: duration,
        zoomSourceTag: zoomSourceTag,
      ),
    );
    return _NavigatorPresentationHandle(context.hostContext, result);
  }
}

/// Programmatic detent-sheet adapter.
///
/// Experimental: in the inspected SDK a system grabber dismissal does not
/// complete the returned Future or invoke PopScope/dispose. Use only when the
/// sheet cannot be dismissed externally, or supply a custom adapter backed by
/// a native dismissal callback.
final class ExperimentalModalSheetPresentation implements Presentation {
  const ExperimentalModalSheetPresentation({
    this.detent = SheetDetent.large,
    this.backgroundColor,
    this.cornerRadius = -1,
    this.showDragHandle = true,
    this.header,
    this.headerController,
  });

  final SheetDetent detent;
  final Color? backgroundColor;
  final double cornerRadius;
  final bool showDragHandle;
  final SheetHeader? header;
  final SheetHeaderController? headerController;

  @override
  bool get canMountAsRoot => false;

  @override
  PresentationHandle present(PresentationContext context) =>
      _NavigatorPresentationHandle(
        context.hostContext,
        showModalSheet<Object?>(
          context: context.hostContext,
          builder: context.builder,
          detent: detent,
          backgroundColor: backgroundColor,
          cornerRadius: cornerRadius,
          showDragHandle: showDragHandle,
          header: header,
          headerController: headerController,
        ),
      );
}

/// Programmatic content-sized bottom-sheet adapter.
///
/// Experimental until the installed SDK exposes reliable external-dismissal
/// acknowledgement for its overlay primitives.
final class ExperimentalBottomSheetPresentation implements Presentation {
  const ExperimentalBottomSheetPresentation({
    this.backgroundColor,
    this.cornerRadius = 15,
    this.dimOpacity = 0.4,
  });

  final Color? backgroundColor;
  final double cornerRadius;
  final double dimOpacity;

  @override
  bool get canMountAsRoot => false;

  @override
  PresentationHandle present(PresentationContext context) =>
      _NavigatorPresentationHandle(
        context.hostContext,
        showModalBottomSheet<Object?>(
          context: context.hostContext,
          builder: context.builder,
          backgroundColor: backgroundColor,
          cornerRadius: cornerRadius,
          dimOpacity: dimOpacity,
        ),
      );
}

/// Programmatic centered-dialog adapter.
///
/// Experimental until the installed SDK exposes reliable external-dismissal
/// acknowledgement for its overlay primitives.
final class ExperimentalDialogPresentation implements Presentation {
  const ExperimentalDialogPresentation({
    this.backgroundColor,
    this.cornerRadius = 15,
    this.dimOpacity = 0.4,
    this.ios,
  });

  final Color? backgroundColor;
  final double cornerRadius;
  final double dimOpacity;
  final DialogIOSConfig? ios;

  @override
  bool get canMountAsRoot => false;

  @override
  PresentationHandle present(PresentationContext context) =>
      _NavigatorPresentationHandle(
        context.hostContext,
        showDialog<Object?>(
          context: context.hostContext,
          builder: context.builder,
          backgroundColor: backgroundColor,
          cornerRadius: cornerRadius,
          dimOpacity: dimOpacity,
          ios: ios,
        ),
      );
}

/// Presents a route above the keyboard (iOS only in the inspected SDK).
///
/// On unsupported platforms DartNative may complete [result] immediately; the
/// router treats that as a native dismissal instead of a synchronization error.
final class ExperimentalKeyboardOverlayPresentation implements Presentation {
  const ExperimentalKeyboardOverlayPresentation();

  @override
  bool get canMountAsRoot => false;

  @override
  PresentationHandle present(PresentationContext context) =>
      _NavigatorPresentationHandle(
        context.hostContext,
        showKeyboardOverlay<Object?>(
          context: context.hostContext,
          builder: context.builder,
        ),
      );
}

final class _NavigatorPresentationHandle implements PresentationHandle {
  const _NavigatorPresentationHandle(this._context, this.result);

  final BuildContext _context;

  @override
  final Future<Object?> result;

  @override
  void dismiss([Object? result]) => Navigator.pop(_context, result);
}

/// Adds URI routing and DartNative rendering to a core [RouteTarget].
///
/// Use the same route declaration as ZenRouter:
/// `abstract class AppRoute extends RouteTarget with RouteUnique {}`.
mixin RouteUnique on RouteTarget implements RouteUri, RootMountable {
  @override
  Uri get identifier => toUri();

  /// The type of layout that contains this route.
  Type? get layout => null;

  @override
  Object? get parentLayoutKey => layout;

  late final _layoutChild = RouteLayoutChild.proxy(this);

  @override
  RouteLayoutParent? createParentLayout(CoordinatorCore coordinator) =>
      _layoutChild.createParentLayout(coordinator);

  @override
  RouteLayoutParent? resolveParentLayout(CoordinatorCore coordinator) =>
      _layoutChild.resolveParentLayout(coordinator);

  /// Presentation used whenever this route is above the persistent root.
  /// The root itself is always mounted inline by [CoordinatorView].
  Presentation get presentation => const ScreenPresentation();

  @override
  bool get canMountAsRoot => presentation.canMountAsRoot;

  Widget build(covariant CoordinatorCore coordinator, BuildContext context);
}
