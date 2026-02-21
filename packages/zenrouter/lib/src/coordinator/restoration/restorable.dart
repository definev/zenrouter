import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// A widget that enables state restoration for a [Coordinator] and its navigation hierarchy.
///
/// ## Role in Navigation Flow
///
/// [CoordinatorRestorable] participates in navigation by:
/// 1. Wrapping the coordinator's widget tree during build
/// 2. Saving navigation state when coordinator changes
/// 3. Restoring navigation state during app initialization
/// 4. Ensuring users return to the exact same screen after app restart
///
/// This widget is used internally by [CoordinatorRouterDelegate.build].
/// It integrates with Flutter's [RestorationMixin] to participate in the
/// framework's restoration protocol.
///
/// ## Where It Fits in the Architecture
///
/// The restoration hierarchy looks like this:
/// ```
/// MaterialApp.router(restorationScopeId: 'app')
///   └─ Router(routerDelegate: coordinator.routerDelegate)
///       └─ CoordinatorRestorable (automatically added by routerDelegate.build)
///           └─ NavigationStack(restorationId: 'root_stack')
///               └─ Your app widgets
/// ```
class CoordinatorRestorable extends StatefulWidget {
  const CoordinatorRestorable({
    super.key,
    required this.restorationId,
    required this.coordinator,
    required this.child,
  });

  /// The restoration identifier used to save and restore this coordinator's state.
  ///
  /// ## Relationship
  /// Must be unique within the parent restoration scope. Part of the restoration
  /// bucket hierarchy.
  final String restorationId;

  /// The coordinator whose navigation state will be saved and restored.
  ///
  /// ## Relationship
  /// The entire navigation hierarchy including all [StackPath] instances will be
  /// persisted when the app goes to background and restored when it returns.
  final Coordinator coordinator;

  /// The child widget to render.
  ///
  /// ## Relationship
  /// Typically the [Router] or root widget of the application's navigation hierarchy.
  final Widget child;

  @override
  State<CoordinatorRestorable> createState() => _CoordinatorRestorableState();
}

class _CoordinatorRestorableState extends State<CoordinatorRestorable>
    with RestorationMixin {
  late final _restorable = _CoordinatorRestorable(widget.coordinator);
  late final _activeRoute = ActiveRouteRestorable(
    initialRoute: widget.coordinator.activePath.activeRoute,
    parseRouteFromUri: widget.coordinator.parseRouteFromUriSync,
    createLayoutParent: widget.coordinator.createLayoutParent,
    decodeLayoutKey: widget.coordinator.decodeLayoutKey,
    getRestorableConverter: widget.coordinator.getRestorableConverter,
  );

  void _saveCoordinator() {
    final result = <String, dynamic>{};
    for (final path in widget.coordinator.paths) {
      if (path is NavigationPath) {
        assert(
          path.debugLabel != null,
          'NavigationPath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.stack;
      }
      if (path is IndexedStackPath) {
        assert(
          path.debugLabel != null,
          'IndexedStackPath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.activeIndex;
      }
    }

    _restorable.value = result;
  }

  void _saveActiveRoute() {
    _activeRoute.value = widget.coordinator.activePath.activeRoute;
  }

  void _restoreCoordinator() {
    final raw = _restorable.value;

    for (final MapEntry(:key, :value) in raw.entries) {
      final path = widget.coordinator.paths.firstWhereOrNull(
        (p) => p.debugLabel == key,
      );

      if (path case RestorablePath path) {
        path.restore(value);
      }
    }
    if (_activeRoute.value case RouteUnique route) {
      widget.coordinator.navigate(route);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_saveCoordinator);
    widget.coordinator.addListener(_saveActiveRoute);
  }

  @override
  void didUpdateWidget(covariant CoordinatorRestorable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coordinator != oldWidget.coordinator) {
      // coverage:ignore-start
      oldWidget.coordinator.removeListener(_saveCoordinator);
      widget.coordinator.addListener(_saveCoordinator);
      oldWidget.coordinator.removeListener(_saveActiveRoute);
      widget.coordinator.addListener(_saveActiveRoute);
      // coverage:ignore-end
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_saveCoordinator);
    widget.coordinator.removeListener(_saveActiveRoute);
    _restorable.dispose();
    _activeRoute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorable, '_restorable');
    registerForRestoration(_activeRoute, '_activeRoute');
    if (initialRestore) {
      _restoreCoordinator();
    }
  }
}

