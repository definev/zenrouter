/// # Documentation Index
///
/// The gateway to all ZenRouter documentation. Here we present
/// the structure of knowledge available to the reader, organized
/// into coherent sections that build upon one another.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/index.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/mardown_section.dart';

import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part 'index.g.dart';

/// The documentation index route, answering to `/docs`
///
/// This page serves as the entry point to all documentation,
/// presenting the reader with a clear map of available content
/// and guiding them toward the knowledge they seek.
@ZenRoute()
class DocsIndexRoute extends _$DocsIndexRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return const DocsIndexWidget();
  }
}

class DocsIndexWidget extends StatelessWidget {
  const DocsIndexWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final coordinator = context.docsCoordinator;

    final theme = Theme.of(context);
    final docs = theme.docs;

    return SelectionArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: docs.contentPadding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─────────────────────────────────────────────────────────────
                  // Title and Introduction
                  // ─────────────────────────────────────────────────────────────
                  Text('Documentation', style: theme.textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    'A Comprehensive Guide to ZenRouter',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),

                  const MarkdownSection(
                    markdown: '''
Welcome to the ZenRouter documentation. Here you will find everything you need to understand, implement, and master navigation in Flutter applications using ZenRouter.

This documentation is organized into five main sections, each building upon the others. Whether you are new to navigation systems or seeking to deepen your understanding, you will find content suited to your needs.

Use the navigation sidebar to explore specific topics, or begin your journey with one of the sections below.
    ''',
                  ),

                  const SizedBox(height: 48),

                  // ─────────────────────────────────────────────────────────────
                  // Navigation Cards
                  // ─────────────────────────────────────────────────────────────
                  const Divider(),
                  const SizedBox(height: 24),

                  buildNavigationList(context, coordinator),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
