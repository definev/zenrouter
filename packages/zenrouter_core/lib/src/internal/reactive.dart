import 'package:meta/meta.dart';

typedef VoidCallback = void Function();

/// Subscribe-only surface for reactive updates.
///
/// Used as the return type of [RouteGuard.canPopListenable] so routes can
/// invalidate `PopScope` when [RouteGuard.canPop] may have changed, without
/// depending on Flutter or `package:listen`.
///
/// In Flutter apps, convert a `ValueNotifier` / `ChangeNotifier` with
/// `toListenableMixin()` from `package:zenrouter`.
abstract mixin class ListenableMixin {
  /// Register a closure to be called when this object notifies its listeners.
  void addListener(VoidCallback listener);

  /// Remove a previously registered closure from this object's listeners.
  void removeListener(VoidCallback listener);

  /// A [ListenableMixin] that notifies when any of [listenables] notify.
  ///
  /// Null entries are ignored. Once created, the iterable must not change.
  static ListenableMixin merge(Iterable<ListenableMixin?> listenables) =>
      _MergingListenable(List<ListenableMixin>.unmodifiable([
        for (final listenable in listenables)
          if (listenable != null) listenable,
      ]));
}

class _MergingListenable implements ListenableMixin {
  _MergingListenable(this._children);

  final List<ListenableMixin> _children;

  @override
  void addListener(VoidCallback listener) {
    for (final child in _children) {
      child.addListener(listener);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    for (final child in _children) {
      child.removeListener(listener);
    }
  }

  @override
  String toString() => 'ListenableMixin.merge([${_children.join(', ')}])';
}

/// Mixin that provides listener management for observable objects.
///
/// Used by [CoordinatorCore] and [StackPath] to notify dependents when
/// navigation state changes. UI widgets listen to these changes to rebuild.
mixin ListenableObject implements ListenableMixin {
  @mustCallSuper
  void dispose() {}

  @protected
  void notifyListeners();
}
