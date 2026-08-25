// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

import '_layout.dart';
import 'docs/_layout.dart';
import 'docs/chapter/[slug].dart' deferred as docs_chapter__slug;
import 'docs/index.dart' deferred as docs_index;
import 'index.dart' deferred as index;
import 'not_found.dart';

export 'package:zenrouter/zenrouter.dart';
export '_layout.dart';
export 'docs/_layout.dart';
export 'not_found.dart';

/// Base class for all routes in this application.
abstract class DocsRoute extends RouteTarget with RouteUnique {}

/// Generated coordinator managing all routes.
class DocsCoordinator extends Coordinator<DocsRoute>
    with RouteModuleBinding<DocsRoute, String> {
  /// Immutable application route topology.
  static final RouteManifest<String> manifest = RouteManifest<String>(
    name: 'DocsCoordinator',
    routes: [
      RouteManifestRoute(
        id: 'ChapterSlugRoute',
        path: '/docs/chapter/:slug',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'DocsIndexRoute',
        path: '/docs',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(id: 'IndexRoute', path: '/'),
    ],
    layouts: [
      RouteManifestLayout.stack(id: 'RootLayout', path: '/'),
      RouteManifestLayout.stack(id: 'DocsLayout', path: '/docs'),
    ],
  );

  /// Type-safe reverse routing without constructing presentation routes.
  static const location = DocsCoordinatorLocation();

  /// Presentation bindings from manifest IDs to route targets.
  @override
  late final routeBindings = manifest.bind<DocsRoute>(
    bindings: [
      RouteBinding.deferred(
        id: 'ChapterSlugRoute',
        loadLibrary: docs_chapter__slug.loadLibrary,
        create: (match) => docs_chapter__slug.ChapterSlugRoute(
          slug: match.pathParameters['slug']!,
        ),
      ),
      RouteBinding.deferred(
        id: 'DocsIndexRoute',
        loadLibrary: docs_index.loadLibrary,
        create: (_) => docs_index.DocsIndexRoute(),
      ),
      RouteBinding.deferred(
        id: 'IndexRoute',
        loadLibrary: index.loadLibrary,
        create: (_) => index.IndexRoute(),
      ),
    ],
    notFound: (uri) => NotFoundRoute(uri: uri, queries: uri.queryParameters),
  );

  late final rootPath = NavigationPath<DocsRoute>.createWith(
    coordinator: this,
    label: 'Root',
  )..bindLayout(RootLayout.new);
  late final docsPath = NavigationPath<DocsRoute>.createWith(
    coordinator: this,
    label: 'Docs',
  )..bindLayout(DocsLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, rootPath, docsPath];

  @override
  Widget layoutBuilder(BuildContext context) {
    return DocsCoordinatorProvider(
      coordinator: this,
      child: super.layoutBuilder(context),
    );
  }
}

/// Type-safe reverse routing without constructing presentation routes.
final class DocsCoordinatorLocation {
  /// Creates the [DocsCoordinatorLocation] reverse-routing surface.
  const DocsCoordinatorLocation();

  Uri chapterSlug({required String slug, String? fragment}) =>
      DocsCoordinator.manifest.location(
        'ChapterSlugRoute',
        pathParameters: {'slug': slug},
        fragment: fragment,
      );

  Uri get docsIndex => DocsCoordinator.manifest.location('DocsIndexRoute');

  Uri get index => DocsCoordinator.manifest.location('IndexRoute');
}

/// Type-safe navigation extension methods.
extension DocsCoordinatorNav on DocsCoordinator {
  /// Type-safe reverse routing without constructing presentation routes.
  DocsCoordinatorLocation get location => DocsCoordinator.location;

  Future<T?> pushChapterSlug<T extends Object>({required String slug}) async =>
      push(await () async {
        await docs_chapter__slug.loadLibrary();
        return docs_chapter__slug.ChapterSlugRoute(slug: slug);
      }());
  Future<void> replaceChapterSlug({required String slug}) async =>
      replace(await () async {
        await docs_chapter__slug.loadLibrary();
        return docs_chapter__slug.ChapterSlugRoute(slug: slug);
      }());
  Future<void> recoverChapterSlug({required String slug}) async =>
      recover(await () async {
        await docs_chapter__slug.loadLibrary();
        return docs_chapter__slug.ChapterSlugRoute(slug: slug);
      }());
  Future<T?> pushDocsIndex<T extends Object>() async => push(await () async {
    await docs_index.loadLibrary();
    return docs_index.DocsIndexRoute();
  }());
  Future<void> replaceDocsIndex() async => replace(await () async {
    await docs_index.loadLibrary();
    return docs_index.DocsIndexRoute();
  }());
  Future<void> recoverDocsIndex() async => recover(await () async {
    await docs_index.loadLibrary();
    return docs_index.DocsIndexRoute();
  }());
  Future<T?> pushIndex<T extends Object>() async => push(await () async {
    await index.loadLibrary();
    return index.IndexRoute();
  }());
  Future<void> replaceIndex() async => replace(await () async {
    await index.loadLibrary();
    return index.IndexRoute();
  }());
  Future<void> recoverIndex() async => recover(await () async {
    await index.loadLibrary();
    return index.IndexRoute();
  }());
}

/// InheritedWidget provider for accessing the coordinator from the widget tree.
class DocsCoordinatorProvider extends InheritedWidget {
  const DocsCoordinatorProvider({
    required this.coordinator,
    required super.child,
    super.key,
  });

  /// Retrieves the [DocsCoordinator] from the widget tree.
  static DocsCoordinator of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DocsCoordinatorProvider>()!
      .coordinator;

  final DocsCoordinator coordinator;

  @override
  bool updateShouldNotify(DocsCoordinatorProvider oldWidget) =>
      coordinator != oldWidget.coordinator;
}

/// Extension on [BuildContext] for convenient coordinator access.
extension DocsCoordinatorGetter on BuildContext {
  /// Access the [DocsCoordinator] from the widget tree.
  DocsCoordinator get docsCoordinator => DocsCoordinatorProvider.of(this);
}

/// Destination navigation for [DocsRoute] instances.
extension DocsCoordinatorNavContext on DocsRoute {
  Future<void> navigate(BuildContext context) =>
      context.docsCoordinator.navigate(this);
  Future<T?> push<T extends Object>(BuildContext context) =>
      context.docsCoordinator.push<T>(this);
  Future<void> pushSilently(BuildContext context) =>
      context.docsCoordinator.pushSilently(this);
  Future<void> replace(BuildContext context) =>
      context.docsCoordinator.replace(this);
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    BuildContext context, {
    RO? result,
  }) => context.docsCoordinator.pushReplacement<R, RO>(this, result: result);
  Future<void> pushOrMoveToTop(BuildContext context) =>
      context.docsCoordinator.pushOrMoveToTop(this);
  Future<void> recover(BuildContext context) =>
      context.docsCoordinator.recover(this);
}
