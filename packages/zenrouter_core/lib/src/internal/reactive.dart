import 'package:meta/meta.dart';

typedef VoidCallback = void Function();

/// Mixin that provides listener management for observable objects.
///
/// Used by [CoordinatorCore] and [StackPath] to notify dependents when
/// navigation state changes. UI widgets listen to these changes to rebuild.
mixin ListenableObject {
  @mustCallSuper
  void dispose() {}

  @protected
  void notifyListeners();

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);
}
