import 'dart:async';
import 'dart:io' show Platform;

import 'package:dartnative/dartnative.dart';
import 'package:zenrouter_dartnative/zenrouter_dartnative.dart';

import 'sheet_host.dart';
import 'sheet_lifecycle.dart';

/// iOS semantic roles approximated in Dart until DartNative exposes UIColor.
final class _SystemPalette {
  const _SystemPalette({
    required this.brightness,
    required this.canvas,
    required this.field,
    required this.inputSurface,
    required this.inputPlaceholder,
    required this.inactiveSelection,
    required this.primary,
    required this.secondary,
    required this.separator,
    required this.selection,
    required this.error,
  });

  final Brightness brightness;
  final Color canvas;
  final Color field;
  final Color inputSurface;
  final Color inputPlaceholder;
  final Color inactiveSelection;
  final Color primary;
  final Color secondary;
  final Color separator;
  final Color selection;
  final Color error;

  static const light = _SystemPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF2F2F7),
    field: Color(0xFFFFFFFF),
    inputSurface: Color(0xFFFCFCFC),
    inputPlaceholder: Color(0xFF757575),
    inactiveSelection: Color(0xFFF2F2F7),
    primary: Color(0xFF000000),
    secondary: Color(0x993C3C43),
    separator: Color(0x4A3C3C43),
    selection: Color(0xFFE5E5EA),
    error: Color(0xFFFF3B30),
  );

  static const dark = _SystemPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF000000),
    field: Color(0xFF1C1C1E),
    inputSurface: Color(0xFF1D1D1D),
    inputPlaceholder: Color(0xFF777777),
    inactiveSelection: Color(0xFF1C1C1E),
    primary: Color(0xFFFFFFFF),
    secondary: Color(0x99EBEBF5),
    separator: Color(0xA6545458),
    selection: Color(0xFF2C2C2E),
    error: Color(0xFFFF453A),
  );

  static _SystemPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

enum NativeDevToolsTab {
  inspect('Inspect', CupertinoIcons.list_bullet),
  active('Active', CupertinoIcons.layers_alt),
  routes('Routes', CupertinoIcons.arrow_swap);

  const NativeDevToolsTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Keep one controller for the app lifetime to preserve the selected tab.
final class NativeDevToolsController extends ChangeNotifier {
  NativeDevToolsTab _tab = NativeDevToolsTab.inspect;
  String? _error;
  final _sheets = DevToolsSheetLifecycle();
  bool _disposed = false;

  NativeDevToolsTab get tab => _tab;
  String? get error => _error;

  void select(NativeDevToolsTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void _setError(Object error) {
    if (_disposed) return;
    _error = '$error';
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sheets.dispose();
    super.dispose();
  }
}

/// Provides the DevTools sheet to each native presentation.
/// Install it through [CoordinatorView.presentationBuilder], then place
/// [NativeDevToolsLauncher] in a Scaffold slot on each screen.
class NativeDevTools<T extends RouteUnique> extends StatelessWidget {
  const NativeDevTools({
    super.key,
    required this.coordinator,
    required this.controller,
    required this.child,
    this.debugRoutes = const [],
    this.enabled = true,
  });

  final Coordinator<T> coordinator;
  final NativeDevToolsController controller;
  final Widget child;
  final List<Uri> debugRoutes;
  final bool enabled;

  Future<void> _open(BuildContext context, Brightness brightness) async {
    try {
      await controller._sheets.open(() {
        final host = DevToolsSheetHost(context);
        try {
          host.show(
            brightness: brightness,
            child: _DevToolsSheet<T>(
              coordinator: coordinator,
              controller: controller,
              debugRoutes: debugRoutes,
              brightness: brightness,
              onClose: host.close,
              onAction: (action) => unawaited(_performAction(action)),
            ),
          );
          return host;
        } catch (_) {
          host.close();
          host.dispose();
          rethrow;
        }
      });
    } catch (error, stack) {
      dnLog('ZenRouter DevTools sheet failed: $error\n$stack');
      controller._setError(error);
    }
  }

