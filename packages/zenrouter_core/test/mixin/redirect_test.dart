import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

class BaseRoute extends RouteTarget {
  BaseRoute(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

/// Redirects to a [BaseRoute] that is not a [SpecificRedirectRoute].
class SpecificRedirectRoute extends BaseRoute with RouteRedirect<BaseRoute> {
  SpecificRedirectRoute(super.id, {required this.redirectToId});

  final String redirectToId;
  bool discarded = false;

  @override
  BaseRoute redirect() => BaseRoute(redirectToId);

  @override
  void onDiscard() {
    discarded = true;
    super.onDiscard();
  }
}

void main() {
  group('RouteRedirect.resolve', () {
    test(
      'throws StateError when redirect returns wrong type for resolve T',
      () async {
        final route = SpecificRedirectRoute('source', redirectToId: 'target');

        // Resolve as SpecificRedirectRoute, but redirect() returns a plain
        // BaseRoute — the new type-mismatch guard must throw instead of looping.
        await expectLater(
          () => RouteRedirect.resolve<SpecificRedirectRoute>(route, null),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(
                contains('BaseRoute'),
                contains('expected SpecificRedirectRoute'),
              ),
            ),
          ),
        );
        expect(route.discarded, isTrue);
      },
    );

    test('returns redirected route when types match', () async {
      final route = SpecificRedirectRoute('source', redirectToId: 'target');

      final result = await RouteRedirect.resolve<BaseRoute>(route, null);

      expect(result, isA<BaseRoute>());
      expect(result!.id, 'target');
      expect(route.discarded, isTrue);
    });
  });
}
