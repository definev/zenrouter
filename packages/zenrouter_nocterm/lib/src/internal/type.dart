import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_core/zenrouter_core.dart';
import 'package:zenrouter_nocterm/src/coordinator/base.dart';
import 'package:zenrouter_nocterm/src/mixin/layout.dart';
import 'package:zenrouter_nocterm/src/mixin/unique.dart';

/// Synchronous parser function that converts a [Uri] into a route instance.
///
/// Used by the restoration system to restore navigation state from URLs.
/// The parser extracts route information from the URI and constructs
/// an appropriate route instance of type [T].
typedef RouteUriParserSync<T extends RouteTarget> = T Function(Uri uri);

/// Builder function for creating a layout widget that wraps route content.
///
/// This typedef defines a function signature for building layout widgets that
/// can wrap and decorate the content of routes in a navigation stack. Layouts
/// are useful for adding common UI elements like app bars, navigation rails,
/// or background decorations around route content.
///
/// **Parameters:**
/// - `coordinator`: The coordinator managing navigation state.
/// - `path`: The current navigation stack path containing the route.
/// - `layout`: Optional layout instance that may contain additional configuration.
///
/// **Returns:**
/// A [Widget] that provides the layout structure for the route.
///
/// See also:
/// - [RouteLayoutConstructor], which creates layout instances.
/// - [RouteLayout], the base class for layout implementations.
typedef RouteLayoutBuilder<T extends RouteUnique> =
    Component Function(
      Coordinator coordinator,
      StackPath<T> path,
      RouteLayout<T>? layout,
    );

/// Constructor function for creating a layout instance.
///
/// This typedef defines a function signature for constructing [RouteLayout]
/// instances. Layout constructors are typically used in route definitions to
/// specify which layout should wrap the route's content.
///
/// **Returns:**
/// A new [RouteLayout] instance of type [T].
///
/// **Example:**
/// ```dart
/// RouteLayoutConstructor<AppRoute> constructor = () => MainLayout();
/// ```
///
/// See also:
/// - [RouteLayoutBuilder], which builds the layout widget.
/// - [RouteLayout], the base class for layout implementations.
typedef RouteLayoutConstructor<T extends RouteUnique> =
    RouteLayout<T> Function();

typedef NavigationStackResolver<T extends RouteTarget> =
    Route<void> Function(T route);
