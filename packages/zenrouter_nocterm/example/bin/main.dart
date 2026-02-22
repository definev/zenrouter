import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_nocterm/zenrouter_nocterm.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulComponent {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final coordinator = AppCoordinator();

  @override
  Component build(BuildContext context) {
    return NoctermApp(child: CoordinatorComponent(coordinator: coordinator));
  }
}

// ============================================================================
// Coordinator
// ============================================================================

final class AppCoordinator extends Coordinator<AppRoute> {
  late final tabPath = IndexedStackPath.createWith(
    coordinator: this,
    label: 'tabs',
    [HomeTab(), SearchTab(), ProfileTab()],
  )..bindLayout(TabLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, tabPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] || ['home'] => HomeTab(),
      ['search'] => SearchTab(),
      ['profile'] => ProfileTab(),
      ['settings'] => SettingsRoute(),
      _ => HomeTab(),
    };
  }
}

// ============================================================================
// Route Base
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Tab Layout
// ============================================================================

class TabLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    return Column(
      children: [
        Expanded(child: buildPath(coordinator)),
        _TabBar(path: path),
      ],
    );
  }
}

class _TabBar extends StatelessComponent {
  const _TabBar({required this.path});

  final IndexedStackPath<AppRoute> path;

  @override
  Component build(BuildContext context) {
    return ListenableBuilder(
      listenable: path,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(border: BoxBorder(top: BorderSide())),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TabItem(
                label: '[ Home ]',
                isActive: path.activeIndex == 0,
                onTap: () => path.goToIndexed(0),
              ),
              _TabItem(
                label: '[ Search ]',
                isActive: path.activeIndex == 1,
                onTap: () => path.goToIndexed(1),
              ),
              _TabItem(
                label: '[ Profile ]',
                isActive: path.activeIndex == 2,
                onTap: () => path.goToIndexed(2),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabItem extends StatelessComponent {
  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : null,
            color: isActive ? Colors.green : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Tab Routes
// ============================================================================

class SettingsRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: 'Settings'),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⚙ Settings Page'),
              SizedBox(height: 1),
              Text(
                'Press ESC to go back',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.keyS) {
          coordinator.push(SettingsRoute());
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🏠 Home',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Press "s" to open Settings',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchTab extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/search');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Text(
        '🔍 Search',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
      ),
    );
  }
}

class ProfileTab extends AppRoute {
  @override
  Type get layout => TabLayout;

  @override
  Uri toUri() => Uri.parse('/profile');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Text(
        '👤 Profile',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.magenta),
      ),
    );
  }
}
