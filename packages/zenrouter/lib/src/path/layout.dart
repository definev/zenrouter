import 'package:zenrouter/zenrouter.dart';

extension RouteLayoutBinding<T extends RouteUnique> on StackPath<T> {
  void bindLayout(RouteLayoutConstructor constructor) =>
      (coordinator as Coordinator).defineLayoutParent(constructor);
}
