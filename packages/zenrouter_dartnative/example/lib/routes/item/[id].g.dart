// GENERATED CODE - DO NOT MODIFY BY HAND

part of '[id].dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for ItemIdRoute.
///
/// URI: /item/:id
abstract class _$ItemIdRoute extends AppRoute {
  /// Dynamic parameter from path segment.
  final String id;

  _$ItemIdRoute({required this.id});

  @override
  Uri toUri() => Uri(pathSegments: ['', 'item', id]);

  @override
  List<Object?> get props => [id];
}
