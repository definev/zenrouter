import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_docs/widgets/mardown_section.dart';

void main() {
  testWidgets('empty TOC does not reserve a blank margin column', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    const surfaceKey = ValueKey('surface');

    await tester.pumpWidget(
      const _LayoutHarness(
        width: 1200,
        child: ColoredBox(key: surfaceKey, color: AppTheme.paper),
      ),
    );

    expect(tester.getSize(find.byKey(surfaceKey)).width, 1200);
    expect(find.text('In this chapter'), findsNothing);
  });

  testWidgets('TOC registration does not resize the reading surface', (
    tester,
  ) async {
    _setViewport(tester, const Size(1200, 800));
    const surfaceKey = ValueKey('surface');

    await tester.pumpWidget(
      const _LayoutHarness(
        width: 1200,
        child: ColoredBox(
          key: surfaceKey,
          color: AppTheme.paper,
          child: _TocFixture(
            key: ValueKey('first-heading'),
            title: 'Route ownership',
          ),
        ),
      ),
    );

    // Headings register after their first layout. The reading surface must not
    // change width when that registration makes the marginal TOC visible.
    expect(tester.getSize(find.byKey(surfaceKey)).width, 1200);

    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byKey(surfaceKey)).width, 1200);
    expect(find.text('In this chapter'), findsOneWidget);
    expect(find.text('Route ownership'), findsOneWidget);

    await tester.pumpWidget(
      const _LayoutHarness(
        width: 1200,
        child: ColoredBox(
          key: surfaceKey,
          color: AppTheme.paper,
          child: _TocFixture(
            key: ValueKey('replacement-heading'),
            title: 'Route ownership',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Route ownership'), findsOneWidget);
  });

  testWidgets('narrow chapters keep the reading surface edge to edge', (
    tester,
  ) async {
    _setViewport(tester, const Size(900, 800));
    const surfaceKey = ValueKey('surface');

    await tester.pumpWidget(
      const _LayoutHarness(
        width: 900,
        child: ColoredBox(
          key: surfaceKey,
          color: AppTheme.paper,
          child: _TocFixture(title: 'Route ownership'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byKey(surfaceKey)).width, 900);
    expect(find.text('In this chapter'), findsNothing);
  });

  testWidgets('Markdown links expose their parsed URI', (tester) async {
    Uri? opened;

    await tester.pumpWidget(
      FTheme(
        data: AppTheme.light,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MarkdownSection(
            markdown: '[Contents](/docs)',
            onOpenUri: (uri) => opened = uri,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Contents'));
    expect(opened, Uri.parse('/docs'));
  });

  testWidgets('chapter navigation spans the reading surface', (tester) async {
    _setViewport(tester, const Size(1000, 800));

    await tester.pumpWidget(
      FTheme(
        data: AppTheme.light,
        child: const DocsTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 1000,
              height: 800,
              child: DocPage(
                markdown: '',
                title: 'A test chapter',
                chapterNavigation: _NavigationProbe(),
              ),
            ),
          ),
        ),
      ),
    );

    final navigation = find.byType(_NavigationProbe);
    expect(navigation, findsNWidgets(2));
    expect(tester.getSize(navigation.first).width, 1000);
    expect(tester.getTopLeft(find.text('A test chapter')).dx, 180);
  });

  testWidgets('unsupported code languages render immediately as plain text', (
    tester,
  ) async {
    await tester.pumpWidget(
      FTheme(
        data: AppTheme.light,
        child: const DocsTheme(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CodeBlock(code: 'echo ready', language: 'bash'),
          ),
        ),
      ),
    );

    expect(find.text('echo ready'), findsOneWidget);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _LayoutHarness extends StatelessWidget {
  const _LayoutHarness({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FTheme(
      data: AppTheme.light,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: width,
            height: 800,
            child: DocsLayoutBuilder(child: child),
          ),
        ),
      ),
    );
  }
}

class _TocFixture extends StatefulWidget {
  const _TocFixture({super.key, required this.title});

  final String title;

  @override
  State<_TocFixture> createState() => _TocFixtureState();
}

class _TocFixtureState extends State<_TocFixture> {
  final GlobalKey _headingKey = GlobalKey();
  TocController? _controller;
  late TocItem _item;

  @override
  void initState() {
    super.initState();
    _item = _createItem();
  }

  TocItem _createItem() =>
      TocItem(title: widget.title, level: 2, key: _headingKey);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DocsTocScope.of(context);
    if (_controller == controller) return;
    _controller?.removeItem(_item);
    _controller = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller?.addItem(_item);
    });
  }

  @override
  void didUpdateWidget(covariant _TocFixture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title == widget.title) return;
    _controller?.removeItem(_item);
    _item = _createItem();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller?.addItem(_item);
    });
  }

  @override
  void dispose() {
    _controller?.removeItem(_item);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(key: _headingKey);
}

class _NavigationProbe extends StatelessWidget {
  const _NavigationProbe();

  @override
  Widget build(BuildContext context) => const SizedBox(height: 60);
}
