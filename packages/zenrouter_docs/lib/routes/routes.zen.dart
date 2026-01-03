// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

import '_layout.dart';
import 'docs/(concepts)/routes-and-paths.dart'
    deferred as docs__concepts_routesandpaths;
import 'docs/(concepts)/stack-management.dart'
    deferred as docs__concepts_stackmanagement;
import 'docs/(concepts)/uri-parsing.dart' deferred as docs__concepts_uriparsing;
import 'docs/(file-routing)/conventions.dart'
    deferred as docs__filerouting_conventions;
import 'docs/(file-routing)/deferred-imports.dart';
import 'docs/(file-routing)/dynamic-routes.dart'
    deferred as docs__filerouting_dynamicroutes;
import 'docs/(file-routing)/getting-started.dart'
    deferred as docs__filerouting_gettingstarted;
import 'docs/(paradigms)/choosing.dart' deferred as docs__paradigms_choosing;
import 'docs/(paradigms)/coordinator.dart'
    deferred as docs__paradigms_coordinator;
import 'docs/(paradigms)/declarative.dart'
    deferred as docs__paradigms_declarative;
import 'docs/(paradigms)/imperative.dart'
    deferred as docs__paradigms_imperative;
import 'docs/(patterns)/deep-linking.dart'
    deferred as docs__patterns_deeplinking;
import 'docs/(patterns)/guards-redirects.dart'
    deferred as docs__patterns_guardsredirects;
import 'docs/(patterns)/layouts.dart' deferred as docs__patterns_layouts;
import 'docs/(patterns)/query-parameters.dart'
    deferred as docs__patterns_queryparameters;
import 'docs/_layout.dart';
import 'docs/examples/[slug]/index.dart' deferred as docs_examples__slug_index;
import 'docs/examples/_layout.dart';
import 'docs/index.dart' deferred as docs_index;
import 'index.dart' deferred as index;
import 'not_found.dart';

export 'package:zenrouter/zenrouter.dart';
export '_layout.dart';
export 'docs/(file-routing)/deferred-imports.dart';
export 'docs/_layout.dart';
export 'docs/examples/_layout.dart';
export 'not_found.dart';

/// Base class for all routes in this application.
abstract class DocsRoute extends RouteTarget with RouteUnique {}

