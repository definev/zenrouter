// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index.dart';

// **************************************************************************
// RouteGenerator
// **************************************************************************

/// Generated base class for ForYouRoute.
///
/// URI: /tabs/feed/for-you
/// Layout: ForYouLayout
abstract class _$ForYouRoute extends AppRoute with RouteQueryParameters {
  @override
  late final ValueNotifier<Map<String, String>> queryNotifier;

  _$ForYouRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

  @override
  Type? get layout => ForYouLayout;

  @override
  Uri toUri() {
    final uri = Uri.parse('/tabs/feed/for-you');
    if (queries.isEmpty) return uri;
    return uri.replace(queryParameters: queries);
  }

  @override
  List<Object?> get props => [];
}
