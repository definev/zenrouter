import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

void main() {
  const config = RouteCodeConfig();

  test('generates encoded path-segment construction for dynamic routes', () {
    const route = RouteElement(
      className: 'UserRoute',
      relativePath: 'users/[userId]',
      pathSegments: ['users', ':userId'],
      parameters: [RouteParameter(name: 'userId')],
    );

    final generated = RouteCodeGenerator.generate(route, config);

    expect(generated, contains("Uri(pathSegments: ['users', userId])"));
    expect(generated, isNot(contains('Uri.parse')));
  });

  test('expands catch-all parameters as independently encoded segments', () {
    const route = RouteElement(
      className: 'DocsRoute',
      relativePath: 'docs/[...slugs]',
      pathSegments: ['docs', '...:slugs'],
      parameters: [
        RouteParameter(name: 'slugs', type: 'List<String>', isRest: true),
      ],
    );

    final generated = RouteCodeGenerator.generate(route, config);

    expect(generated, contains("Uri(pathSegments: ['docs', ...slugs])"));
  });

  test('keeps root canonical and applies declared queries afterward', () {
    const route = RouteElement(
      className: 'HomeRoute',
      relativePath: 'index',
      pathSegments: [],
      parameters: [],
      queries: ['q'],
    );

    final generated = RouteCodeGenerator.generate(route, config);

    expect(generated, contains("final uri = Uri(path: '/');"));
    expect(generated, contains('uri.replace(queryParameters: queries)'));
  });

  test('Uri pathSegments round-trip reserved characters in one parameter', () {
    const parameter = 'a/b?c#d% e';
    final uri = Uri(pathSegments: ['users', parameter]);

    expect(uri.pathSegments, ['users', parameter]);
    expect(uri.path, isNot(contains('/a/b')));
  });
}
