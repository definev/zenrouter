// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query-parameters.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for QueryParametersRoute.
///
/// URI: /docs/patterns/query-parameters
/// Layout: DocsLayout
abstract class _$QueryParametersRoute extends DocsRoute
    with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  _$QueryParametersRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

  @override
  Type? get layout => DocsLayout;

  @override
  Uri toUri() {
    final uri = Uri.parse('/docs/patterns/query-parameters');
    if (queries.isEmpty) return uri;
    return uri.replace(queryParameters: queries);
  }

  @override
  List<Object?> get props => [];
}
