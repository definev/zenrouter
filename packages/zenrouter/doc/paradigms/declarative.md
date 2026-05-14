# Declarative Navigation

> **Define what the stack should look like, not how to build it**

The declarative paradigm lets you define your navigation stack as a function of your app's state. Instead of imperatively calling `push()` and `pop()`, you declare what routes should be present and let ZenRouter efficiently update the stack using Myers diff algorithm.

## When to Use Declarative Navigation

✅ **Use declarative navigation when:**
- Your navigation is driven by state changes (selected tab, list items, filters)
- You want React-like declarative UI for navigation
- You need efficient stack updates with minimal operations
- Your navigation stack mirrors your app state
- You're building tabbed interfaces or filtered lists

❌ **Don't use declarative navigation when:**
- Navigation is primarily event-driven (use [Imperative](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) instead)
- You need deep linking or web URLs (use [Coordinator](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator/coordinator.md) instead)
- You need fine-grained control over push/pop operations

## Core Concept

In declarative navigation, you define the desired navigation stack based on your state, and ZenRouter automatically calculates the minimal set of operations needed to update the actual stack.

```dart
// Your state
int selectedPage = 1;
bool showSpecial = false;

// Your navigation stack is derived from state
NavigationStack.declarative(
  routes: [
    HomePage(),
    if (selectedPage > 0) PageRoute(selectedPage),
    if (showSpecial) SpecialRoute(),
  ],
  resolver: (route) => StackTransition.material(
    route.build(context),
  ),
)
```

When state changes, only the **changed routes** are added or removed - existing routes are preserved! This is powered by the **Myers diff algorithm**.

## How Myers Diff Works

Myers diff is an efficient algorithm that finds the minimal set of operations to transform one list into another.

### Example: Adding a Page

```dart
// Before (state: pages = [1, 2])
Stack: [Page1, Page2]

// After (state: pages = [1, 2, 3])
Stack: [Page1, Page2, Page3]

// Myers diff operation: INSERT Page3 at end
// ✅ Page1 and Page2 are preserved (not recreated!)
```

### Example: Removing a Page

```dart
// Before (state: pages = [1, 2, 3])
Stack: [Page1, Page2, Page3]

// After (state: pages = [1, 3])
Stack: [Page1, Page3]

// Myers diff operation: DELETE Page2
// ✅ Page1 and Page3 are preserved!
```

### Why This Matters

Without diff, changing the stack would destroy and recreate all routes, losing:
- Widget state (scroll position, form inputs, etc.)
- Animation continuity
- Performance

With Myers diff, only the minimal changes are applied, preserving everything else!

## Complete Example: Dynamic Page List

This example shows a list of pages that can be added or removed. Watch how the counter state is preserved when you add/remove other pages!

### Step 1: Define Your Routes

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// Route with a parameter
class PageRoute extends RouteTarget {
  final int pageNumber;
  
  PageRoute(this.pageNumber);
  
  // IMPORTANT: Must implement equality for diff to work!
  @override
  List<Object?> get props => [pageNumber];
}

