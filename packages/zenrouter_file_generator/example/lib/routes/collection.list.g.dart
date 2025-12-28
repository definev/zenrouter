// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.list.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for CollectionListRoute.
///
/// URI: /collection/list
abstract class _$CollectionListRoute extends AppRoute
    with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  _$CollectionListRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

  @override
  Uri toUri() {
    final uri = Uri.parse('/collection/list');
    if (queries.isEmpty) return uri;
    return uri.replace(queryParameters: queries);
  }

  @override
  List<Object?> get props => [];

  Widget pageBuilder<T>({
    required T Function(String? page) selector,
    required Widget Function(BuildContext, T page) builder,
  }) => selectorBuilder<T>(
    selector: (queries) => selector(queries['page']),
    builder: (context, page) => builder(context, page),
  );

  Widget sortOrderBuilder<T>({
    required T Function(String? sortOrder) selector,
    required Widget Function(BuildContext, T sortOrder) builder,
  }) => selectorBuilder<T>(
    selector: (queries) => selector(queries['sortOrder']),
    builder: (context, sortOrder) => builder(context, sortOrder),
  );

  Widget filterBuilder<T>({
    required T Function(String? filter) selector,
    required Widget Function(BuildContext, T filter) builder,
  }) => selectorBuilder<T>(
    selector: (queries) => selector(queries['filter']),
    builder: (context, filter) => builder(context, filter),
  );
}
