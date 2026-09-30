import 'dart:async';

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import 'app_route.dart';
import 'demo_widgets.dart';
import 'tracing_presentation.dart';

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri(path: '/navigation');
  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      const HomeScreen();
}

class DetailRoute extends AppRoute {
  DetailRoute(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
  @override
  Uri toUri() => Uri(pathSegments: ['', 'details', id]);
  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) {
    return DemoPage(
      title: 'Detail $id',
      children: [
        Text('URI: ${toUri()}'),
        action('Return result: saved', () => coordinator.pop('saved:$id')),
        action(
          'Push same URI again',
          () => coordinator.pushSilently(DetailRoute(id)),
        ),
        action('Replace top with detail 99', () {
          unawaited(coordinator.pushReplacement(DetailRoute('99')));
        }),
        action(
          'Reset to playground',
          () => coordinator.recoverUri(Uri.parse('/controls/counter')),
        ),
      ],
    );
  }
}

class EditorRoute extends AppRoute with RouteGuard {
  final _saved = ValueNotifier<bool>(false);

  bool _allowNextBack = false;

  @override
  Uri toUri() => Uri(path: '/editor');
  @override
  bool get canPop => _saved.value;
  @override
  ListenableMixin get canPopListenable => _saved.toListenableMixin();
  @override
  Future<bool> popGuard() async {
    final allowed = _saved.value || _allowNextBack;
    _allowNextBack = false;
    return allowed;
  }

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) {
    return DemoPage(
      title: 'Guarded editor',
      children: [
        const Text(
          'Back is blocked until you save.\n'
          'Try the native back button, then save and try again.',
        ),
        action('Try guarded pop', () => coordinator.pop('discarded')),
        action('Allow next back via async guard', () {
          // canPop remains false: the host must run the async guard and then
          // authorize the physical pop without invoking the guard a second time.
          _allowNextBack = true;
        }),
        action('Save: enable native back', () {
          _saved.value = true;
        }),
        action('Save and return result', () {
          _saved.value = true;
          return coordinator.pop('editor:saved');
        }),
      ],
    );
  }
}

class SheetRoute extends AppRoute {
  @override
  Presentation get presentation => const TracingPresentation(
    ExperimentalModalSheetPresentation(detent: SheetDetent.medium),
  );

  @override
  Uri toUri() => Uri(path: '/sheet');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Routed native sheet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'This route uses an app-defined presentation adapter wrapping '
            'ExperimentalModalSheetPresentation.',
          ),
          action(
            'Close sheet with result',
            () => coordinator.pop('sheet:done'),
          ),
        ],
      ),
    );
  }
}

class MissingRoute extends AppRoute with RouteNotFound {
  MissingRoute(this.uri);
  final Uri uri;
  @override
  Uri toUri() => uri;
  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      DemoPage(
        title: 'Not found',
        children: [
          Text('$uri'),
          action(
            'Reset to playground',
            () => coordinator.recoverUri(Uri.parse('/controls/counter')),
          ),
        ],
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _result = 'No result yet';

  Future<void> _open(AppRoute route) async {
    final result = await CoordinatorScope.of<AppRoute>(
      context,
    ).push<String>(route);
    if (mounted) setState(() => _result = 'Result: $result');
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = CoordinatorScope.of<AppRoute>(context);
    return DemoPage(
      title: 'ZenRouter · DartNative',
      children: [
        const Text('Native presentation stack + indexed route layouts'),
        Text(_result),
        action('Open detail 42', () => _open(DetailRoute('42'))),
        action('Open guarded editor', () => _open(EditorRoute())),
        action('Open routed native sheet', () => _open(SheetRoute())),
        action(
          'Recover Controls / Counter',
          () => coordinator.recoverUri(Uri.parse('/controls/counter')),
        ),
        action(
          'Recover URI /details/7',
          () => coordinator.recoverUri(Uri.parse('/details/7')),
        ),
        action(
          'Recover unknown URI',
          () => coordinator.recoverUri(Uri.parse('/unknown')),
        ),
        action(
          'Recover URI /gallery/palette',
          () => coordinator.recoverUri(Uri.parse('/gallery/palette')),
        ),
      ],
    );
  }
}
