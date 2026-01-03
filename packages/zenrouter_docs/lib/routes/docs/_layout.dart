/// # Documentation Layout
///
/// This is the grand layout that wraps all documentation sections.
/// It provides a tree view navigation for accessing all content
/// and a Table of Contents sidebar on the right.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';

part '_layout.g.dart';

/// The grand layout for all documentation content.
///
/// This layout provides:
/// - A tree view navigation sidebar (left)
/// - A Table of Contents sidebar (right)
/// - A consistent wrapper for all documentation pages
@ZenLayout(type: LayoutType.stack)
class DocsLayout extends _$DocsLayout {
  static const _navTree = [
    NavTreeNode(
      label: 'Paradigms',
      children: [
        NavTreeNode(label: 'Imperative', path: '/docs/imperative'),
        NavTreeNode(label: 'Declarative', path: '/docs/declarative'),
        NavTreeNode(label: 'Coordinator', path: '/docs/coordinator'),
        NavTreeNode(label: 'Choosing', path: '/docs/choosing'),
      ],
    ),
    NavTreeNode(
      label: 'Concepts',
      children: [
        NavTreeNode(label: 'Routes & Paths', path: '/docs/routes-and-paths'),
        NavTreeNode(label: 'URI Parsing', path: '/docs/uri-parsing'),
        NavTreeNode(label: 'Stack Management', path: '/docs/stack-management'),
      ],
    ),
    NavTreeNode(
      label: 'Patterns',
      children: [
        NavTreeNode(label: 'Layouts', path: '/docs/layouts'),
        NavTreeNode(
          label: 'Guards & Redirects',
          path: '/docs/guards-redirects',
        ),
        NavTreeNode(label: 'Deep Linking', path: '/docs/deep-linking'),
        NavTreeNode(label: 'Query Parameters', path: '/docs/query-parameters'),
      ],
    ),
    NavTreeNode(
      label: 'File Routing',
      children: [
        NavTreeNode(
          label: 'Getting Started',
          path: '/docs/file-routing/getting-started',
        ),
        NavTreeNode(
          label: 'Conventions',
          path: '/docs/file-routing/conventions',
        ),
        NavTreeNode(
          label: 'Dynamic Routes',
          path: '/docs/file-routing/dynamic-routes',
        ),
        NavTreeNode(
          label: 'Deferred Imports',
          path: '/docs/file-routing/deferred-imports',
        ),
      ],
    ),
    NavTreeNode(
      label: 'Examples',
      children: [
        NavTreeNode(
          label: 'Basic Navigation',
          path: '/docs/examples/basic-navigation',
        ),
        NavTreeNode(label: 'Tab Bar', path: '/docs/examples/tab-bar'),
        NavTreeNode(label: 'Deep Linking', path: '/docs/examples/deep-linking'),
        NavTreeNode(label: 'Auth Flow', path: '/docs/examples/auth-flow'),
      ],
    ),
  ];

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator.activePath,
      builder: (context, _) {
        final currentPath =
            coordinator.activePath.activeRoute?.toUri().path ?? '/';
        return DocsLayoutBuilder(
          navTree: _navTree,
          currentPath: currentPath,
          onNavigate: (path) async => coordinator.navigate(
            await coordinator.parseRouteFromUri(Uri.parse(path)),
          ),
          child: buildPath(coordinator),
        );
      },
    );
  }
}