/// A [RestorableValue] that manages the restoration of the currently active route in the navigation stack.
///
/// ## Role in Navigation Flow
///
/// [ActiveRouteRestorable] tracks the currently visible route:
/// 1. Saves the active route when coordinator state changes
/// 2. Restores navigation to the saved route during app initialization
/// 3. Enables seamless user experience after app restart
///
/// This class is used internally by [_CoordinatorRestorableState] to track the
/// active route separately from the full navigation stack.
///
/// ## Relationship
///
/// The restoration data flow:
/// ```
/// CoordinatorRestorableState
///   ├─ _CoordinatorRestorable       (saves ALL routes in ALL paths)
///   └─ ActiveRouteRestorable        (saves the ONE active route)
///        └─ On restore → Coordinator.navigate(activeRoute)
/// ```
class ActiveRouteRestorable<T extends RouteUnique> extends RestorableValue<T?> {
  ActiveRouteRestorable({
    required this.initialRoute,
    required this.parseRouteFromUri,
    required this.createLayoutParent,
    required this.decodeLayoutKey,
    required this.getRestorableConverter,
  });

  /// The initial route to use when no restoration data is available.
  ///
  /// ## Relationship
  /// Used as default when app launches fresh or restoration data doesn't exist.
  final T? initialRoute;

  /// Function to parse a route from a URI string.
  ///
  /// ## Relationship
  /// Synchronous version of [Coordinator.parseRouteFromUri] for deserializing
  /// [RouteUnique] routes saved as URI strings.
  final RouteUriParserSync<RouteUnique> parseRouteFromUri;

  final RouteLayoutParentConstructor createLayoutParent;

  final DecodeLayoutKeyCallback decodeLayoutKey;

  final RestorableConverterLookupFunction getRestorableConverter;

  @override
  T? createDefaultValue() => initialRoute;

  @override
  void didUpdateValue(T? oldValue) {
    notifyListeners();
  }

  @override
  T? fromPrimitives(Object? data) {
    // Never happen
    // coverage:ignore-start
    if (data == null) return null;
    // coverage:ignore-end
    return RestorableConverter.deserializeRoute(
      data,
      decodeLayoutKey: decodeLayoutKey,
      createLayoutParent: createLayoutParent,
      parseRouteFromUri: parseRouteFromUri,
      getRestorableConverter: getRestorableConverter,
    );
  }

  @override
  Object? toPrimitives() {
    if (value == null) return null;
    return RestorableConverter.serializeRoute(value!);
  }
}

class _CoordinatorRestorable<T extends RouteUnique>
    extends RestorableValue<Map<String, dynamic>> {
  _CoordinatorRestorable(this.coordinator);
  final Coordinator coordinator;

  @override
  Map<String, dynamic> createDefaultValue() {
    final map = <String, dynamic>{};
    for (final path in coordinator.paths) {
      if (path is NavigationPath) {
        assert(
          path.debugLabel != null,
          'NavigationPath must have a debugLabel for restoration to work',
        );
        map[path.debugLabel!] = path.stack.cast<T>();
        continue;
      }
      if (path is IndexedStackPath) {
        assert(
          path.debugLabel != null,
          'IndexedStackPath must have a debugLabel for restoration to work',
        );
        map[path.debugLabel!] = path.activeIndex;
        continue;
      }
    }
    return map;
  }

  @override
  void didUpdateValue(Map<String, dynamic>? oldValue) {
    notifyListeners();
  }

  @override
  Map<String, dynamic> fromPrimitives(Object? data) {
    final result = <String, dynamic>{};

    final map = (data as Map).cast<String, dynamic>();
    for (final pathEntry in map.entries) {
      final path = coordinator.paths.firstWhereOrNull(
        (p) => p.debugLabel == pathEntry.key,
      );
      if (path case NavigationPath path) {
        assert(
          path.debugLabel != null,
          'NavigationPath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.deserialize(
          pathEntry.value,
          coordinator.parseRouteFromUriSync,
        );
      }
      if (path case RestorablePath path) {
        assert(
          path.debugLabel != null,
          'RestorablePath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.deserialize(pathEntry.value);
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> toPrimitives() {
    final result = <String, dynamic>{};

    for (final path in coordinator.paths) {
      if (path case RestorablePath path) {
        assert(
          path.debugLabel != null,
          'RestorablePath must have a debugLabel for restoration to work',
        );
        result[path.debugLabel!] = path.serialize();
      }
    }

    return result;
  }
}
