// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.[profileId].collections.[collectionId].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for CollectionsCollectionIdRoute.
///
/// URI: /profile/:profileId/collections/:collectionId
abstract class _$CollectionsCollectionIdRoute extends AppRoute
    with RouteQueryParameters {
  /// Dynamic parameter from path segment.
  final String profileId;

  /// Dynamic parameter from path segment.
  final String collectionId;

  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  _$CollectionsCollectionIdRoute({
    required this.profileId,
    required this.collectionId,
    Map<String, String> queries = const {},
  }) : queryNotifier = ValueNotifier(queries);

  @override
  Uri toUri() {
    final uri = Uri.parse('/profile/$profileId/collections/$collectionId');
    if (queries.isEmpty) return uri;
    return uri.replace(queryParameters: queries);
  }

  @override
  List<Object?> get props => [profileId, collectionId];
}
