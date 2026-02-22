import 'package:nocterm/nocterm.dart';

mixin class ReactiveChangeNotifier implements ChangeNotifier {
  final List<VoidCallback> _listeners = [];

  /// Register a closure to be called when the object notifies its listeners.
  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove a previously registered listener.
  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Call all registered listeners.
  @override
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Discards any resources used by the object.
  @override
  void dispose() {
    _listeners.clear();
  }
}
