// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

import '_layout.dart';
import 'docs/_layout.dart';
import 'docs/concepts/routes-and-paths.dart'
    deferred as docs_concepts_routesandpaths;
import 'docs/concepts/stack-management.dart'
    deferred as docs_concepts_stackmanagement;
import 'docs/concepts/uri-parsing.dart' deferred as docs_concepts_uriparsing;
import 'docs/examples/[slug]/index.dart' deferred as docs_examples__slug_index;
import 'docs/examples/_layout.dart';
import 'docs/file-routing/conventions.dart'
    deferred as docs_filerouting_conventions;
import 'docs/file-routing/deferred-imports.dart';
import 'docs/file-routing/dynamic-routes.dart'
    deferred as docs_filerouting_dynamicroutes;
import 'docs/file-routing/getting-started.dart'
    deferred as docs_filerouting_gettingstarted;
import 'docs/index.dart' deferred as docs_index;
import 'docs/paradigms/choosing.dart' deferred as docs_paradigms_choosing;
import 'docs/paradigms/coordinator.dart' deferred as docs_paradigms_coordinator;
import 'docs/paradigms/declarative.dart' deferred as docs_paradigms_declarative;
import 'docs/paradigms/imperative.dart' deferred as docs_paradigms_imperative;
import 'docs/patterns/deep-linking.dart' deferred as docs_patterns_deeplinking;
import 'docs/patterns/guards-redirects.dart'
    deferred as docs_patterns_guardsredirects;
import 'docs/patterns/layouts.dart' deferred as docs_patterns_layouts;
import 'docs/patterns/query-parameters.dart'
    deferred as docs_patterns_queryparameters;
import 'index.dart' deferred as index;
import 'not_found.dart';

export 'package:zenrouter/zenrouter.dart';
export '_layout.dart';
export 'docs/_layout.dart';
export 'docs/examples/_layout.dart';
export 'docs/file-routing/deferred-imports.dart';
export 'not_found.dart';

/// Base class for all routes in this application.
abstract class DocsRoute extends RouteTarget with RouteUnique {}

