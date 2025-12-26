import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/src/path/restoration.dart';
import 'package:zenrouter/zenrouter.dart';

class CoordinatorRestorable extends StatefulWidget {
  const CoordinatorRestorable({
    super.key,
    required this.restorationId,
    required this.coordinator,
    required this.child,
  });

  final String restorationId;
  final Coordinator coordinator;
  final Widget child;

  @override
  State<CoordinatorRestorable> createState() => CoordinatorRestorableState();
}

class CoordinatorRestorableState extends State<CoordinatorRestorable>
    with RestorationMixin {
  late final _restorable = _CoordinatorRestorable(widget.coordinator);
  late final _activeRoute = ActiveRouteRestorable(
    initialRoute: widget.coordinator.activePath.activeRoute,
    parseRouteFromUri: widget.coordinator.parseRouteFromUriSync,
  );

  void _saveCoordinator() {
    final result = <String, dynamic>{};
    for (final path in widget.coordinator.paths) {
      if (path is NavigationPath) {
        result[path.debugLabel!] = path.stack;
      }
      if (path is IndexedStackPath) {
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
      if (path == null) continue;

      if (path case RestorablePath path) {
        path.restore(value);
      } else {
        throw UnimplementedError();
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
      oldWidget.coordinator.removeListener(_saveCoordinator);
      widget.coordinator.addListener(_saveCoordinator);
      oldWidget.coordinator.removeListener(_saveActiveRoute);
      widget.coordinator.addListener(_saveActiveRoute);
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

class ActiveRouteRestorable<T extends RouteUnique> extends RestorableValue<T?> {
  ActiveRouteRestorable({
    required this.initialRoute,
    required this.parseRouteFromUri,
  });
  final T? initialRoute;
  final RouteUriParserSync<RouteUnique> parseRouteFromUri;

  @override
  T? createDefaultValue() => initialRoute;

  @override
  void didUpdateValue(T? oldValue) {
    notifyListeners();
  }

  @override
  T? fromPrimitives(Object? data) {
    if (data == null) return null;
    if (data case String data) {
      return parseRouteFromUri(Uri.parse(data)) as T;
    }
    if (data case Map<String, dynamic> data) {
      return RouteRestorable.deserialize(
            data,
            parseRouteFromUri: parseRouteFromUri,
          )
          as T;
    }
    return null;
  }

  @override
  Object? toPrimitives() {
    if (value == null) return null;
    if (value case RouteRestorable value) {
      return RouteRestorable.serialize(value);
    }
    return value!.toUri().toString();
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
        map[path.debugLabel!] = path.stack.cast<T>();
        continue;
      }
      if (path is IndexedStackPath) {
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

      /// Invalid cached
      if (path == null) return {};
      if (path case NavigationPath path) {
        result[path.debugLabel!] = path.deserialize(
          pathEntry.value,
          coordinator.parseRouteFromUriSync,
        );
      }
      if (path case RestorablePath path) {
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
        result[path.debugLabel!] = path.serialize();
      }
      final converter = RestorableConverter.buildConverter(path.pathKey.key);
      if (converter == null) throw UnimplementedError();
      result[path.debugLabel!] = converter.serialize(path);
    }

    return result;
  }
}
