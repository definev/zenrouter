import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

/// App-defined instrumentation composed around any presentation. The host
/// needs no knowledge of this type, and dismissal/result identity is preserved.
final class TracingPresentation implements Presentation {
  const TracingPresentation(this.delegate);
  final Presentation delegate;

  @override
  bool get canMountAsRoot => delegate.canMountAsRoot;

  @override
  PresentationHandle present(PresentationContext context) {
    final label =
        '${context.route.toUri()} #${identityHashCode(context.entryToken)}';
    dnLog('[Presentation] open $label');
    final handle = delegate.present(context);
    return PresentationHandleAdapter(
      result: handle.result.then((result) {
        dnLog('[Presentation] closed $label → $result');
        return result;
      }),
      dismiss: (result) {
        dnLog('[Presentation] dismiss $label → $result');
        handle.dismiss(result);
      },
    );
  }
}
