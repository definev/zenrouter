import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class _BranchRoute extends RouteTarget with RouteUnique {}

class _ShellLayout extends _BranchRoute with RouteLayout<_BranchRoute> {
  @override
  BranchedStackPath<_BranchRoute> resolvePath(
    covariant _BranchCoordinator coordinator,
  ) => coordinator.branches;

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      buildPath(coordinator as Coordinator);
}

class _HomeBranchLayout extends _BranchRoute with RouteLayout<_BranchRoute> {
  @override
  Type get layout => _ShellLayout;

  @override
  NavigationPath<_BranchRoute> resolvePath(
    covariant _BranchCoordinator coordinator,
  ) => coordinator.homePath;

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      buildPath(coordinator as Coordinator);
}

class _SettingsBranchLayout extends _BranchRoute
    with RouteLayout<_BranchRoute> {
  @override
  Type get layout => _ShellLayout;

  @override
  NavigationPath<_BranchRoute> resolvePath(
    covariant _BranchCoordinator coordinator,
  ) => coordinator.settingsPath;

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      buildPath(coordinator as Coordinator);
}

class _HomeRoute extends _BranchRoute {
  _HomeRoute(this.id);

  final String id;

  @override
  Type get layout => _HomeBranchLayout;

  @override
  Uri toUri() => Uri.parse('/home/$id');

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      Text('home:$id');

  @override
  List<Object?> get props => [id];
}

class _SettingsRoute extends _BranchRoute {
  _SettingsRoute(this.id);

  final String id;

  @override
  Type get layout => _SettingsBranchLayout;

  @override
  Uri toUri() => Uri.parse('/settings/$id');

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      Text('settings:$id');

  @override
  List<Object?> get props => [id];
}

class _PlainRoute extends _BranchRoute {
  @override
  Uri toUri() => Uri.parse('/plain');

  @override
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      const SizedBox.shrink();
}

class _BranchCoordinator extends Coordinator<_BranchRoute> {
  late final homePath = NavigationPath<_BranchRoute>.createWith(
    coordinator: this,
    label: 'home',
  )..bindLayout(_HomeBranchLayout.new);

  late final settingsPath = NavigationPath<_BranchRoute>.createWith(
    coordinator: this,
    label: 'settings',
  )..bindLayout(_SettingsBranchLayout.new);

  late final branches = BranchedStackPath<_BranchRoute>.createWith(
    [_HomeBranchLayout(), _SettingsBranchLayout()],
    coordinator: this,
    label: 'branches',
  )..bindLayout(_ShellLayout.new);

  @override
  List<StackPath> get paths => [
    ...super.paths,
    branches,
    homePath,
    settingsPath,
  ];

  @override
  _BranchRoute parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['settings', final id] => _SettingsRoute(id),
    ['home', final id] => _HomeRoute(id),
    _ => _HomeRoute('root'),
  };
}

void main() {
  group('BranchedStackPath', () {
    test('requires at least one unique branch layout', () {
      expect(
        () => BranchedStackPath<_BranchRoute>.create([]),
        throwsArgumentError,
      );
      expect(
        () => BranchedStackPath<_BranchRoute>.create([
          _HomeBranchLayout(),
          _HomeBranchLayout(),
        ]),
        throwsArgumentError,
      );
    });

    test('requires every branch root to be a layout parent', () {
      expect(
        () => BranchedStackPath<_BranchRoute>.create([_PlainRoute()]),
        throwsArgumentError,
      );
    });

    test(
      'switches fixed branches and restores the active branch index',
      () async {
        final path = BranchedStackPath<_BranchRoute>.create([
          _HomeBranchLayout(),
          _SettingsBranchLayout(),
        ]);

        expect(path.pathKey, BranchedStackPath.key);
        expect(path.activeBranchIndex, 0);
        expect(path.activeBranch, isA<_HomeBranchLayout>());

        await path.goToBranch(1);

        expect(path.activeBranchIndex, 1);
        expect(path.activeBranch, isA<_SettingsBranchLayout>());
        expect(path.serialize(), 1);

        path.reset();
        path.restore(path.deserialize(1));

        expect(path.activeBranchIndex, 1);
      },
    );

    test(
      'preserves the independent navigation depth of every branch',
      () async {
        final coordinator = _BranchCoordinator();

        await coordinator.pushSilently(_HomeRoute('one'));
        await coordinator.pushSilently(_HomeRoute('two'));
        await coordinator.pushSilently(_SettingsRoute('one'));

        expect(coordinator.branches.activeBranchIndex, 1);
        expect(coordinator.homePath.stack, [
          _HomeRoute('one'),
          _HomeRoute('two'),
        ]);
        expect(coordinator.settingsPath.stack, [_SettingsRoute('one')]);
        expect(coordinator.activePaths.last, coordinator.settingsPath);

        await coordinator.branches.goToBranch(0);

        expect(coordinator.activePaths.last, coordinator.homePath);
        expect(coordinator.currentUri, Uri.parse('/home/two'));
        expect(coordinator.homePath.stack.length, 2);
        expect(coordinator.settingsPath.stack.length, 1);

        coordinator.branches.reset();

        expect(coordinator.branches.activeBranchIndex, 0);
        expect(coordinator.homePath.stack, isEmpty);
        expect(coordinator.settingsPath.stack, isEmpty);

        coordinator.dispose();
      },
    );

    test('has a built-in Flutter layout builder', () {
      expect(kDefaultLayoutBuilderTable[BranchedStackPath.key], isNotNull);
    });
  });
}
