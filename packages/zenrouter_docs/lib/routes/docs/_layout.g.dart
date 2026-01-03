// GENERATED CODE - DO NOT MODIFY BY HAND

part of '_layout.dart';

// **************************************************************************
// LayoutGenerator
// **************************************************************************

/// Generated base class for DocsLayout.
///
/// URI: /docs
/// Path type: stack
/// Parent layout: RootLayout
abstract class _$DocsLayout extends DocsRoute with RouteLayout<DocsRoute> {
  _$DocsLayout();

  @override
  Type? get layout => RootLayout;

  @override
  NavigationPath<DocsRoute> resolvePath(
    covariant DocsCoordinator coordinator,
  ) => coordinator.docsPath;

  @override
  Uri toUri() => Uri.parse('/docs');

  @override
  List<Object?> get props => [];
}
