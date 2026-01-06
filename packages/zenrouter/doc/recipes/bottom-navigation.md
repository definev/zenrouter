# Recipe: Bottom Navigation with Persistent State

## Problem

Your app has a bottom navigation bar with multiple tabs (e.g., Home, Search, Profile), and you want each tab to maintain its own navigation stack. When users switch tabs and come back, they should see where they left off—not reset to the tab's root page.

## Solution Overview

ZenRouter's **IndexedStackPath** is designed specifically for this use case. Unlike traditional navigation that replaces the screen, `IndexedStackPath`:

- Keeps all tab screens alive in memory
- Maintains each tab's navigation state
- Provides instant tab switching (no rebuild)
- Works with both Coordinator and Imperative paradigms

## Complete Code Example

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// 1. Define routes for each tab
abstract class AppRoute extends RouteTarget with RouteUnique {}

class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.tabPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return RootLayout(
      coordinator: coordinator,
      child: buildPath(coordinator),
    );
  }
}

// Home tab routes
class HomeTabRoute extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return HomePage();
  }
}

class ArticleRoute extends AppRoute {
  final String articleId;
  ArticleRoute(this.articleId);

  Type get layout => TabLayout;
  
  @override
  List<Object?> get props => [articleId];
  
  @override
  Uri toUri() => Uri.parse('/article/$articleId');
  
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ArticlePage(articleId: articleId);
  }
}

// Search tab routes
class SearchTabRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/search');
  
  @override
  Type get layout => TabLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return const SearchPage();
  }
}

class SearchResultsRoute extends AppRoute {
  final String query;
  SearchResultsRoute(this.query);
  
  @override
  List<Object?> get props => [query];
  
  @override
  Uri toUri() => Uri.parse('/search/results').replace(
        queryParameters: {'q': query},
      );
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return SearchResultsPage(query: query);
  }
}

// Profile tab routes
class ProfileTabRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/profile');

  @override
  Type get layout => TabLayout;
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const ProfilePage();
  }
}

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/profile/settings');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return const SettingsPage();
  }
}

// 2. Create a Coordinator with IndexedStackPath
class AppCoordinator extends Coordinator<AppRoute> {
  // Create an IndexedStackPath for tab navigation
  late final tabPath = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'tab',
    [
      HomeTabRoute(),
      SearchTabRoute(),
      ProfileTabRoute(),
    ],
  )..bindLayout(TabLayout.new);
  
  @override
  List<StackPath<AppRoute>> get paths => [...super.paths, tabPath];
  
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeTabRoute(),
      ['article', String id] => ArticleRoute(id),
      ['search'] => SearchTabRoute(),
      ['search', 'results'] => SearchResultsRoute(
          uri.queryParameters['q'] ?? '',
        ),
      ['profile'] => ProfileTabRoute(),
      ['profile', 'settings'] => SettingsRoute(),
      _ => NotFoundRoute(),
    };
  }
  
  // Helper methods for tab navigation
  void switchToTab(int index) {
    tabPath.activeIndex = index;
  }
  
  int get currentTab => tabPath.activeIndex;
}

// 3. Main app with bottom navigation
class MyApp extends StatelessWidget {
  final coordinator = AppCoordinator();
  
  MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// 4. Root layout with bottom navigation bar
class RootLayout extends StatelessWidget {
  final AppCoordinator coordinator;
  final Widget child;
  
  const RootLayout({
    super.key,
    required this.coordinator,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: ListenableBuilder(
        listenable: coordinator.tabPath,
        builder: (context, _) {
          return BottomNavigationBar(
            currentIndex: coordinator.currentTab,
            onTap: coordinator.switchToTab,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

// 5. Example tab content with nested navigation
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Article ${index + 1}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Push article route onto the home tab's stack
              coordinator.push(ArticleRoute('article-${index + 1}'));
            },
          );
        },
      ),
    );
  }
}

class ArticlePage extends StatelessWidget {
  final String articleId;
  