  Future<void> _performAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      dnLog('ZenRouter DevTools action failed: $error\n$stack');
      controller._setError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return _NativeDevToolsScope(
      open: (brightness) => unawaited(_open(context, brightness)),
      child: child,
    );
  }
}

/// Native launcher for a Scaffold.floatingActionButton slot.
class NativeDevToolsLauncher extends StatelessWidget {
  const NativeDevToolsLauncher({super.key, this.brightness});

  /// Overrides the opening screen's brightness when its Scaffold forces one.
  final Brightness? brightness;

  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_NativeDevToolsScope>();
    if (scope == null) return const SizedBox.shrink();
    final openingBrightness =
        brightness ??
        ScaffoldBrightness.forcedOf(context) ??
        MediaQuery.of(context).platformBrightness;
    return FloatingActionButton(
      onPressed: () => scope.open(openingBrightness),
      mini: true,
      child: const Icon(CupertinoIcons.ant, size: 20),
    );
  }
}

class _NativeDevToolsScope extends InheritedWidget {
  const _NativeDevToolsScope({required this.open, required super.child});

  final void Function(Brightness brightness) open;

  @override
  bool updateShouldNotify(_NativeDevToolsScope oldWidget) =>
      !identical(open, oldWidget.open);
}

class _DevToolsSheet<T extends RouteUnique> extends StatefulWidget {
  const _DevToolsSheet({
    required this.coordinator,
    required this.controller,
    required this.debugRoutes,
    required this.brightness,
    required this.onClose,
    required this.onAction,
  });

  final Coordinator<T> coordinator;
  final NativeDevToolsController controller;
  final List<Uri> debugRoutes;
  final Brightness brightness;
  final VoidCallback onClose;
  final void Function(Future<void> Function()) onAction;

  @override
  State<_DevToolsSheet<T>> createState() => _DevToolsSheetState<T>();
}

