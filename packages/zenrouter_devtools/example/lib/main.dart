import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: appCoordinator.routerDelegate,
      routeInformationParser: appCoordinator.routeInformationParser,
    );
  }
}

final appCoordinator = AppCoordinator();

abstract class AppRoute extends RouteTarget with RouteUnique {}

class CustomLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  StackPath<RouteUnique> resolvePath(AppCoordinator coordinator) =>
      coordinator.customIndexed;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final path = resolvePath(coordinator);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: switch (size.width) {
        < 600 => Column(
          children: [
            Expanded(child: buildPath(coordinator)),
            Container(
              height: 60,
              color: Colors.yellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    child: Text('One'),
                    onPressed: () => coordinator.push(FirstLayout()),
                  ),
                  ElevatedButton(
                    child: Text('Two'),
                    onPressed: () => coordinator.push(SecondTab()),
                  ),
                  ElevatedButton(
                    child: Text('Three'),
                    onPressed: () => coordinator.push(ThirdTab()),
                  ),
                ],
              ),
            ),
          ],
        ),
        _ => Column(
          children: [
            Expanded(
              child: switch (path.activeRoute) {
                ThirdTab() => path.activeRoute!.build(coordinator, context),
                _ => Row(
                  children: [
                    Expanded(child: path.stack[0].build(coordinator, context)),
                    VerticalDivider(width: 1, color: Colors.amber),
                    Expanded(child: path.stack[1].build(coordinator, context)),
                  ],
                ),
              },
            ),
            Container(
              height: 60,
              color: Colors.yellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    child: Text('One/Two'),
                    onPressed: () {
                      if (path.activeRoute is FirstLayout) {
                        coordinator.push(SecondTab());
                      } else {
                        coordinator.push(FirstLayout());
                      }
                    },
                  ),
                  ElevatedButton(
                    child: Text('Three'),
                    onPressed: () => coordinator.push(ThirdTab()),
                  ),
                ],
              ),
            ),
          ],
        ),
      },
    );
  }
}

class FirstLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/first');

  @override
  Type get layout => CustomLayout;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.firstStack;
}

class FirstTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/first');

  @override
  Type get layout => FirstLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final activeIndex = coordinator.customIndexed.activeIndex;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              'First page ${activeIndex == 0 ? '(Focused)' : '(No focused)'}',
            ),
            FilledButton(
              onPressed: () =>
                  coordinator.push(FirstTabChild(message: "Hello")),
              child: Text('Go "Hello"'),
            ),
            FilledButton(
              onPressed: () => coordinator.push(FirstTabChild(message: "Ciao")),
              child: Text('Go "Ciao"'),
            ),
          ],
        ),
      ),
    );
  }
}

class FirstTabChild extends AppRoute {
  FirstTabChild({required this.message});

  final String message;

  @override
  Uri toUri() => Uri.parse('/first/$message');

  @override
  Type get layout => FirstLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('First Message: $message'),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [message];
}

class SecondTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/second');

  @override
  Type get layout => CustomLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final activeIndex = coordinator.customIndexed.activeIndex;
    return Scaffold(
      backgroundColor: Colors.red.shade100,
      body: Center(
        child: Text(
          'Second tab (${activeIndex == 1 ? 'Focused' : 'No focused'})',
        ),
      ),
    );
  }
}

class ThirdTab extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/third');

  @override
  Type get layout => CustomLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final activeIndex = coordinator.customIndexed.activeIndex;
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: Center(
        child: Text(
          'Third tab (${activeIndex == 2 ? 'Focused' : 'No focused'})',
        ),
      ),
    );
  }
}

class NotFound extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Center(child: Text('Not found')));
  }
}

class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug {
  late final customIndexed = IndexedStackPath<AppRoute>.createWith(
    coordinator: this,
    label: 'CustomIndexed',
    [FirstLayout(), SecondTab(), ThirdTab()],
  );
  late final firstStack = NavigationPath<AppRoute>.createWith(
    label: 'FirstStack',
    coordinator: this,
  );

  @override
  List<AppRoute> get debugRoutes => [
    FirstTab(),
    FirstTabChild(message: 'Hello'),
    FirstTabChild(message: 'Ciao'),
    SecondTab(),
    ThirdTab(),
    NotFound(),
  ];

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    customIndexed,
    firstStack,
  ];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(CustomLayout, CustomLayout.new);
    RouteLayout.defineLayout(FirstLayout, FirstLayout.new);
  }

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => FirstTab(),
      ['first'] => FirstTab(),
      ['first', final message] => FirstTabChild(message: message),
      ['second'] => SecondTab(),
      ['third'] => ThirdTab(),
      _ => NotFound(),
    };
  }
}
