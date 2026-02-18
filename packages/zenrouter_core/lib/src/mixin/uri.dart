import 'package:zenrouter_core/zenrouter_core.dart';

/// Abstract base class for routes with URI representation.
///
/// [RouteUri] combines [RouteIdentity] with [RouteLayoutChild] to provide
/// URI-based route identification and layout resolution capabilities.
///
/// ## Role in Navigation Flow
///
/// Routes extending this class:
///
/// - Have a URI identifier used for URL synchronization and deep linking
/// - Support parent layout resolution for nested navigation
/// - Can be converted to/from URIs for web routing
///
/// Most routes should use [RouteUnique] which implements this class.
abstract class RouteUri extends RouteTarget
    with RouteIdentity<Uri>, RouteLayoutChild {
  @override
  Uri get identifier => toUri();

  /// Converts this route to a [Uri] for URL representation.
  Uri toUri();

  Object? get parentLayoutKey => null;
}