class _DevToolsSheetState<T extends RouteUnique>
    extends State<_DevToolsSheet<T>>
    with SingleTickerProviderStateMixin {
  final TextEditingController _uri = TextEditingController();
  late final TabController _tabs;
  String? _validationError;
  String? _actionNotice;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: NativeDevToolsTab.values.length,
      initialIndex: widget.controller.tab.index,
      vsync: this,
    )..addListener(_selectTab);
    _uri.text = widget.coordinator.currentUri.toString();
    widget.coordinator.addListener(_onCoordinatorChanged);
    widget.controller.addListener(_refresh);
  }

  void _onCoordinatorChanged() {
    if (!mounted) return;
    final uri = widget.coordinator.currentUri.toString();
    if (_uri.text != uri) {
      _uri.value = TextEditingValue(
        text: uri,
        selection: TextSelection.collapsed(offset: uri.length),
      );
      _validationError = null;
    }
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    if (_tabs.index != widget.controller.tab.index) {
      _tabs.index = widget.controller.tab.index;
    }
    setState(() {});
  }

  void _selectTab() {
    final tab = NativeDevToolsTab.values[_tabs.index];
    if (tab == widget.controller.tab) return;
    _actionNotice = null;
    widget.controller.select(tab);
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorChanged);
    widget.controller.removeListener(_refresh);
    _tabs.removeListener(_selectTab);
    _tabs.dispose();
    _uri.dispose();
    super.dispose();
  }

  void _submit(Future<void> Function() action) {
    widget.controller.clearError();
    if (_actionNotice != null) setState(() => _actionNotice = null);
    widget.onAction(action);
  }

  void _popCurrent() => _submit(() async {
    final popped = await widget.coordinator.tryPop();
    if (mounted && popped != true) {
      setState(
        () => _actionNotice = popped == false
            ? 'Pop was blocked by the route guard.'
            : 'No route to pop.',
      );
    }
  });

  void _selectPathIndex(IndexedStackPath<T> path, int index) => _submit(
    () async {
      await widget.coordinator.selectIndex(path, index);
      if (mounted && path.activeIndex != index) {
        setState(() => _actionNotice = 'Selection was blocked or redirected.');
      }
    },
  );

  Uri? _enteredUri() {
    final input = _uri.text.trim();
    final uri = Uri.tryParse(input);
    if (uri == null || !input.startsWith('/') || !uri.hasAbsolutePath) {
      setState(() => _validationError = 'Enter a path such as /profile/42.');
      return null;
    }
    setState(() => _validationError = null);
    return uri;
  }

  void _submitUri(Future<void> Function(Uri) action) {
    final uri = _enteredUri();
    if (uri == null) return;
    _submit(() => action(uri));
  }

  @override
  Widget build(BuildContext context) {
    final palette = _SystemPalette.forBrightness(widget.brightness);
    final body = Column(
      children: [
        if (Platform.isAndroid) _buildAndroidHeader(palette),
        if (Platform.isAndroid) _buildInputArea(palette),
        _buildTabBar(palette),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: switch (widget.controller.tab) {
              NativeDevToolsTab.inspect => _buildInspectTab(palette),
              NativeDevToolsTab.active => _buildActiveTab(palette),
              NativeDevToolsTab.routes => _buildRoutesTab(palette),
            },
          ),
        ),
      ],
    );
    // Android's native modal owns the outer layout at each detent. Keep the URI
    // controls at the top so editing does not depend on IME insets being
    // forwarded from the modal window to Dart's MediaQuery.
    if (Platform.isAndroid) return body;
    return Scaffold(
      brightness: palette.brightness,
      // Keep the iOS 26 sheet material visible behind grouped content.
      backgroundColor: isIOS26 ? const Color(0x00000000) : palette.canvas,
      body: body,
      bottomInputBar: _buildInputArea(palette),
    );
  }

  Widget _buildAndroidHeader(_SystemPalette palette) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'ZenRouter',
            style: TextStyle(
              color: palette.primary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onClose,
          icon: const Icon(CupertinoIcons.xmark, size: 20),
        ),
      ],
    ),
  );

  // ===========================================================================
  // TAB BAR
  // ===========================================================================

  Widget _buildTabBar(_SystemPalette palette) {
    final bar = TabBar(
      controller: _tabs,
      labelColor: palette.primary,
      unselectedLabelColor: palette.secondary,
      indicatorColor: palette.primary,
      dividerColor: palette.separator,
      tabs: [
        for (final tab in NativeDevToolsTab.values)
          Tab(
            text: tab.label,
            icon: Platform.isAndroid ? null : Icon(tab.icon, size: 20),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      // In the body, no AppBar consumes the tab bar's preferred size.
      // Give the native strip a frame instead of relying on intrinsic sizing.
      child: SizedBox(
        width: double.infinity,
        height: bar.preferredSize.height,
        child: bar,
      ),
    );
  }

  // ===========================================================================
  // INSPECT TAB
  // ===========================================================================

  List<Widget> _buildInspectTab(_SystemPalette palette) {
    final paths = widget.coordinator.paths;
    final activePaths = widget.coordinator.activePaths;
    final registered = Set<StackPath>.identity()..addAll(paths);
    final visited = Set<StackPath>.identity();
    final popTarget = _popTarget(activePaths);

    return [
      if (paths.isEmpty) _emptyState('No paths registered.', palette),
      if (registered.contains(widget.coordinator.root))
        _pathGroup(
          widget.coordinator.root,
          registered: registered,
          visited: visited,
          activePaths: activePaths,
          popTarget: popTarget,
          palette: palette,
        ),
      for (final path in paths)
        if (!visited.contains(path))
          _pathGroup(
            path,
            registered: registered,
            visited: visited,
            activePaths: activePaths,
            popTarget: popTarget,
            palette: palette,
          ),
      if (_actionNotice != null) _notice(_actionNotice!, palette),
    ];
  }

  Widget _pathGroup(
    StackPath path, {
    required Set<StackPath> registered,
    required Set<StackPath> visited,
    required List<StackPath> activePaths,
    required StackPath? popTarget,
    required _SystemPalette palette,
    bool compact = false,
  }) {
    if (!visited.add(path)) return const SizedBox.shrink();
    final active = activePaths.contains(path);
    final entries = path.stack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: compact ? EdgeInsets.zero : const EdgeInsets.all(8),
          decoration: compact
              ? null
              : BoxDecoration(
                  color: palette.field,
                  borderRadius: BorderRadius.circular(10),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          path.debugLabel ?? '${path.runtimeType}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _pathKind(path),
                        style: TextStyle(
                          color: palette.secondary,
                          fontSize: 12,
                        ),
                      ),
                      if (identical(path, popTarget)) ...[
                        const SizedBox(width: 8),
                        _inlineAction('Pop', _popCurrent),
                      ],
                    ],
                  ),
                ),
                Divider(
                  height: 16,
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                  color: palette.separator,
                ),
              ],
              if (entries.isEmpty)
                Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Empty',
                    style: TextStyle(color: palette.secondary, fontSize: 13),
                  ),
                ),
              if (path is BranchedStackPath<T>)
                for (var index = 0; index < entries.length; index++)
                  _branchItem(
                    path,
                    index,
                    registered: registered,
                    visited: visited,
                    activePaths: activePaths,
                    popTarget: popTarget,
                    palette: palette,
                  )
              else
                for (var index = 0; index < entries.length; index++)
                  _routeRow(
                    entries[index],
                    selected: path is IndexedStackPath<T>
                        ? index == path.activeIndex
                        : index == entries.length - 1 && active,
                    active: active,
                    onTap:
                        path is IndexedStackPath<T> &&
                            active &&
                            index != path.activeIndex
                        ? () => _selectPathIndex(path, index)
                        : null,
                    palette: palette,
                  ),
            ],
          ),
        ),
        if (!compact) const SizedBox(height: 10),
        if (path is! BranchedStackPath<T>)
          for (final route in entries)
            if (route is RouteLayoutParent)
              _childPath(
                route,
                registered: registered,
                visited: visited,
                activePaths: activePaths,
                popTarget: popTarget,
                palette: palette,
              ),
      ],
    );
  }

  String _pathKind(StackPath path) => switch (path) {
    BranchedStackPath() => 'Branched',
    IndexedStackPath() => 'Indexed',
    StackMutatable() => 'Stack',
    _ => path.pathKey.key,
  };

  StackPath? _popTarget(List<StackPath> activePaths) {
    for (final path in activePaths.reversed) {
      if (path is StackMutatable && path.stack.length >= 2) return path;
    }
    return null;
  }

  Widget _branchItem(
    BranchedStackPath<T> path,
    int index, {
    required Set<StackPath> registered,
    required Set<StackPath> visited,
    required List<StackPath> activePaths,
    required StackPath? popTarget,
    required _SystemPalette palette,
  }) {
    final route = path.stack[index];
    final selected = index == path.activeBranchIndex;
    final active = activePaths.contains(path);
    final childPath = route is RouteLayoutParent
        ? (route as RouteLayoutParent).resolvePath(widget.coordinator)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected && active ? palette.selection : palette.field,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${route.runtimeType}',
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (childPath != null)
                      Text(
                        '${childPath.debugLabel ?? childPath.runtimeType} · ${_pathKind(childPath)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.secondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (identical(childPath, popTarget) && active && selected)
                _inlineAction('Pop', _popCurrent)
              else if (active && !selected)
                _inlineAction('Switch', () => _selectPathIndex(path, index)),
            ],
          ),
        ),
        if (childPath != null &&
            registered.contains(childPath) &&
            !visited.contains(childPath)) ...[
          const SizedBox(height: 8),
          _pathGroup(
            childPath,
            registered: registered,
            visited: visited,
            activePaths: activePaths,
            popTarget: popTarget,
            palette: palette,
            compact: true,
          ),
        ],
        if (index < path.stack.length - 1)
          Divider(
            height: 16,
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: palette.separator,
          ),
      ],
    );
  }

  Widget _childPath(
    RouteLayoutParent layout, {
    required Set<StackPath> registered,
    required Set<StackPath> visited,
    required List<StackPath> activePaths,
    required StackPath? popTarget,
    required _SystemPalette palette,
  }) {
    final childPath = layout.resolvePath(widget.coordinator);
    if (!registered.contains(childPath) || visited.contains(childPath)) {
      return const SizedBox.shrink();
    }
    return _pathGroup(
      childPath,
      registered: registered,
      visited: visited,
      activePaths: activePaths,
      popTarget: popTarget,
      palette: palette,
    );
  }

  Widget _routeRow(
    RouteTarget route, {
    required bool selected,
    required bool active,
    required VoidCallback? onTap,
    required _SystemPalette palette,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (active ? palette.selection : palette.inactiveSelection)
              : palette.field,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${route.runtimeType}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                route is RouteUnique && route is! RouteLayoutParent
                    ? route.toUri().toString()
                    : 'Layout',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.secondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _inlineAction(String title, VoidCallback onPressed) => Button(
    title: title,
    onPressed: onPressed,
    variant: ButtonVariant.bordered,
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );

  Widget _notice(String message, _SystemPalette palette) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      message,
      style: TextStyle(color: palette.secondary, fontSize: 13),
    ),
  );

  // ===========================================================================
  // ACTIVE TAB
  // ===========================================================================

  List<Widget> _buildActiveTab(_SystemPalette palette) {
    final paths = widget.coordinator.activePaths;
    final popTarget = _popTarget(paths);
    final current = widget.coordinator.activePath.activeRoute;
    return [
      _sectionTitle('Current location', palette),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.field,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.coordinator.currentUri.toString(),
              selectable: true,
              style: TextStyle(color: palette.primary, fontSize: 17),
            ),
            if (current != null) ...[
              const SizedBox(height: 4),
              Text(
                '${current.runtimeType}',
                style: TextStyle(color: palette.secondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _sectionTitle('Active path chain', palette),
      const SizedBox(height: 8),
      for (var index = 0; index < paths.length; index++) ...[
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${paths[index].debugLabel ?? paths[index].runtimeType} · ${_pathKind(paths[index])}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.primary, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  paths[index].activeRoute == null
                      ? 'Empty'
                      : '${paths[index].activeRoute.runtimeType}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: palette.secondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (index < paths.length - 1 || popTarget != null)
          Divider(height: 16, thickness: 1, color: palette.separator),
      ],
      if (popTarget != null)
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Top of ${popTarget.debugLabel ?? popTarget.runtimeType}',
                  style: TextStyle(color: palette.secondary, fontSize: 12),
                ),
              ),
              _inlineAction('Pop', _popCurrent),
            ],
          ),
        ),
      if (_actionNotice != null) _notice(_actionNotice!, palette),
    ];
  }

  // ===========================================================================
  // ROUTES TAB
  // ===========================================================================

  List<Widget> _buildRoutesTab(_SystemPalette palette) => [
    if (widget.debugRoutes.isEmpty)
      _emptyState('No quick routes configured.', palette),
    for (var i = 0; i < widget.debugRoutes.length; i++) ...[
      _buildRouteItem(widget.debugRoutes[i], palette),
      if (i < widget.debugRoutes.length - 1)
        Divider(height: 12, thickness: 1, color: palette.separator),
    ],
  ];

  Widget _buildRouteItem(Uri uri, _SystemPalette palette) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 5),
    title: Text(
      uri.toString(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: palette.primary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          () => _submit(() => widget.coordinator.navigateUri(uri)),
          icon: CupertinoIcons.arrow_right,
          variant: ButtonVariant.tinted,
          width: 40,
        ),
        const SizedBox(width: 4),
        _actionButton(
          () => _submit(() => widget.coordinator.pushSilentlyUri(uri)),
          icon: CupertinoIcons.plus_square_on_square,
          variant: ButtonVariant.plain,
          width: 40,
        ),
        const SizedBox(width: 4),
        _actionButton(
          icon: CupertinoIcons.arrow_2_squarepath,
          () => _submit(() => widget.coordinator.replaceUri(uri)),
          variant: ButtonVariant.plain,
          width: 40,
        ),
      ],
    ),
  );

  // ===========================================================================
  // URI INPUT
  // ===========================================================================

  Widget _buildInputArea(_SystemPalette palette) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_validationError != null) _errorText(_validationError!, palette),
        if (widget.controller.error != null)
          _errorText(widget.controller.error!, palette),
        _uriInput(palette),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                () => _submitUri(widget.coordinator.navigateUri),
                label: 'Navigate',
                variant: isIOS26
                    ? ButtonVariant.prominentGlass
                    : ButtonVariant.filled,
                height: 44,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                () => _submitUri(widget.coordinator.pushSilentlyUri),
                label: 'Push',
                variant: isIOS26 ? ButtonVariant.glass : ButtonVariant.filled,
                height: 44,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                () => _submitUri(widget.coordinator.replaceUri),
                label: 'Replace',
                variant: isIOS26 ? ButtonVariant.glass : ButtonVariant.filled,
                height: 44,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _uriInput(_SystemPalette palette) {
    final input = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _uri,
        style: TextStyle(color: palette.primary, fontSize: 17),
        decoration: InputDecoration(
          hintText: 'Destination URI',
          hintStyle: TextStyle(color: palette.inputPlaceholder),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        clearButtonMode: ClearButtonMode.whileEditing,
        autocorrect: false,
        onChanged: (_) {
          if (_validationError != null) {
            setState(() => _validationError = null);
          }
          widget.controller.clearError();
        },
        onSubmitted: (_) => _submitUri(widget.coordinator.navigateUri),
      ),
    );
    final light = palette.brightness == Brightness.light;
    final shadow = BoxShadow(
      color: Color(light ? 0x1A000000 : 0x66000000),
      blurRadius: 18,
      offset: const Offset(0, 4),
    );
    final child = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: input,
    );
    if (isIOS26) {
      // Keep the native field inside the interactive glass content view.
      // The glass draws its own edge in dark mode and its own press effect.
      return GlassEffectContainer(
        borderRadius: BorderRadius.circular(24),
        brightness: palette.brightness,
        interactive: true,
        child: child,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: palette.inputSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [shadow],
      ),
      child: child,
    );
  }

  // ===========================================================================
  // SHARED CONTENT
  // ===========================================================================

  Widget _actionButton(
    VoidCallback onPressed, {
    IconData? icon,
    String? label,
    required ButtonVariant variant,
    double? width,
    double height = 40,
  }) => Button(
    // Button has no image-padding option, so prefix the native title with a
    // space to separate it from the icon.
    title: label == null ? null : ' $label',
    child: icon == null ? null : Icon(icon, size: 19),
    onPressed: onPressed,
    variant: variant,
    width: width,
    height: height,
    padding: EdgeInsets.zero,
  );

  Widget _sectionTitle(String title, _SystemPalette palette) => Text(
    title,
    style: TextStyle(
      color: palette.secondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _emptyState(String message, _SystemPalette palette) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Text(
      message,
      style: TextStyle(color: palette.secondary, fontSize: 15),
    ),
  );

  Widget _errorText(String message, _SystemPalette palette) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      message,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: palette.error, fontSize: 13),
    ),
  );
}
