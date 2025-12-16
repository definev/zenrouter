import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

// ============================================================================
// Main App Entry Point
// ============================================================================
import 'dart:collection';
import 'package:flutter/scheduler.dart';

/// A widget that visualizes widget rebuilds by drawing a flashing rectangle
/// over widgets that have just rebuilt.
///
/// Usage:
/// ```dart
/// void main() {
///   runApp(
///     FlutterScan(
///       enabled: true,
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class FlutterScan extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const FlutterScan({super.key, required this.child, this.enabled = true});

  @override
  State<FlutterScan> createState() => _FlutterScanState();
}

class _FlutterScanState extends State<FlutterScan>
    with SingleTickerProviderStateMixin {
  final ListQueue<_RebuildInfo> _rebuilds = ListQueue();
  late final Ticker _ticker;
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);
  final List<Element> _dirtyElements = [];
  bool _frameCallbackScheduled = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.enabled) {
      _enableScanning();
    }
  }

  @override
  void didUpdateWidget(FlutterScan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _enableScanning();
      } else {
        _disableScanning();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _disableScanning();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _tickNotifier.value++;

    // Cleanup old rebuilds
    final now = DateTime.now();
    while (_rebuilds.isNotEmpty) {
      final info = _rebuilds.first;
      if (now.difference(info.timestamp).inMilliseconds > 500) {
        _rebuilds.removeFirst();
      } else {
        break;
      }
    }

    if (_rebuilds.isEmpty) {
      _ticker.stop();
    }
  }

  void _enableScanning() {
    debugOnRebuildDirtyWidget = _onRebuildDirtyWidget;
  }

  void _disableScanning() {
    if (debugOnRebuildDirtyWidget == _onRebuildDirtyWidget) {
      debugOnRebuildDirtyWidget = null;
    }
    _rebuilds.clear();
    _ticker.stop();
  }

  void _onRebuildDirtyWidget(Element element, bool builtOnce) {
    // Avoid scanning our own internal widgets to prevent infinite loops
    if (element.widget is FlutterScan) {
      if (element.widget.runtimeType.toString() == '_RebuildPainter' ||
          element.widget is FlutterScan) {
        return;
      }
    }

    // We only care about elements that have a render object attached directly
    // or indirectly that we can measure.
    if (element.renderObject == null || !element.renderObject!.attached) {
      return;
    }

    _dirtyElements.add(element);
    if (!_frameCallbackScheduled) {
      _frameCallbackScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback(_onPostFrame);
    }
  }

  void _onPostFrame(Duration timeStamp) {
    _frameCallbackScheduled = false;
    if (!mounted) {
      _dirtyElements.clear();
      return;
    }

    final now = DateTime.now();
    bool addedAny = false;

    for (final element in _dirtyElements) {
      // The logic from _processElement is now inlined here.
      if (!element.mounted || element.renderObject == null) continue;

      final renderObject = element.renderObject!;
      if (!renderObject.attached) continue;

      // We don't calculate rect here anymore, we just store the renderObject.
      // But we do check if it's visible/valid to avoid adding junk.
      try {
        // Quick check if it has size (optional, but good for perf)
        if (!renderObject.paintBounds.isEmpty) {
          _rebuilds.add(
            _RebuildInfo(renderObject: renderObject, timestamp: now),
          );
          addedAny = true;
        }
      } catch (e) {
        // Ignore
      }
    }
    _dirtyElements.clear();

    if (addedAny && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        // Overlay for rebuilds
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _RebuildPainter(
              rebuilds: _rebuilds,
              repaint: _tickNotifier,
            ),
          ),
        ),
      ],
    );
  }
}

class _RebuildInfo {
  final WeakReference<RenderObject> renderObjectRef;
  final DateTime timestamp;

  _RebuildInfo({required RenderObject renderObject, required this.timestamp})
    : renderObjectRef = WeakReference(renderObject);
}

class _RebuildPainter extends CustomPainter {
  final ListQueue<_RebuildInfo> rebuilds;

