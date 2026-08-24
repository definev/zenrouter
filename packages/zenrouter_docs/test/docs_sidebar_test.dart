import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/content/book_content.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final content = await BookContentRepository.load();
    registerLoadedContent(content);
  });

  testWidgets('sidebar selection follows coordinator navigation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final coordinator = _TestDocsCoordinator();
    addTearDown(coordinator.dispose);

    await tester.pumpWidget(
      WidgetsApp(
        color: AppTheme.canvas,
        supportedLocales: FLocalizations.supportedLocales,
        localizationsDelegates: FLocalizations.localizationsDelegates,
        builder: (context, _) => FTheme(
          data: AppTheme.light,
          child: DocsTheme(
            child: DocsCoordinatorProvider(
              coordinator: coordinator,
              child: const RootLayoutBuilder(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );

    coordinator.updateCurrentPath('/docs/chapter/chapter-1');
    await tester.pump();

    expect(_selectedChapter(tester, '1. Start here'), isTrue);
    expect(_selectedChapter(tester, '2. Choose a navigation model'), isFalse);

    coordinator.updateCurrentPath('/docs/chapter/chapter-2');
    await tester.pump();

    expect(_selectedChapter(tester, '1. Start here'), isFalse);
    expect(_selectedChapter(tester, '2. Choose a navigation model'), isTrue);
  });
}

bool _selectedChapter(WidgetTester tester, String label) {
  final selectedDecoration = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == AppTheme.paleBlue,
    ),
  );
  return selectedDecoration.evaluate().isNotEmpty;
}

class _TestDocsCoordinator extends DocsCoordinator {
  Uri? _currentUri;

  @override
  Uri get currentUri => _currentUri ?? super.currentUri;

  void updateCurrentPath(String path) {
    _currentUri = Uri.parse(path);
    notifyListeners();
  }
}
