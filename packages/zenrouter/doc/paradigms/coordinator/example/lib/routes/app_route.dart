import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'coordinator.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeIndexed;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);

    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: path.activeIndex,
        onTap: (index) {
          coordinator.push(path.stack[index]);

          /// Ensure the selected tab is not empty
          switch (index) {
            case 0:
              if (coordinator.feedNavigation.stack.isEmpty) {
                coordinator.push(PostList());
              }
            case 1:
              if (coordinator.profileNavigation.stack.isEmpty) {
                coordinator.push(Profile());
              }
          }
        },
      ),
    );
  }
}

class FeedLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.feedNavigation;

  @override
  Type? get layout => HomeLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return buildPath(coordinator);
  }
}

class ProfileLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.profileNavigation;

  @override
  Type? get layout => HomeLayout;
}

class PostList extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/post');

  /// `PostList` will be rendered inside `FeedLayout`
  @override
  Type? get layout => FeedLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    // Scaffold is important here because NavigationStack doesn't provide one
    return Scaffold(
      appBar: AppBar(title: const Text('Post List')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Post 1'),
            onTap: () => coordinator.push(PostDetail(id: 1)),
          ),
          ListTile(
            title: const Text('Post 2'),
            onTap: () => coordinator.push(PostDetail(id: 2)),
          ),
        ],
      ),
    );
  }
}

class PostDetail extends AppRoute {
  PostDetail({required this.id});

  final int id;

  /// If the params has involved in `toUri` function, you must add it to `props`
  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/post/$id');

  @override
  Type? get layout => FeedLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post $id Detail')),
      body: Center(child: Text('Post ID: $id')),
    );
  }
}

class Profile extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/profile');

  /// `ProfileView` will be rendered inside `ProfileLayout`
  @override
  Type? get layout => ProfileLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const ListTile(title: Text('Hello, User')),
          ListTile(
            title: const Text('Open Settings'),
            onTap: () => coordinator.push(Settings()),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class Settings extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  /// `SettingsView` will be rendered inside `ProfileLayout`
  @override
  Type? get layout => ProfileLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings View')),
    );
  }
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});

  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('Route not found: $uri')),
    );
  }
}

class IndexRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  AppRoute redirect() => PostList();

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const SizedBox.shrink();
  }
}