  _RebuildPainter({required this.rebuilds, required super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    for (final info in rebuilds) {
      final renderObject = info.renderObjectRef.target;
      if (renderObject == null || !renderObject.attached) continue;

      final age = now.difference(info.timestamp).inMilliseconds;
      if (age > 500) continue;

      try {
        final transform = renderObject.getTransformTo(null);
        final paintBounds = renderObject.paintBounds;
        final rect = MatrixUtils.transformRect(transform, paintBounds);

        if (rect.isEmpty) continue;

        final opacity = 1.0 - (age / 500.0);

        const strokeWidth = 2.0;
        final insideRect = rect.deflate(strokeWidth / 2);

        final borderPaint = Paint()
          ..color = const Color.fromARGB(
            255,
            104,
            167,
            159,
          ).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

        canvas.drawRect(insideRect, borderPaint);
      } catch (e) {
        // RenderObject might be detached during paint
      }
    }
  }

  @override
  bool shouldRepaint(_RebuildPainter oldDelegate) => true;
}

void main() {
  runApp(FlutterScan(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final appCoordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Nested Routes Example',
      routerDelegate: appCoordinator.routerDelegate,
      routeInformationParser: appCoordinator.routeInformationParser,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
    );
  }
}

// ============================================================================
// Route Definitions
// ============================================================================

/// Base route class for all app routes
abstract class AppRoute extends RouteTarget with RouteUnique {}

/// Home layout - uses NavigatorStack for nested navigation within home
class HomeLayout extends AppRoute with RouteLayout<AppRoute>, RouteTransition {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home'), backgroundColor: Colors.blue),
      body: RouteLayout.buildPrimitivePath(
        NavigationPath,
        coordinator,
        coordinator.homeStack,
        this,
      ),
    );
  }

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    AppCoordinator coordinator,
  ) {
    return StackTransition.cupertino(
      Builder(builder: (context) => build(coordinator, context)),
    );
  }
}

/// Tab bar shell - uses Custom (IndexedStack) for tab navigation
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Type get layout => HomeLayout;

  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabIndexed;

  @override
  Uri toUri() => Uri.parse('/home/tabs');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabIndexed;
    return Scaffold(
      body: Column(
        children: [
          // Tab content (IndexedStack is built by RouteLayout)
          Expanded(
            child: RouteLayout.buildPrimitivePath(
              IndexedStackPath,
              coordinator,
              path,
              this,
            ),
          ),
          // Tab bar
          Container(
            color: Colors.grey[200],
            child: ListenableBuilder(
              listenable: path,
              builder: (context, child) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TabButton(
                    label: 'Feed',
                    isActive: path.activeIndex == 0,
                    onTap: () => coordinator.push(FeedTabLayout()),
                  ),
                  _TabButton(
                    label: 'Profile',
                    isActive: path.activeIndex == 1,
                    onTap: () => coordinator.push(ProfileTab()),
                  ),
                  _TabButton(
                    label: 'Settings',
                    isActive: path.activeIndex == 2,
                    onTap: () => coordinator.push(SettingsTab()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings shell - uses NavigatorStack for nested settings navigation
class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.settingsStack;

  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => coordinator.tryPop()),
        title: const Text('Settings'),
      ),
      body: RouteLayout.buildPrimitivePath(
        NavigationPath,
        coordinator,
        coordinator.settingsStack,
        this,
      ),
    );
  }
}

// ============================================================================
// Tab Routes (belong to TabBarLayout - custom layout)
// ============================================================================

class FeedTabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/home/tabs/feed');

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.feedTabStack;

  @override
  Type get layout => TabBarLayout;
}

class FeedTab extends AppRoute {
  @override
  Type get layout => FeedTabLayout;

  @override
  Uri toUri() => Uri.parse('/home/tabs/feed');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Feed',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _FeedItem(
          title: 'Post 1',
          onTap: () => coordinator.push(FeedDetail(id: '1')),
        ),
        _FeedItem(
          title: 'Post 2',
          onTap: () => coordinator.push(FeedDetail(id: '2')),
        ),
        _FeedItem(
          title: 'Post 3',
          onTap: () => coordinator.push(FeedDetail(id: '3')),
        ),
        _FeedItem(
          title: 'Post "profile" will redirect to ProfileDetail',
          onTap: () => coordinator.push(FeedDetail(id: 'profile')),
        ),
      ],
    );
  }
}

class ProfileTab extends AppRoute {
  @override
  Type get layout => TabBarLayout;

  @override
  Uri toUri() => Uri.parse('/home/tabs/profile');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => coordinator.push(ProfileDetail()),
          child: const Text('View Profile Details'),
        ),
      ],
    );
  }
}

class SettingsTab extends AppRoute {
  @override
  Type get layout => TabBarLayout;

  @override
  Uri toUri() => Uri.parse('/home/tabs/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Quick Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => coordinator.push(GeneralSettings()),
          child: const Text('Go to Full Settings'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => coordinator.push(Login()),
          child: const Text('Go to Login'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            coordinator.recoverRouteFromUri(Uri.parse('/home/feed/3221'));
          },
          child: const Text('Recover Route'),
        ),
      ],
    );
  }
}

// ============================================================================
// Detail Routes (belong to HomeLayout - navigatorStack layout)
// ============================================================================

