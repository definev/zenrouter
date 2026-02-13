import 'package:meta/meta.dart';

typedef VoidCallback = void Function();

mixin ListenableObject {
  @mustCallSuper
  void dispose() {}

  @protected
  void notifyListeners();

  void addListener(VoidCallback listener);

  void removeListener(VoidCallback listener);
}
