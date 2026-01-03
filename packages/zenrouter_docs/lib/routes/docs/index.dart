/// # Documentation Index
///
/// The gateway to all ZenRouter documentation. Here we present
/// the structure of knowledge available to the reader, organized
/// into coherent sections that build upon one another.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
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
    final theme = Theme.of(context);
    final docs = theme.docs;

    return Scaffold(
      body: SingleChildScrollView(
        padding: docs.contentPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

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

                const ProseSection(
                  content: '''
Welcome to the ZenRouter documentation. Here you will find everything you need to understand, implement, and master navigation in Flutter applications using ZenRouter.

This documentation is organized into five main sections, each building upon the others. Whether you are new to navigation systems or seeking to deepen your understanding, you will find content suited to your needs.

Use the navigation sidebar to explore specific topics, or begin your journey with one of the sections below.
''',
                ),

                const SizedBox(height: 48),

                // ─────────────────────────────────────────────────────────────
                // Navigation Cards
                // ─────────────────────────────────────────────────────────────
                Text(
                  'Explore the Documentation',
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),

                _buildNavigationGrid(context, coordinator),

                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationGrid(
    BuildContext context,
    DocsCoordinator coordinator,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _NavigationCard(
          icon: Icons.route,
          title: 'Paradigms',
          description:
              'Three distinct approaches to navigation: Imperative, Declarative, and Coordinator. Understand when and why to use each paradigm.',
          onTap: () => coordinator.pushImperative(),
          color: const Color(0xFF1A5F7A),
        ),
        _NavigationCard(
          icon: Icons.account_tree,
          title: 'Core Concepts',
          description:
              'Routes, Paths, URI parsing, and Stack management - the fundamental building blocks that power ZenRouter.',
          onTap: () => coordinator.pushRoutesAndPaths(),
          color: const Color(0xFF9B6B3D),
        ),
        _NavigationCard(
          icon: Icons.pattern,
          title: 'Patterns',
          description:
              'Practical patterns for real applications: Layouts, Guards, Deep Linking, and Query Parameters.',
          onTap: () => coordinator.pushLayouts(),
          color: const Color(0xFF6B5B95),
        ),
        _NavigationCard(
          icon: Icons.folder_special,
          title: 'File-Based Routing',
          description:
              'Let your file structure define your routes. Learn about conventions, dynamic routes, and deferred imports.',
          onTap: () => coordinator.pushGettingStarted(),
          color: const Color(0xFF88B04B),
        ),
        _NavigationCard(
          icon: Icons.play_circle_outline,
          title: 'Live Examples',
          description:
              'Interactive demonstrations you can explore and modify. See ZenRouter in action with real, runnable code.',
          onTap: () => coordinator.pushExamplesSlug(slug: 'basic-navigation'),
          color: const Color(0xFFDD4124),
        ),
      ],
    );
  }
}

/// A card inviting the reader to explore a section of documentation.
class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 280,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
