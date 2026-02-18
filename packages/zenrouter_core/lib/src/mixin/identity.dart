import 'package:zenrouter_core/src/mixin/target.dart';

mixin RouteIdentity<T> on RouteTarget {
  /// The identifier for this route.
  T get identifier;
}
