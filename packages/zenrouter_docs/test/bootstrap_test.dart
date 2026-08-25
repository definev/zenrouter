import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter_docs/content/book_content.dart';
import 'package:zenrouter_docs/main.dart';

void main() {
  testWidgets('bootstrap paints before the outline finishes loading', (
    tester,
  ) async {
    final content = Completer<BookContentRepository>();

    await tester.pumpWidget(DocsBootstrap(content: content.future));

    expect(find.text('ZenRouter'), findsOneWidget);
    expect(find.text('Preparing documentation…'), findsOneWidget);
  });
}
