import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// Adapts a DartNative notifier to the core guard-listener contract.
extension ListenableToListenableMixin on Listenable {
  ListenableMixin toListenableMixin() => _ListenableAdapter(this);
}

final class _ListenableAdapter implements ListenableMixin {
  const _ListenableAdapter(this.source);
  final Listenable source;

  @override
  void addListener(void Function() listener) => source.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      source.removeListener(listener);
}