class FeedDetail extends AppRoute
    with RouteGuard, RouteRedirect, RouteDeepLink {
  FeedDetail({required this.id});

  final String id;

  @override
  Type get layout => FeedTabLayout;

  @override
  Uri toUri() => Uri.parse('/home/feed/$id');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed Detail $id')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Feed Detail for Post $id',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [id];

  /// Showing confirm pop dialog
  @override
  FutureOr<bool> popGuardWith(AppCoordinator coordinator) async {
    final confirm = await showDialog<bool>(
      context: coordinator.navigator.context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to leave this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  @override
  FutureOr<AppRoute?> redirect() {
    /// Redirect to other stack demonstration
    /// The redirect path resolver by the Coordinator
    if (id == 'profile') return ProfileDetail();
    return this;
  }

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  FutureOr<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) {
    coordinator.replace(FeedTab());
    coordinator.push(this);
  }
}

class ProfileDetail extends AppRoute {
  @override
  Type get layout => HomeLayout;

  @override
  Uri toUri() => Uri.parse('/home/profile/detail');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile Detail Page', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Settings Routes (belong to SettingsLayout - navigatorStack layout)
// ============================================================================

class GeneralSettings extends AppRoute {
  @override
  Type get layout => SettingsLayout;

  @override
  Uri toUri() => Uri.parse('/settings/general');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'General Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: Text('Account Settings'),
          onTap: () => coordinator.push(AccountSettings()),
        ),
        ListTile(
          title: Text('Privacy Settings'),
          onTap: () => coordinator.push(PrivacySettings()),
        ),
      ],
    );
  }
}

class AccountSettings extends AppRoute {
  @override
  Type get layout => SettingsLayout;

  @override
  Uri toUri() => Uri.parse('/settings/account');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(title: Text('Email')),
        const ListTile(title: Text('Password')),
        const ListTile(title: Text('Delete Account')),
      ],
    );
  }
}

class PrivacySettings extends AppRoute {
  @override
  Type get layout => SettingsLayout;

  @override
  Uri toUri() => Uri.parse('/settings/privacy');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Privacy Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(title: Text('Data Privacy')),
        const ListTile(title: Text('Location Services')),
        const ListTile(title: Text('Analytics')),
      ],
    );
  }
}

// ============================================================================
// Not Found Route
// ============================================================================

class NotFound extends AppRoute {
  NotFound({required this.uri});

  final Uri uri;

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Route not found: ${uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.replace(HomeLayout()),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Coordinator
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug {
  // Navigation paths for different shells
  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  );
  late final NavigationPath<AppRoute> settingsStack = NavigationPath.createWith(
    label: 'settings',
    coordinator: this,
  );
  late final IndexedStackPath<AppRoute> tabIndexed =
      IndexedStackPath.createWith(coordinator: this, label: 'home-tabs', [
        FeedTabLayout(),
        ProfileTab(),
        SettingsTab(),
      ]);

  late final NavigationPath<AppRoute> feedTabStack = NavigationPath.createWith(
    label: 'feed-nested',
    coordinator: this,
  );

  @override
  void defineLayout() {
    RouteLayout.defineLayout(HomeLayout, HomeLayout.new);
    RouteLayout.defineLayout(SettingsLayout, SettingsLayout.new);
    RouteLayout.defineLayout(TabBarLayout, TabBarLayout.new);
    RouteLayout.defineLayout(FeedTabLayout, FeedTabLayout.new);
  }

  @override
  List<StackPath> get paths => [
    root,
    homeStack,
    settingsStack,
    tabIndexed,
    feedTabStack,
  ];

  @override
  List<AppRoute> get debugRoutes => [
    Login(),
    FeedTabLayout(),
    ProfileTab(),
    SettingsTab(),
    FeedDetail(id: '1'),
    ProfileDetail(),
    GeneralSettings(),
    AccountSettings(),
    PrivacySettings(),
    NotFound(uri: Uri.parse('/not-found')),
  ];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      // Root - default to feed tab (layouts will be set up automatically)
      [] => Login(),
      // Home routes - default to feed tab
      ['home'] => FeedTab(),
      ['home', 'tabs'] => FeedTab(), // Default to feed tab
      ['home', 'tabs', 'feed'] => FeedTab(),
      ['home', 'tabs', 'profile'] => ProfileTab(),
      ['home', 'tabs', 'settings'] => SettingsTab(),
      ['home', 'feed', final id] => FeedDetail(id: id),
      ['home', 'profile', 'detail'] => ProfileDetail(),
      // Settings routes - default to general settings
      ['settings'] => GeneralSettings(),
      ['settings', 'general'] => GeneralSettings(),
      ['settings', 'account'] => AccountSettings(),
      ['settings', 'privacy'] => PrivacySettings(),
      ['login'] => Login(),
      // Not found
      _ => NotFound(uri: uri),
    };
  }
}

class Login extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => coordinator.tryPop()),
        title: const Text('Login'),
      ),
      body: Center(
        child: TextButton(
          onPressed: () => coordinator.replace(FeedTab()),
          child: Text('Go to Feed'),
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
