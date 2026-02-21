library;

/**
 * A complete example demonstrating state restoration in ZenRouter.
 *
 * ## What This Example Demonstrates
 *
 * This example shows how to implement full state restoration for a navigation hierarchy,
 * allowing the app to survive process death and return users to exactly where they left off.
 * It demonstrates both simple URI-based restoration (for [Home] and [Bookmark] routes) and
 * custom converter-based restoration (for [BookmarkDetail] with complex state).
 *
 * ## How to Test Restoration
 *
 * **On iOS Simulator:**
 * 1. Run the app and navigate through several screens
 * 2. Background the app (Cmd+Shift+H)
 * 3. In Xcode: Debug → Simulate Memory Warning
 * 4. Or use Device → Erase All Content and Settings, then restore
 * 5. Relaunch the app - it should return to the same screen
 *
 * **On Android Emulator:**
 * 1. Run the app and navigate through screens
 * 2. Background the app (Home button)
 * 3. Use `adb shell am kill <package>` to terminate
 * 4. Relaunch - restoration should occur
 *
 * ## How the Components Work Together
 *
 * **MaterialApp setup:**
 * The `restorationScopeId: 'main_restorable'` enables Flutter's restoration framework.
 * The [CoordinatorRouterDelegate] automatically wraps your app with [CoordinatorRestorable]
 * internally, so you don't need to do any manual wrapping. Without the restorationScopeId,
 * no restoration will occur regardless of other setup.
 *
 * **Simple routes (Home, Bookmark):**
 * These routes only implement [RouteUnique], so they're automatically saved and restored
 * using their URI. When restored, the coordinator's `parseRouteFromUri` method converts
 * the saved URI string back into route objects.
 *
 * **Complex route (BookmarkDetail):**
 * This route mixes in [RouteRestorable] with a custom [BookmarkDetailConverter] to preserve
 * the `name` parameter that wouldn't normally be in the URL. The converter serializes both
 * the id and name, allowing the route to be perfectly reconstructed with all its state.
 *
 * **Coordinator registration (AppCoordinator.defineConverter - line 75-79):**
 * The converter must be registered globally during coordinator initialization. This makes
 * it available to the restoration system when deserializing saved state.
 *
 * **Widget state (HomeView with RestorableInt):**
 * The counter in HomeView demonstrates that widget-level state (the count) is separate
 * from navigation state. Each screen needing to persist its own state must implement
 * [RestorationMixin] independently.
 *
 * ## What Gets Restored
 *
 * ✅ **Navigation stack:** All routes in the navigation history
 * ✅ **Active route:** Which screen was visible when the app was backgrounded
 * ✅ **Route parameters:** Both URL parameters and custom converter data
 * ✅ **Widget state:** Any widgets using [RestorationMixin] (like the counter)
 *
 * ❌ **Not restored automatically:**
 * - Network requests or API data (refetch on restore)
 * - Form inputs without [RestorationMixin]
 * - Scroll positions without restoration IDs
 * - In-memory caches or temporary data
 *
 * See the restoration documentation in [CoordinatorRestorable], [RouteRestorable],
 * and [RestorableConverter] for detailed implementation guidance.
 */
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

abstract class AppRoute extends RouteTarget with RouteUnique {}

class Home extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      HomeView();
}

class Bookmark extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/bookmark');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      BookmarkView();
}

class BookmarkDetail extends AppRoute with RouteRestorable<BookmarkDetail> {
  BookmarkDetail({required this.id, this.name});

  final String id;
  final String? name;

  @override
  String get restorationId => 'bookmark_${id}_$name';

  @override
  RestorationStrategy get restorationStrategy => RestorationStrategy.converter;

  @override
  RestorableConverter<BookmarkDetail> get converter =>
      const BookmarkDetailConverter();

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/bookmark/$id');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      BookmarkDetailView(id: id, name: name);
}

class BookmarkDetailConverter extends RestorableConverter<BookmarkDetail> {
  const BookmarkDetailConverter();

  static const staticKey = 'bookmark_detail';

  @override
  String get key => staticKey;

  @override
  Map<String, dynamic> serialize(BookmarkDetail route) {
    return {'id': route.id, 'name': route.name};
  }

  @override
  BookmarkDetail deserialize(Map<String, dynamic> data) {
    return BookmarkDetail(
      id: data['id'] as String,
      name: data['name'] as String?,
    );
  }
}

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  void defineConverter() {
    defineRestorableConverter(
      BookmarkDetailConverter.staticKey,
      BookmarkDetailConverter.new,
    );
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    [] => Home(),
    ['bookmark'] => Bookmark(),
    ['bookmark', final id] => BookmarkDetail(id: id),
    _ => throw UnimplementedError(),
  };
}

void main() {
  runApp(
    MaterialApp.router(
      // ADD THIS LINE FOR RESTORATION WORKING
      restorationScopeId: 'main_restorable',
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    ),
  );
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with RestorationMixin {
  final RestorableInt _counter = RestorableInt(0);

  @override
  String? get restorationId => 'home';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_counter, 'count');
  }

  void _incrementCounter() {
    setState(() {
      _counter.value++;
    });
  }

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Restorable')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '${_counter.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            FilledButton(
              onPressed: () => coordinator.pushOrMoveToTop(Bookmark()),
              child: Text('Bookmark'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class BookmarkView extends StatefulWidget {
  const BookmarkView({super.key});

  @override
  State<BookmarkView> createState() => _BookmarkViewState();
}

class _BookmarkViewState extends State<BookmarkView> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmark')),
      body: Column(
        children: [
          TextField(onChanged: (value) => _text = value),
          Expanded(
            child: ListView.builder(
              restorationId: 'bookmark_list',
              itemCount: 100,
              itemBuilder: (context, index) => ListTile(
                title: Text('Bookmark $index'),
                onTap: () => coordinator.pushOrMoveToTop(
                  BookmarkDetail(id: index.toString(), name: _text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookmarkDetailView extends StatelessWidget {
  const BookmarkDetailView({super.key, required this.id, this.name});

  final String id;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bookmark $id')),
      body: Center(child: Text(name ?? 'No name')),
    );
  }
}

final coordinator = AppCoordinator();
