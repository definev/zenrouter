/// # The Base Route
///
/// Every route in our documentation shall extend this abstract class.
/// It combines `RouteTarget` (the fundamental building block) with
/// `RouteUnique` (the mixin that grants URI awareness).
///
/// This is the pattern: define your route hierarchy, then let each
/// route know how to present itself as a URI and how to build its
/// widget.
library;

import 'package:zenrouter/zenrouter.dart';

/// The foundation upon which all documentation routes are built.
///
/// By extending `RouteTarget` and mixing in `RouteUnique`, each route
/// gains two essential capabilities:
///
/// 1. **Identity**: The route knows who it is, can compare itself to others
/// 2. **URI Awareness**: The route can express itself as a URI and be
///    reconstructed from one
abstract class DocsRoute extends RouteTarget with RouteUnique {}