/// Generated coordinator managing all routes.
class DocsCoordinator extends Coordinator<DocsRoute> {
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
    return switch (uri.pathSegments) {
      [] => await () async {
        await index.loadLibrary();
        return index.IndexRoute();
      }(),
      ['docs', 'examples', final slug] => await () async {
        await docs_examples__slug_index.loadLibrary();
        return docs_examples__slug_index.ExamplesSlugRoute(slug: slug);
      }(),
      ['docs', 'routes-and-paths'] => await () async {
        await docs__concepts_routesandpaths.loadLibrary();
        return docs__concepts_routesandpaths.RoutesAndPathsRoute();
      }(),
      ['docs', 'stack-management'] => await () async {
        await docs__concepts_stackmanagement.loadLibrary();
        return docs__concepts_stackmanagement.StackManagementRoute();
      }(),
      ['docs', 'uri-parsing'] => await () async {
        await docs__concepts_uriparsing.loadLibrary();
        return docs__concepts_uriparsing.UriParsingRoute();
      }(),
      ['docs', 'conventions'] => await () async {
        await docs__filerouting_conventions.loadLibrary();
        return docs__filerouting_conventions.ConventionsRoute();
      }(),
      ['docs', 'deferred-imports'] => DeferredImportsRoute(),
      ['docs', 'dynamic-routes'] => await () async {
        await docs__filerouting_dynamicroutes.loadLibrary();
        return docs__filerouting_dynamicroutes.DynamicRoutesRoute();
      }(),
      ['docs', 'getting-started'] => await () async {
        await docs__filerouting_gettingstarted.loadLibrary();
        return docs__filerouting_gettingstarted.GettingStartedRoute();
      }(),
      ['docs', 'choosing'] => await () async {
        await docs__paradigms_choosing.loadLibrary();
        return docs__paradigms_choosing.ChoosingRoute();
      }(),
      ['docs', 'coordinator'] => await () async {
        await docs__paradigms_coordinator.loadLibrary();
        return docs__paradigms_coordinator.CoordinatorRoute();
      }(),
      ['docs', 'declarative'] => await () async {
        await docs__paradigms_declarative.loadLibrary();
        return docs__paradigms_declarative.DeclarativeRoute();
      }(),
      ['docs', 'imperative'] => await () async {
        await docs__paradigms_imperative.loadLibrary();
        return docs__paradigms_imperative.ImperativeRoute();
      }(),
      ['docs', 'deep-linking'] => await () async {
        await docs__patterns_deeplinking.loadLibrary();
        return docs__patterns_deeplinking.DeepLinkingRoute();
      }(),
      ['docs', 'guards-redirects'] => await () async {
        await docs__patterns_guardsredirects.loadLibrary();
        return docs__patterns_guardsredirects.GuardsRedirectsRoute();
      }(),
      ['docs', 'layouts'] => await () async {
        await docs__patterns_layouts.loadLibrary();
        return docs__patterns_layouts.LayoutsRoute();
      }(),
      ['docs', 'query-parameters'] => await () async {
        await docs__patterns_queryparameters.loadLibrary();
        return docs__patterns_queryparameters.QueryParametersRoute(
          queries: uri.queryParameters,
        );
      }(),
      ['docs'] => await () async {
        await docs_index.loadLibrary();
        return docs_index.DocsIndexRoute();
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
        await docs__concepts_routesandpaths.loadLibrary();
        return docs__concepts_routesandpaths.RoutesAndPathsRoute();
      }());
  Future<void> replaceRoutesAndPaths() async => replace(await () async {
    await docs__concepts_routesandpaths.loadLibrary();
    return docs__concepts_routesandpaths.RoutesAndPathsRoute();
  }());
  Future<void> recoverRoutesAndPaths() async => recover(await () async {
    await docs__concepts_routesandpaths.loadLibrary();
    return docs__concepts_routesandpaths.RoutesAndPathsRoute();
  }());
  Future<T?> pushStackManagement<T extends Object>() async =>
      push(await () async {
        await docs__concepts_stackmanagement.loadLibrary();
        return docs__concepts_stackmanagement.StackManagementRoute();
      }());
  Future<void> replaceStackManagement() async => replace(await () async {
    await docs__concepts_stackmanagement.loadLibrary();
    return docs__concepts_stackmanagement.StackManagementRoute();
  }());
  Future<void> recoverStackManagement() async => recover(await () async {
    await docs__concepts_stackmanagement.loadLibrary();
    return docs__concepts_stackmanagement.StackManagementRoute();
  }());
  Future<T?> pushUriParsing<T extends Object>() async => push(await () async {
    await docs__concepts_uriparsing.loadLibrary();
    return docs__concepts_uriparsing.UriParsingRoute();
  }());
  Future<void> replaceUriParsing() async => replace(await () async {
    await docs__concepts_uriparsing.loadLibrary();
    return docs__concepts_uriparsing.UriParsingRoute();
  }());
  Future<void> recoverUriParsing() async => recover(await () async {
    await docs__concepts_uriparsing.loadLibrary();
    return docs__concepts_uriparsing.UriParsingRoute();
  }());
  Future<T?> pushConventions<T extends Object>() async => push(await () async {
    await docs__filerouting_conventions.loadLibrary();
    return docs__filerouting_conventions.ConventionsRoute();
  }());
  Future<void> replaceConventions() async => replace(await () async {
    await docs__filerouting_conventions.loadLibrary();
    return docs__filerouting_conventions.ConventionsRoute();
  }());
  Future<void> recoverConventions() async => recover(await () async {
    await docs__filerouting_conventions.loadLibrary();
    return docs__filerouting_conventions.ConventionsRoute();
  }());
  Future<T?> pushDeferredImports<T extends Object>() =>
      push(DeferredImportsRoute());
  Future<void> replaceDeferredImports() => replace(DeferredImportsRoute());
  Future<void> recoverDeferredImports() => recover(DeferredImportsRoute());
  Future<T?> pushDynamicRoutes<T extends Object>() async =>
      push(await () async {
        await docs__filerouting_dynamicroutes.loadLibrary();
        return docs__filerouting_dynamicroutes.DynamicRoutesRoute();
      }());
  Future<void> replaceDynamicRoutes() async => replace(await () async {
    await docs__filerouting_dynamicroutes.loadLibrary();
    return docs__filerouting_dynamicroutes.DynamicRoutesRoute();
  }());
  Future<void> recoverDynamicRoutes() async => recover(await () async {
    await docs__filerouting_dynamicroutes.loadLibrary();
    return docs__filerouting_dynamicroutes.DynamicRoutesRoute();
  }());
  Future<T?> pushGettingStarted<T extends Object>() async =>
      push(await () async {
        await docs__filerouting_gettingstarted.loadLibrary();
        return docs__filerouting_gettingstarted.GettingStartedRoute();
      }());
  Future<void> replaceGettingStarted() async => replace(await () async {
    await docs__filerouting_gettingstarted.loadLibrary();
    return docs__filerouting_gettingstarted.GettingStartedRoute();
  }());
  Future<void> recoverGettingStarted() async => recover(await () async {
    await docs__filerouting_gettingstarted.loadLibrary();
    return docs__filerouting_gettingstarted.GettingStartedRoute();
  }());
  Future<T?> pushChoosing<T extends Object>() async => push(await () async {
    await docs__paradigms_choosing.loadLibrary();
    return docs__paradigms_choosing.ChoosingRoute();
  }());
  Future<void> replaceChoosing() async => replace(await () async {
    await docs__paradigms_choosing.loadLibrary();
    return docs__paradigms_choosing.ChoosingRoute();
  }());
  Future<void> recoverChoosing() async => recover(await () async {
    await docs__paradigms_choosing.loadLibrary();
    return docs__paradigms_choosing.ChoosingRoute();
  }());
  Future<T?> pushCoordinator<T extends Object>() async => push(await () async {
    await docs__paradigms_coordinator.loadLibrary();
    return docs__paradigms_coordinator.CoordinatorRoute();
  }());
  Future<void> replaceCoordinator() async => replace(await () async {
    await docs__paradigms_coordinator.loadLibrary();
    return docs__paradigms_coordinator.CoordinatorRoute();
  }());
  Future<void> recoverCoordinator() async => recover(await () async {
    await docs__paradigms_coordinator.loadLibrary();
    return docs__paradigms_coordinator.CoordinatorRoute();
  }());
  Future<T?> pushDeclarative<T extends Object>() async => push(await () async {
    await docs__paradigms_declarative.loadLibrary();
    return docs__paradigms_declarative.DeclarativeRoute();
  }());
  Future<void> replaceDeclarative() async => replace(await () async {
    await docs__paradigms_declarative.loadLibrary();
    return docs__paradigms_declarative.DeclarativeRoute();
  }());
  Future<void> recoverDeclarative() async => recover(await () async {
    await docs__paradigms_declarative.loadLibrary();
    return docs__paradigms_declarative.DeclarativeRoute();
  }());
  Future<T?> pushImperative<T extends Object>() async => push(await () async {
    await docs__paradigms_imperative.loadLibrary();
    return docs__paradigms_imperative.ImperativeRoute();
  }());
  Future<void> replaceImperative() async => replace(await () async {
    await docs__paradigms_imperative.loadLibrary();
    return docs__paradigms_imperative.ImperativeRoute();
  }());
  Future<void> recoverImperative() async => recover(await () async {
    await docs__paradigms_imperative.loadLibrary();
    return docs__paradigms_imperative.ImperativeRoute();
  }());
  Future<T?> pushDeepLinking<T extends Object>() async => push(await () async {
    await docs__patterns_deeplinking.loadLibrary();
    return docs__patterns_deeplinking.DeepLinkingRoute();
  }());
  Future<void> replaceDeepLinking() async => replace(await () async {
    await docs__patterns_deeplinking.loadLibrary();
    return docs__patterns_deeplinking.DeepLinkingRoute();
  }());
  Future<void> recoverDeepLinking() async => recover(await () async {
    await docs__patterns_deeplinking.loadLibrary();
    return docs__patterns_deeplinking.DeepLinkingRoute();
  }());
  Future<T?> pushGuardsRedirects<T extends Object>() async =>
      push(await () async {
        await docs__patterns_guardsredirects.loadLibrary();
        return docs__patterns_guardsredirects.GuardsRedirectsRoute();
      }());
  Future<void> replaceGuardsRedirects() async => replace(await () async {
    await docs__patterns_guardsredirects.loadLibrary();
    return docs__patterns_guardsredirects.GuardsRedirectsRoute();
  }());
  Future<void> recoverGuardsRedirects() async => recover(await () async {
    await docs__patterns_guardsredirects.loadLibrary();
    return docs__patterns_guardsredirects.GuardsRedirectsRoute();
  }());
  Future<T?> pushLayouts<T extends Object>() async => push(await () async {
    await docs__patterns_layouts.loadLibrary();
    return docs__patterns_layouts.LayoutsRoute();
  }());
  Future<void> replaceLayouts() async => replace(await () async {
    await docs__patterns_layouts.loadLibrary();
    return docs__patterns_layouts.LayoutsRoute();
  }());
  Future<void> recoverLayouts() async => recover(await () async {
    await docs__patterns_layouts.loadLibrary();
    return docs__patterns_layouts.LayoutsRoute();
  }());
  Future<T?> pushQueryParameters<T extends Object>({
    Map<String, String> queries = const {},
  }) async => push(await () async {
    await docs__patterns_queryparameters.loadLibrary();
    return docs__patterns_queryparameters.QueryParametersRoute(
      queries: queries,
    );
  }());
  Future<void> replaceQueryParameters({
    Map<String, String> queries = const {},
  }) async => replace(await () async {
    await docs__patterns_queryparameters.loadLibrary();
    return docs__patterns_queryparameters.QueryParametersRoute(
      queries: queries,
    );
  }());
  Future<void> recoverQueryParameters({
    Map<String, String> queries = const {},
  }) async => recover(await () async {
    await docs__patterns_queryparameters.loadLibrary();
    return docs__patterns_queryparameters.QueryParametersRoute(
      queries: queries,
    );
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
