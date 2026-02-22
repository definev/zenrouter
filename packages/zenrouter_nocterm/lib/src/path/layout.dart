import 'package:zenrouter_nocterm/zenrouter_nocterm.dart';

/// Extension that binds a [RouteLayout] constructor to a [StackPath].
///
/// This extension provides the [bindLayout] method which registers a layout
/// constructor with the coordinator, allowing routes in this path to be
/// wrapped by the specified layout.
extension RouteLayoutBinding<T extends RouteUnique> on StackPath<T> {
  void bindLayout(RouteLayoutConstructor constructor) =>
      // ignore: invalid_use_of_protected_member
      (coordinator as Coordinator).defineLayoutParent(constructor);
}
