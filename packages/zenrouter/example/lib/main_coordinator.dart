import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

// ============================================================================
// Main App Entry Point
// ============================================================================

void main() {
  runApp(const MyApp());
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
  late final NavigationPath<AppRoute> homeStack = NavigationPath.coordinator(
    debugLabel: 'home',
    coordinator: this,
  );
  late final NavigationPath<AppRoute> settingsStack =
      NavigationPath.coordinator(debugLabel: 'settings', coordinator: this);
  late final IndexedStackPath<AppRoute> tabIndexed =
      IndexedStackPath.coordinator(
        [FeedTabLayout(), ProfileTab(), SettingsTab()],
        debugLabel: 'home-tabs',
        coordinator: this,
      );

  late final NavigationPath<AppRoute> feedTabStack = NavigationPath.coordinator(
    debugLabel: 'feed-nested',
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
