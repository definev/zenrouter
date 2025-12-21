// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection.list.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for CollectionsCollectionIdRoute.
///
/// URI: /collection/list
abstract class _$CollectionsCollectionIdRoute extends AppRoute
    with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  _$CollectionsCollectionIdRoute({Map<String, String> queries = const {}})
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

  Widget sortBuilder<T>({
    required T Function(String? sort) selector,
    required Widget Function(BuildContext, T sort) builder,
  }) => selectorBuilder<T>(
    selector: (queries) => selector(queries['sort']),
    builder: (context, sort) => builder(context, sort),
  );

  Widget filterBuilder<T>({
    required T Function(String? filter) selector,
    required Widget Function(BuildContext, T filter) builder,
  }) => selectorBuilder<T>(
    selector: (queries) => selector(queries['filter']),
    builder: (context, filter) => builder(context, filter),
  );
}
