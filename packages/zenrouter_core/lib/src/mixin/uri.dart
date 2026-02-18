import 'package:zenrouter_core/zenrouter_core.dart';

/// Abstract base class for routes that can be represented as URIs.
///
/// [RouteUri] combines [RouteIdentity] and [RouteLayoutChild] to provide:
/// - [identifier]: URI-based route identification
/// - [toUri()]: Convert route to URI representation
/// - Layout resolution via [RouteLayoutChild] methods
///
/// Most routes should use the [RouteUnique] mixin instead of implementing
/// this directly. [RouteUnique] extends [RouteTarget] and implements [RouteUri],
/// providing the full routing functionality.
abstract class RouteUri extends RouteTarget
    with RouteIdentity<Uri>, RouteLayoutChild {
  @override
  Uri get identifier => toUri();

  Uri toUri();
}