  const ArticlePage({super.key, required this.articleId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article: $articleId'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Article Content',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('ID: $articleId'),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final coordinator = context.coordinator<AppCoordinator>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      coordinator.push(
                        SearchResultsRoute(_searchController.text),
                      );
                    }
                  },
                ),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  coordinator.push(SearchResultsRoute(query));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SearchResultsPage extends StatelessWidget {
  final String query;
  
  const SearchResultsPage({super.key, required this.query});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results for "$query"'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Result ${index + 1} for "$query"'),
            subtitle: Text('Description of result ${index + 1}'),
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    final coordinator = context.coordinator<AppCoordinator>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('John Doe'),
            subtitle: Text('john.doe@example.com'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              coordinator.push(SettingsRoute());
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to about page
            },
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          SwitchListTile(
            title: Text('Notifications'),
            subtitle: Text('Enable push notifications'),
            value: true,
            onChanged: null,
          ),
          SwitchListTile(
            title: Text('Dark Mode'),
            subtitle: Text('Use dark theme'),
            value: false,
            onChanged: null,
          ),
        ],
      ),
    );
  }
}
```

## Step-by-Step Explanation

### 1. Create an IndexedStackPath with Layout Binding

```dart
late final tabPath = IndexedStackPath<AppRoute>.createWith(
  coordinator: this,
  label: 'tab',
  [
    HomeTabRoute(),
    SearchTabRoute(),
    ProfileTabRoute(),
  ],
)..bindLayout(TabLayout.new);
```

- `IndexedStackPath.createWith()` creates the path with initial routes
- Pass the coordinator reference and a label for identification
- Provide initial routes as a list (one per tab)
- `..bindLayout(TabLayout.new)` binds the layout that will wrap all tab content
- The `TabLayout` class handles rendering the bottom navigation bar and child content

### 2. Expose the Path in Coordinator

```dart
@override
List<StackPath<AppRoute>> get paths => [...super.paths, tabPath];
```

This tells ZenRouter to use the `tabPath` for navigation. All `push()`, `pop()`, and `replace()` operations will affect the currently active tab's stack.

> **Note:** You have to call `super.paths` to include the default paths.

### 3. Tab Switching

```dart
void switchToTab(int index) {
  tabPath.activeIndex = index;
}
```

Changing `activeIndex` switches the visible tab instantly. Each tab retains its navigation state.

### 4. Listen to Tab Changes

```dart
ListenableBuilder(
  listenable: coordinator.tabPath,
  builder: (context, _) {
    return BottomNavigationBar(
      currentIndex: coordinator.currentTab,
      onTap: coordinator.switchToTab,
      items: const [...],
    );
  },
)
```

`IndexedStackPath` is a `Listenable`, so you can rebuild UI when the active tab changes.

## Advanced Variations

### Per-Tab Navigation Stacks

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  // Separate NavigationPath for each tab
  late final homeStack = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'home',
  );
  late final searchStack = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'search',
  );
  late final profileStack = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'profile',
  );
  
  late final tabPath = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'tab',
    [
      HomeTabRoute(),
      SearchTabRoute(),
      ProfileTabRoute(),
    ],
  );
  
  int _currentTab = 0;
  
  @override
  List<StackPath<AppRoute>> get paths => [
    ...super.paths,
    tabPath,
    homeStack,
    searchStack,
    profileStack,
  ];
  
  
  void switchToTab(int index) {
    _currentTab = index;
    tabPath.activeIndex = index;
  }
}
```

### Reset Tab on Double Tap

```dart
class RootLayout extends StatelessWidget {
  // ...
  
  void _handleTabTap(int index) {
    if (coordinator.currentTab == index) {
      // User tapped the already active tab - reset the tab stack
    } else {
      coordinator.switchToTab(index);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: coordinator.currentTab,
        onTap: _handleTabTap, // Use custom handler
        items: const [...],
      ),
    );
  }
}
```

### Badge Notifications

```dart
class RootLayout extends StatelessWidget {
  // ...
  
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: const Text('3'),
            child: const Icon(Icons.search),
          ),
          label: 'Search',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
```

## Common Gotchas

> [!TIP]
> **Use RootLayout wisely**
> Wrap each tab's content in a shared `RootLayout` widget that contains the bottom navigation bar. This prevents the tab bar from disappearing when navigating within a tab.

> [!CAUTION]
> **Memory considerations**
> `IndexedStackPath` keeps all tabs in memory. If your tabs have heavy content or media, consider using lazy loading or disposing unused content.

> [!NOTE]
> **Back button behavior**
> On Android, the back button will pop the current tab's stack first. Only when the tab is at its root will back button switch to the previous tab or exit the app.

> [!WARNING]
> **State restoration**
> If using state restoration, ensure each tab's state is properly serialized. See the [State Restoration Guide](../guides/state-restoration.md) for details.

## Related Recipes

- [Nested Navigation](nested-navigation.md) - Complex nested navigation patterns
- [State Management Integration](state-management.md) - Manage tab state with Riverpod/Bloc
- [Authentication Flow](authentication-flow.md) - Protect tabs with authentication

## See Also

- [IndexedStackPath API](../api/navigation-paths.md#indexedstackpath)
- [Coordinator Pattern Guide](../paradigms/coordinator/coordinator.md)
