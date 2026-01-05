/// # Deferred Imports
///
/// Lazy loading routes for improved startup performance - load code
/// only when (and if) the user navigates there.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'deferred-imports.g.dart';

/// The Deferred Imports documentation page.
@ZenRoute()
class DeferredImportsRoute extends _$DeferredImportsRoute
    with RouteSeo, RouteToc {
  @override
  String get title => 'Deferred Imports';

  @override
  String get description => 'Lazy Loading for Performance';

  @override
  String get keywords =>
      'Deferred Imports, Lazy Loading, Code Splitting, Performance';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Deferred Imports',
      subtitle: 'Lazy Loading for Performance',
      tocController: tocController,
      onTocItemsReady: (items) => tocItems.value = items,
      markdown: '''
Every route in your app contributes to its initial bundle size. For large applications with many routes, this can slow down startup - users wait longer before seeing anything, and on web, they download code they may never execute.

Deferred imports solve this: routes are loaded only when first navigated to. The initial bundle stays lean, and features load on demand.

## Enabling Deferred Imports

You can enable deferred imports per-route or globally.

```dart
// Per-Route Configuration
// Enable for a specific route
@ZenRoute(deferredImport: true)
class HeavyAdminPanelRoute extends _\$HeavyAdminPanelRoute {
  // This route and its dependencies load only when navigated to
}

// Disable for a critical route (when globally enabled)
@ZenRoute(deferredImport: false)
class HomeRoute extends _\$HomeRoute {
  // Always in initial bundle - no loading delay
}
```

```yaml
# build.yaml (Global Configuration)
# Enable deferred imports for all routes by default
targets:
  \$default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: true
```

## Precedence Rules

When both per-route and global configuration exist:

1. **Route annotation wins**: Explicit `deferredImport: false` overrides global config
2. **IndexedStack routes are always non-deferred**: Tab routes need to be immediately available for smooth tab switching
3. **Global config applies otherwise**: Routes without explicit annotation use the global setting

## Generated Code

With deferred imports, the generator produces async navigation:

```dart
// Generated imports
import 'about.dart' deferred as about;
import 'admin.dart' deferred as admin;
import 'home.dart';  // Non-deferred (explicit or IndexedStack)

// Generated parseRouteFromUri (now async)
@override
Future<AppRoute> parseRouteFromUri(Uri uri) async {
  return switch (uri.pathSegments) {
    [] => HomeRoute(),  // Immediate
    ['about'] => await () async {
      await about.loadLibrary();
      return about.AboutRoute();
    }(),
    ['admin'] => await () async {
      await admin.loadLibrary();
      return admin.AdminPanelRoute();
    }(),
    _ => NotFoundRoute(uri: uri),
  };
}

// Generated navigation (also async)
Future<T?> pushAbout<T extends Object>() async => push(await () async {
  await about.loadLibrary();
  return about.AboutRoute();
}());
```

## Performance Benefits

Real-world benchmarks show significant improvements:

| Metric | Without Deferred | With Deferred | Change |
|--------|------------------|---------------|--------|
| Initial bundle | 2,414 KB | 2,155 KB | -10.7% |
| Total app size | 2,719 KB | 2,759 KB | +1.5% |
| Deferred chunks | 0 | 24 | - |

**Key Benefits:**
- Initial bundle reduced by ~10-15%
- Faster time-to-interactive for users
- Better caching - unchanged routes don't re-download
- Code splitting happens automatically

**Trade-offs:**
- Slight navigation delay on first visit to deferred routes
- Small increase in total code size (~1-2%)
- Async nature propagates through navigation methods

> This documentation app uses deferred imports. Most pages load on-demand, keeping the initial bundle lean. The home page and critical navigation are non-deferred for instant interaction.
''',
    );
  }
}
