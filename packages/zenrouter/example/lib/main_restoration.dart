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

class BookmarkDetail extends AppRoute {
  BookmarkDetail({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/bookmark/$id');

  @override
  Widget build(Coordinator<AppRoute> coordinator, BuildContext context) =>
      BookmarkDetailView(id: id);
}

class AppCoodinator extends Coordinator<AppRoute> {
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

class BookmarkView extends StatelessWidget {
  const BookmarkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmark')),
      body: ListView.builder(
        restorationId: 'bookmark_list',
        itemCount: 100,
        itemBuilder: (context, index) => ListTile(
          title: Text('Bookmark $index'),
          onTap: () =>
              coordinator.pushOrMoveToTop(BookmarkDetail(id: index.toString())),
        ),
      ),
    );
  }
}

class BookmarkDetailView extends StatelessWidget {
  const BookmarkDetailView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Bookmark $id')));
  }
}

final coordinator = AppCoodinator();
