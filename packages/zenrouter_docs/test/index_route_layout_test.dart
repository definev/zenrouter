import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/content/book_content.dart';
import 'package:zenrouter_docs/routes/index.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final content = await BookContentRepository.load();
    registerLoadedContent(content);
  });

  testWidgets('index route lays out inside a narrow scrolling viewport', (
    tester,
  ) async {
    await _pumpIndex(tester, const Size(600, 800));

    expect(find.text('Navigation that\nstays in sync.'), findsOneWidget);
    expect(find.text('Orient'), findsOneWidget);
    expect(
      find.text('Get a URL-aware route on screen in 20 minutes.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('index route lays out its equal-height cards on wide screens', (
    tester,
  ) async {
    await _pumpIndex(tester, const Size(1200, 900));

    expect(find.text('Orient'), findsOneWidget);
    expect(find.text('Build'), findsOneWidget);
    expect(find.text('Scale'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpIndex(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final coordinator = DocsCoordinator();
  addTearDown(coordinator.dispose);

  await tester.pumpWidget(
    WidgetsApp(
      color: AppTheme.canvas,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      builder: (context, _) => FTheme(
        data: AppTheme.light,
        child: DocsTheme(
          child: Builder(
            builder: (context) => IndexRoute().build(coordinator, context),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