/// Generated coordinator managing all routes.
class DocsCoordinator extends Coordinator<DocsRoute> {
  /// Immutable application route topology.
  static final RouteManifest<String> manifest = RouteManifest<String>(
    name: 'DocsCoordinator',
    routes: [
      RouteManifestRoute(
        id: 'RoutesAndPathsRoute',
        path: '/docs/concepts/routes-and-paths',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'StackManagementRoute',
        path: '/docs/concepts/stack-management',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'UriParsingRoute',
        path: '/docs/concepts/uri-parsing',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'ExamplesSlugRoute',
        path: '/docs/examples/:slug',
        parentId: 'ExamplesLayout',
      ),
      RouteManifestRoute(
        id: 'ConventionsRoute',
        path: '/docs/file-routing/conventions',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'DeferredImportsRoute',
        path: '/docs/file-routing/deferred-imports',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'DynamicRoutesRoute',
        path: '/docs/file-routing/dynamic-routes',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'GettingStartedRoute',
        path: '/docs/file-routing/getting-started',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'DocsIndexRoute',
        path: '/docs',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'ChoosingRoute',
        path: '/docs/paradigms/choosing',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'CoordinatorRoute',
        path: '/docs/paradigms/coordinator',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'DeclarativeRoute',
        path: '/docs/paradigms/declarative',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'ImperativeRoute',
        path: '/docs/paradigms/imperative',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'DeepLinkingRoute',
        path: '/docs/patterns/deep-linking',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'GuardsRedirectsRoute',
        path: '/docs/patterns/guards-redirects',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'LayoutsRoute',
        path: '/docs/patterns/layouts',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(
        id: 'QueryParametersRoute',
        path: '/docs/patterns/query-parameters',
        parentId: 'DocsLayout',
      ),
      RouteManifestRoute(id: 'IndexRoute', path: '/'),
    ],
    layouts: [
      RouteManifestLayout(
        id: 'RootLayout',
        path: '/',
        kind: RouteManifestLayoutKind.stack,
      ),
      RouteManifestLayout(
        id: 'DocsLayout',
        path: '/docs',
        kind: RouteManifestLayoutKind.stack,
      ),
      RouteManifestLayout(
        id: 'ExamplesLayout',
        path: '/docs/examples',
        parentId: 'DocsLayout',
        kind: RouteManifestLayoutKind.stack,
      ),
    ],
  );

  @override
  RouteManifest<String> get routeManifest => manifest;

  /// Type-safe reverse routing without constructing presentation routes.
  static Uri routesAndPathsLocation({String? fragment}) =>
      manifest.location('RoutesAndPathsRoute', fragment: fragment);

  static Uri stackManagementLocation({String? fragment}) =>
      manifest.location('StackManagementRoute', fragment: fragment);

  static Uri uriParsingLocation({String? fragment}) =>
      manifest.location('UriParsingRoute', fragment: fragment);

  static Uri examplesSlugLocation({required String slug, String? fragment}) =>
      manifest.location(
        'ExamplesSlugRoute',
        pathParameters: {'slug': slug},
        fragment: fragment,
      );

  static Uri conventionsLocation({String? fragment}) =>
      manifest.location('ConventionsRoute', fragment: fragment);

  static Uri deferredImportsLocation({String? fragment}) =>
      manifest.location('DeferredImportsRoute', fragment: fragment);

  static Uri dynamicRoutesLocation({String? fragment}) =>
      manifest.location('DynamicRoutesRoute', fragment: fragment);

  static Uri gettingStartedLocation({String? fragment}) =>
      manifest.location('GettingStartedRoute', fragment: fragment);

  static Uri docsIndexLocation({String? fragment}) =>
      manifest.location('DocsIndexRoute', fragment: fragment);

  static Uri choosingLocation({String? fragment}) =>
      manifest.location('ChoosingRoute', fragment: fragment);

  static Uri coordinatorLocation({String? fragment}) =>
      manifest.location('CoordinatorRoute', fragment: fragment);

  static Uri declarativeLocation({String? fragment}) =>
      manifest.location('DeclarativeRoute', fragment: fragment);

  static Uri imperativeLocation({String? fragment}) =>
      manifest.location('ImperativeRoute', fragment: fragment);

  static Uri deepLinkingLocation({String? fragment}) =>
      manifest.location('DeepLinkingRoute', fragment: fragment);

  static Uri guardsRedirectsLocation({String? fragment}) =>
      manifest.location('GuardsRedirectsRoute', fragment: fragment);

  static Uri layoutsLocation({String? fragment}) =>
      manifest.location('LayoutsRoute', fragment: fragment);

  static Uri queryParametersLocation({
    Map<String, String> queries = const {},
    String? fragment,
  }) => manifest.location(
    'QueryParametersRoute',
    queryParameters: queries,
    fragment: fragment,
  );

  static Uri indexLocation({String? fragment}) =>
      manifest.location('IndexRoute', fragment: fragment);

  late final rootPath = NavigationPath<DocsRoute>.createWith(
    coordinator: this,
    label: 'Root',
  )..bindLayout(RootLayout.new);
  late final docsPath = NavigationPath<DocsRoute>.createWith(
    coordinator: this,
    label: 'Docs',
  )..bindLayout(DocsLayout.new);
  late final examplesPath = NavigationPath<DocsRoute>.createWith(
    coordinator: this,
    label: 'Examples',
  )..bindLayout(ExamplesLayout.new);

  @override
  List<StackPath> get paths => [
    ...super.paths,
    rootPath,
    docsPath,
    examplesPath,
  ];

  @override
  Future<DocsRoute> parseRouteFromUri(Uri uri) async {
    final match = routeManifest.match(uri);
    if (match == null) {
      return NotFoundRoute(uri: uri, queries: uri.queryParameters);
    }
    return switch (match.id) {
      'RoutesAndPathsRoute' => await () async {
        await docs_concepts_routesandpaths.loadLibrary();
        return docs_concepts_routesandpaths.RoutesAndPathsRoute();
      }(),
      'StackManagementRoute' => await () async {
        await docs_concepts_stackmanagement.loadLibrary();
        return docs_concepts_stackmanagement.StackManagementRoute();
      }(),
      'UriParsingRoute' => await () async {
        await docs_concepts_uriparsing.loadLibrary();
        return docs_concepts_uriparsing.UriParsingRoute();
      }(),
      'ConventionsRoute' => await () async {
        await docs_filerouting_conventions.loadLibrary();
        return docs_filerouting_conventions.ConventionsRoute();
      }(),
      'DeferredImportsRoute' => DeferredImportsRoute(),
      'DynamicRoutesRoute' => await () async {
        await docs_filerouting_dynamicroutes.loadLibrary();
        return docs_filerouting_dynamicroutes.DynamicRoutesRoute();
      }(),
      'GettingStartedRoute' => await () async {
        await docs_filerouting_gettingstarted.loadLibrary();
        return docs_filerouting_gettingstarted.GettingStartedRoute();
      }(),
      'ChoosingRoute' => await () async {
        await docs_paradigms_choosing.loadLibrary();
        return docs_paradigms_choosing.ChoosingRoute();
      }(),
      'CoordinatorRoute' => await () async {
        await docs_paradigms_coordinator.loadLibrary();
        return docs_paradigms_coordinator.CoordinatorRoute();
      }(),
      'DeclarativeRoute' => await () async {
        await docs_paradigms_declarative.loadLibrary();
        return docs_paradigms_declarative.DeclarativeRoute();
      }(),
      'ImperativeRoute' => await () async {
        await docs_paradigms_imperative.loadLibrary();
        return docs_paradigms_imperative.ImperativeRoute();
      }(),
      'DeepLinkingRoute' => await () async {
        await docs_patterns_deeplinking.loadLibrary();
        return docs_patterns_deeplinking.DeepLinkingRoute();
      }(),
      'GuardsRedirectsRoute' => await () async {
        await docs_patterns_guardsredirects.loadLibrary();
        return docs_patterns_guardsredirects.GuardsRedirectsRoute();
      }(),
      'LayoutsRoute' => await () async {
        await docs_patterns_layouts.loadLibrary();
        return docs_patterns_layouts.LayoutsRoute();
      }(),
      'QueryParametersRoute' => await () async {
        await docs_patterns_queryparameters.loadLibrary();
        return docs_patterns_queryparameters.QueryParametersRoute(
          queries: uri.queryParameters,
        );
      }(),
      'ExamplesSlugRoute' => await () async {
        await docs_examples__slug_index.loadLibrary();
        return docs_examples__slug_index.ExamplesSlugRoute(
          slug: match.pathParameters['slug']!,
        );
      }(),
      'DocsIndexRoute' => await () async {
        await docs_index.loadLibrary();
        return docs_index.DocsIndexRoute();
      }(),
      'IndexRoute' => await () async {
        await index.loadLibrary();
        return index.IndexRoute();
      }(),
      _ => NotFoundRoute(uri: uri, queries: uri.queryParameters),
    };
  }

  @override
  Widget layoutBuilder(BuildContext context) {
    return DocsCoordinatorProvider(
      coordinator: this,
      child: super.layoutBuilder(context),
    );
  }
}

/// Type-safe navigation extension methods.
extension DocsCoordinatorNav on DocsCoordinator {
  Future<T?> pushRoutesAndPaths<T extends Object>() async =>
      push(await () async {
        await docs_concepts_routesandpaths.loadLibrary();
        return docs_concepts_routesandpaths.RoutesAndPathsRoute();
      }());
  Future<void> replaceRoutesAndPaths() async => replace(await () async {
    await docs_concepts_routesandpaths.loadLibrary();
    return docs_concepts_routesandpaths.RoutesAndPathsRoute();
  }());
  Future<void> recoverRoutesAndPaths() async => recover(await () async {
    await docs_concepts_routesandpaths.loadLibrary();
    return docs_concepts_routesandpaths.RoutesAndPathsRoute();
  }());
  Future<T?> pushStackManagement<T extends Object>() async =>
      push(await () async {
        await docs_concepts_stackmanagement.loadLibrary();
        return docs_concepts_stackmanagement.StackManagementRoute();
      }());
  Future<void> replaceStackManagement() async => replace(await () async {
    await docs_concepts_stackmanagement.loadLibrary();
    return docs_concepts_stackmanagement.StackManagementRoute();
  }());
  Future<void> recoverStackManagement() async => recover(await () async {
    await docs_concepts_stackmanagement.loadLibrary();
    return docs_concepts_stackmanagement.StackManagementRoute();
  }());
  Future<T?> pushUriParsing<T extends Object>() async => push(await () async {
    await docs_concepts_uriparsing.loadLibrary();
    return docs_concepts_uriparsing.UriParsingRoute();
  }());
  Future<void> replaceUriParsing() async => replace(await () async {
    await docs_concepts_uriparsing.loadLibrary();
    return docs_concepts_uriparsing.UriParsingRoute();
  }());
  Future<void> recoverUriParsing() async => recover(await () async {
    await docs_concepts_uriparsing.loadLibrary();
    return docs_concepts_uriparsing.UriParsingRoute();
  }());
  Future<T?> pushExamplesSlug<T extends Object>({required String slug}) async =>
      push(await () async {
        await docs_examples__slug_index.loadLibrary();
        return docs_examples__slug_index.ExamplesSlugRoute(slug: slug);
      }());
  Future<void> replaceExamplesSlug({required String slug}) async =>
      replace(await () async {
        await docs_examples__slug_index.loadLibrary();
        return docs_examples__slug_index.ExamplesSlugRoute(slug: slug);
      }());
  Future<void> recoverExamplesSlug({required String slug}) async =>
      recover(await () async {
        await docs_examples__slug_index.loadLibrary();
        return docs_examples__slug_index.ExamplesSlugRoute(slug: slug);
      }());
  Future<T?> pushConventions<T extends Object>() async => push(await () async {
    await docs_filerouting_conventions.loadLibrary();
    return docs_filerouting_conventions.ConventionsRoute();
  }());
  Future<void> replaceConventions() async => replace(await () async {
    await docs_filerouting_conventions.loadLibrary();
    return docs_filerouting_conventions.ConventionsRoute();
  }());
  Future<void> recoverConventions() async => recover(await () async {
    await docs_filerouting_conventions.loadLibrary();
    return docs_filerouting_conventions.ConventionsRoute();
  }());
  Future<T?> pushDeferredImports<T extends Object>() =>
      push(DeferredImportsRoute());
  Future<void> replaceDeferredImports() => replace(DeferredImportsRoute());
  Future<void> recoverDeferredImports() => recover(DeferredImportsRoute());
  Future<T?> pushDynamicRoutes<T extends Object>() async =>
      push(await () async {
        await docs_filerouting_dynamicroutes.loadLibrary();
        return docs_filerouting_dynamicroutes.DynamicRoutesRoute();
      }());
  Future<void> replaceDynamicRoutes() async => replace(await () async {
    await docs_filerouting_dynamicroutes.loadLibrary();
    return docs_filerouting_dynamicroutes.DynamicRoutesRoute();
  }());
  Future<void> recoverDynamicRoutes() async => recover(await () async {
    await docs_filerouting_dynamicroutes.loadLibrary();
    return docs_filerouting_dynamicroutes.DynamicRoutesRoute();
  }());
  Future<T?> pushGettingStarted<T extends Object>() async =>
      push(await () async {
        await docs_filerouting_gettingstarted.loadLibrary();
        return docs_filerouting_gettingstarted.GettingStartedRoute();
      }());
  Future<void> replaceGettingStarted() async => replace(await () async {
    await docs_filerouting_gettingstarted.loadLibrary();
    return docs_filerouting_gettingstarted.GettingStartedRoute();
  }());
  Future<void> recoverGettingStarted() async => recover(await () async {
    await docs_filerouting_gettingstarted.loadLibrary();
    return docs_filerouting_gettingstarted.GettingStartedRoute();
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
  Future<T?> pushChoosing<T extends Object>() async => push(await () async {
    await docs_paradigms_choosing.loadLibrary();
    return docs_paradigms_choosing.ChoosingRoute();
  }());
  Future<void> replaceChoosing() async => replace(await () async {
    await docs_paradigms_choosing.loadLibrary();
    return docs_paradigms_choosing.ChoosingRoute();
  }());
  Future<void> recoverChoosing() async => recover(await () async {
    await docs_paradigms_choosing.loadLibrary();
    return docs_paradigms_choosing.ChoosingRoute();
  }());
  Future<T?> pushCoordinator<T extends Object>() async => push(await () async {
    await docs_paradigms_coordinator.loadLibrary();
    return docs_paradigms_coordinator.CoordinatorRoute();
  }());
  Future<void> replaceCoordinator() async => replace(await () async {
    await docs_paradigms_coordinator.loadLibrary();
    return docs_paradigms_coordinator.CoordinatorRoute();
  }());
  Future<void> recoverCoordinator() async => recover(await () async {
    await docs_paradigms_coordinator.loadLibrary();
    return docs_paradigms_coordinator.CoordinatorRoute();
  }());
  Future<T?> pushDeclarative<T extends Object>() async => push(await () async {
    await docs_paradigms_declarative.loadLibrary();
    return docs_paradigms_declarative.DeclarativeRoute();
  }());
  Future<void> replaceDeclarative() async => replace(await () async {
    await docs_paradigms_declarative.loadLibrary();
    return docs_paradigms_declarative.DeclarativeRoute();
  }());
  Future<void> recoverDeclarative() async => recover(await () async {
    await docs_paradigms_declarative.loadLibrary();
    return docs_paradigms_declarative.DeclarativeRoute();
  }());
  Future<T?> pushImperative<T extends Object>() async => push(await () async {
    await docs_paradigms_imperative.loadLibrary();
    return docs_paradigms_imperative.ImperativeRoute();
  }());
  Future<void> replaceImperative() async => replace(await () async {
    await docs_paradigms_imperative.loadLibrary();
    return docs_paradigms_imperative.ImperativeRoute();
  }());
  Future<void> recoverImperative() async => recover(await () async {
    await docs_paradigms_imperative.loadLibrary();
    return docs_paradigms_imperative.ImperativeRoute();
  }());
  Future<T?> pushDeepLinking<T extends Object>() async => push(await () async {
    await docs_patterns_deeplinking.loadLibrary();
    return docs_patterns_deeplinking.DeepLinkingRoute();
  }());
  Future<void> replaceDeepLinking() async => replace(await () async {
    await docs_patterns_deeplinking.loadLibrary();
    return docs_patterns_deeplinking.DeepLinkingRoute();
  }());
  Future<void> recoverDeepLinking() async => recover(await () async {
    await docs_patterns_deeplinking.loadLibrary();
    return docs_patterns_deeplinking.DeepLinkingRoute();
  }());
  Future<T?> pushGuardsRedirects<T extends Object>() async =>
      push(await () async {
        await docs_patterns_guardsredirects.loadLibrary();
        return docs_patterns_guardsredirects.GuardsRedirectsRoute();
      }());
  Future<void> replaceGuardsRedirects() async => replace(await () async {
    await docs_patterns_guardsredirects.loadLibrary();
    return docs_patterns_guardsredirects.GuardsRedirectsRoute();
  }());
  Future<void> recoverGuardsRedirects() async => recover(await () async {
    await docs_patterns_guardsredirects.loadLibrary();
    return docs_patterns_guardsredirects.GuardsRedirectsRoute();
  }());
  Future<T?> pushLayouts<T extends Object>() async => push(await () async {
    await docs_patterns_layouts.loadLibrary();
    return docs_patterns_layouts.LayoutsRoute();
  }());
  Future<void> replaceLayouts() async => replace(await () async {
    await docs_patterns_layouts.loadLibrary();
    return docs_patterns_layouts.LayoutsRoute();
  }());
  Future<void> recoverLayouts() async => recover(await () async {
    await docs_patterns_layouts.loadLibrary();
    return docs_patterns_layouts.LayoutsRoute();
  }());
  Future<T?> pushQueryParameters<T extends Object>({
    Map<String, String> queries = const {},
  }) async => push(await () async {
    await docs_patterns_queryparameters.loadLibrary();
    return docs_patterns_queryparameters.QueryParametersRoute(queries: queries);
  }());
  Future<void> replaceQueryParameters({
    Map<String, String> queries = const {},
  }) async => replace(await () async {
    await docs_patterns_queryparameters.loadLibrary();
    return docs_patterns_queryparameters.QueryParametersRoute(queries: queries);
  }());
  Future<void> recoverQueryParameters({
    Map<String, String> queries = const {},
  }) async => recover(await () async {
    await docs_patterns_queryparameters.loadLibrary();
    return docs_patterns_queryparameters.QueryParametersRoute(queries: queries);
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

/// Extension on [DocsRoute] for navigation methods.
extension DocsCoordinatorNavContext on DocsRoute {
  Future<void> navigate(BuildContext context) =>
      context.docsCoordinator.navigate(this);
  Future<T?> push<T extends Object>(BuildContext context) =>
      context.docsCoordinator.push<T>(this);
  Future<void> replace(BuildContext context) =>
      context.docsCoordinator.replace(this);
  Future<void> recover(BuildContext context) =>
      context.docsCoordinator.recover(this);
}