class SpecialRoute extends RouteTarget {}
```

> **⚠️ Critical:** Routes **must** implement `==` and `hashCode` correctly for Myers diff to identify which routes changed!

### Step 2: Create Stateful Widget with State

```dart
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // State: list of page numbers to show
  final List<int> _pageNumbers = [1];
  int _nextPageNumber = 2;
  bool _showSpecial = false;
  
  void _addPage() {
    setState(() {
      _pageNumbers.add(_nextPageNumber);
      _nextPageNumber++;
    });
  }
  
  void _removePage(int pageNumber) {
    setState(() {
      _pageNumbers.remove(pageNumber);
    });
  }
  
  void _toggleSpecial() {
    setState(() {
      _showSpecial = !_showSpecial;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Declarative navigation stack
          Expanded(
            child: NavigationStack.declarative(
              routes: [
                // Derive routes from state
                for (final pageNumber in _pageNumbers) 
                  PageRoute(pageNumber),
                if (_showSpecial) 
                  SpecialRoute(),
              ],
              resolver: (route) => switch (route) {
                SpecialRoute() => StackTransition.sheet(
                  _buildSpecialPage(),
                ),
                PageRoute(:final pageNumber) => StackTransition.material(
                  PageView(pageNumber: pageNumber),
                ),
                _ => throw UnimplementedError(),
              },
            ),
          ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _showSpecial,
                      onChanged: (_) => _toggleSpecial(),
                    ),
                    const Text('Show special page'),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addPage,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Page'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: _pageNumbers.map((pageNum) {
                    return Chip(
                      label: Text('Page $pageNum'),
                      onDeleted: _pageNumbers.length > 1
                          ? () => _removePage(pageNum)
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpecialPage() {
    return Scaffold(
      appBar: AppBar(title: const Text('Special Route')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => setState(() => _showSpecial = false),
          child: const Text('Close'),
        ),
      ),
    );
  }
}
```

### Step 3: Build Stateful Page Widget

This widget demonstrates **state preservation** - the counter is preserved when other pages are added/removed:

```dart
class PageView extends StatefulWidget {
  final int pageNumber;
  
  const PageView({super.key, required this.pageNumber});
  
  @override
  State<PageView> createState() => _PageViewState();
}

class _PageViewState extends State<PageView> {
  int _counter = 0; // Widget state
  
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${widget.pageNumber}'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('State Preservation Demo'),
            const SizedBox(height: 16),
            Text(
              'Counter: $_counter',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _incrementCounter,
              icon: const Icon(Icons.add),
              label: const Text('Increment'),
            ),
            const SizedBox(height: 32),
            Text(
              'Try adding/removing other pages.\\n'
              'This counter stays preserved!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

For complete API documentation including all methods and parameters, see:

**[→ Navigation Paths API Reference](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#navigationstackdeclarative)**

Quick reference for `NavigationStack.declarative`:

| Parameter | Required | Description |
|-----------|----------|-------------|
| `routes` | ✅ Yes | List of routes derived from state |
| `resolver` | ✅ Yes | Function converting routes to `StackTransition` |
| `navigatorKey` | ❌ No | Key for accessing navigator state |
| `debugLabel` | ❌ No | Label for debugging |

**StackTransition types:**

| Type | Behavior |
|------|----------|
| `.material(child)` | Material page transition (platform adaptive) |
| `.cupertino(child)` | iOS-style slide from right |
| `.sheet(child)` | Bottom sheet presentation |
| `.dialog(child)` | Dialog presentation |
| `.custom(...)` | Custom transition with full control |

See [StackTransition API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#stacktransition) for detailed examples.


## State Patterns

### Pattern: Tab Navigation

Derive navigation from selected tab index:

```dart
class TabNavigation extends StatefulWidget {
  @override
  State<TabNavigation> createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  int _selectedTab = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigationStack.declarative(
        routes: [
          // Base route always present
          HomeRoute(),
          // Active tab route
          switch (_selectedTab) {
            0 => FeedRoute(),
            1 => ProfileRoute(),
            2 => SettingsRoute(),
            _ => FeedRoute(),
          },
        ],
        resolver: (route) => StackTransition.material(
          route.build(context),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

### Pattern: Filtered List

Derive navigation from list filters:

```dart
class FilteredListNavigation extends StatefulWidget {
  @override
  State<FilteredListNavigation> createState() => _FilteredListNavigationState();
}

class _FilteredListNavigationState extends State<FilteredListNavigation> {
  String _searchQuery = '';
  String _category = 'all';
  
  List<Item> get _filteredItems {
    return allItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory = _category == 'all' || item.category == _category;
      return matchesSearch && matchesCategory;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter controls
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(hintText: 'Search...'),
          ),
          DropdownButton<String>(
            value: _category,
            onChanged: (value) => setState(() => _category = value!),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All')),
              DropdownMenuItem(value: 'tech', child: Text('Tech')),
              DropdownMenuItem(value: 'food', child: Text('Food')),
            ],
          ),
          
          // Declarative navigation based on filters
          Expanded(
            child: NavigationStack.declarative(
              routes: [
                ListRoute(),
                for (final item in _filteredItems)
                  ItemRoute(item.id),
              ],
              resolver: (route) => switch (route) {
                ListRoute() => StackTransition.material(
                  ListScreen(items: _filteredItems),
                ),
                ItemRoute(:final id) => StackTransition.material(
                  ItemDetailScreen(id: id),
                ),
                _ => throw UnimplementedError(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Pattern: Wizard Flow with Steps

Derive navigation from current step:

```dart
class WizardNavigation extends StatefulWidget {
  @override
  State<WizardNavigation> createState() => _WizardNavigationState();
}

class _WizardNavigationState extends State<WizardNavigation> {
  int _currentStep = 0;
  WizardData _data = const WizardData();
  
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }
  
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return NavigationStack.declarative(
      routes: [
        WelcomeRoute(),
        if (_currentStep >= 0) Step1Route(data: _data),
        if (_currentStep >= 1) Step2Route(data: _data),
        if (_currentStep >= 2) Step3Route(data: _data),
      ],
      resolver: (route) => StackTransition.material(
        route.build(context, onNext: _nextStep, onPrev: _prevStep),
      ),
    );
  }
}
```

## Best Practices

### ✅ DO: Implement Equality Correctly

Routes **must** implement `==` and `hashCode` for Myers diff to work, make sure you call `compareWith` to align with underline `RouteTarget` comparing logic.

```dart
class ItemRoute extends RouteTarget {
  final String itemId;
  
  ItemRoute(this.itemId);
  
  @override
  List<Object?> get props => [itemId];
}
```

Without proper equality, Myers diff can't identify unchanged routes and will recreate them unnecessarily!

### ✅ DO: Derive Routes from Single Source of Truth

Keep your state in one place and derive everything from it:

```dart
class AppState {
  final List<Item> selectedItems;
  final bool showDetails;
  final String? activeItemId;
}

// Derive routes from AppState
List<RouteTarget> buildRoutes(AppState state) {
  return [
    HomeRoute(),
    for (final item in state.selectedItems)
      ItemRoute(item.id),
    if (state.showDetails && state.activeItemId != null)
      DetailRoute(state.activeItemId!),
  ];
}
```

### ❌ DON'T: Mutate the Routes List

Don't modify the routes list after passing it - create a new list:

```dart
// ❌ BAD
final routes = [HomeRoute()];
routes.add(ProfileRoute()); // Mutation
NavigationStack.declarative(routes: routes, ...)

// ✅ GOOD
NavigationStack.declarative(
  routes: [
    HomeRoute(),
    ProfileRoute(),
  ],
  ...
)
```

### ❌ DON'T: Forget to Call setState

The stack only updates when you rebuild with new routes:

```dart
// ❌ BAD
void addPage() {
  _pages.add(PageRoute(2)); // Stack won't update!
}

// ✅ GOOD
void addPage() {
  setState(() {
    _pages.add(PageRoute(2)); // Triggers rebuild
  });
}
```

## Performance Characteristics

### Myers Diff Complexity

- **Time complexity:** O((N+M)D) where N and M are list lengths, D is the edit distance
- **Space complexity:** O((N+M)D)

For most navigation scenarios (small lists, few changes), this is very fast!

### Optimization Tips

1. **Implement equality correctly** - This lets Myers diff skip unchanged routes
2. **Use const constructors** - Flutter can skip widget rebuilds
3. **Avoid large route lists** - Keep navigation depth reasonable (< 10 routes typically)
4. **Batch state changes** - Update state once instead of multiple times

```dart
// ❌ BAD: Multiple setState calls
void updateFilters() {
  setState(() => _category = 'tech');    // Rebuild+diff
  setState(() => _searchQuery = 'phone'); // Rebuild+diff
}

// ✅ GOOD: Single setState call
void updateFilters() {
  setState(() {
    _category = 'tech';
    _searchQuery = 'phone';
  }); // Single rebuild+diff
}
```

## Transition to Other Paradigms

### Moving to Imperative

If you need more direct control over navigation timing:

```dart
// Instead of deriving stack from state...
NavigationStack.declarative(
  routes: [if (showDetail) DetailRoute()],
  resolver: resolver,
)

// ...use imperative push/pop at the right moment
onTap: () => path.push(DetailRoute())
```

### Moving to Coordinator

If you need deep linking or web support:

```dart
// Create new abstract route for your Coordinator
abstract class AppRoute extends RouteTarget with RouteUnique {}

class MyRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/my-route');
  
  @override
  Widget build(Coordinator coordinator, BuildContext context) {
    return MyScreen();
  }
}

// Still use declarative style with Coordinator
class AppCoordinator extends Coordinator<AppRoute> {
  void updateNavigation(AppState state) {
    root.replace([
      HomeRoute(),
      for (final item in state.items) ItemRoute(item.id),
    ]);
  }
}
```

## See Also

- [Imperative Navigation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/imperative.md) - Direct stack control
- [Coordinator Pattern](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/paradigms/coordinator/coordinator.md) - Deep linking and web support
- [Myers Diff Implementation](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#navigationstackdeclarative) - Algorithm details
- [DeclarativeNavigationStack API](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/api/navigation-paths.md#navigationstackdeclarative) - Complete API reference
