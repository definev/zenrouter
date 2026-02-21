import 'package:zenrouter/zenrouter.dart';

/// {@template zenrouter.CoordinatorRestoration}
/// Mixins for coordinating route state restoration.
///
/// [CoordinatorRestoration] - Abstract mixin defining the interface for
/// encoding/decoding layout restoration keys.
///
/// ## Role in Navigation Flow
///
/// [CoordinatorRestoration] enables state persistence across app restarts:
/// 1. Encodes layout keys for restoration when layouts are defined
/// 2. Decodes layout keys when restoring navigation state
/// 3. Generates restoration IDs for routes based on their path hierarchy
///
/// When restoration is enabled:
/// - [encodeLayoutKey] is called when layouts are registered
/// - [decodeLayoutKey] is called during restoration to recreate layouts
/// - [resolveRouteId] generates unique IDs for each route's state
/// {@endtemplate}
mixin CoordinatorRestoration<T extends RouteUnique> on CoordinatorCore<T> {
  final _layoutKeyTable = <String, Object>{};

  @override
  void dispose() {
    _layoutKeyTable.clear();
    super.dispose();
  }

  /// {@template zenrouter.CoordinatorRestoration.decodeLayoutKey}
  /// Decodes and returns the stored layout key for the given [key].
  /// {@endtemplate}
  Object decodeLayoutKey(String key) {
    final value = _layoutKeyTable[key];
    if (value == null) {
      throw UnimplementedError(
        'The [$key] layout is not defined. You must define it using [Coordinator.defineLayoutParent] or via the [bindLayout] method in the corresponding [StackPath].',
      );
    }
    return value;
  }

  /// {@template zenrouter.CoordinatorRestoration.encodeLayoutKey}
  /// Encodes the layout key to be restored later.
  /// {@endtemplate}
  void encodeLayoutKey(Object value) =>
      _layoutKeyTable[value.toString()] = value;

  /// The restoration ID for the root path.
  ///
  /// This ID is used to restore the root path when the app is re-launched.
  String get rootRestorationId => root.debugLabel ?? 'root';

  /// Resolves the restoration ID for a given route.
  ///
  /// This ID is used to restore the route when the app is re-launched.
  String resolveRouteId(covariant T route) {
    RouteLayout? layout = route.resolveParentLayout(this);
    List<RouteLayout> layouts = [];
    List<StackPath> layoutPaths = [];
    while (layout != null) {
      layouts.add(layout);
      layoutPaths.add(layout.resolvePath(this));
      layout = layout.resolveParentLayout(this);
    }

    String layoutRestorationId = layoutPaths
        .map((p) {
          final label = p.debugLabel;
          assert(
            label != null,
            '[StackPath] must have an unique label in order to use with Coordinator restorable',
          );
          return label!;
        })
        .join('_');
    layoutRestorationId = '${rootRestorationId}_$layoutRestorationId';
    final routeRestorationId = switch (route) {
      RouteRestorable() => (route as RouteRestorable).restorationId,
      _ => route.identifier.toString(),
    };

    return '${layoutRestorationId}_$routeRestorationId';
  }
}
