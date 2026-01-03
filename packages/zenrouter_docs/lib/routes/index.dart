/// # Welcome to ZenRouter
///
/// This is the landing page - the first thing our reader encounters.
/// Like the opening chapter of a well-crafted novel, it must accomplish
/// several things at once: orient the reader, establish tone, and
/// promise the value to come.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';

part 'index.g.dart';

/// The home route, answering to `/`
///
/// Here we welcome the reader and present the paths available to them.
/// Each section of our documentation is a destination they may choose.
@ZenRoute()
class IndexRoute extends _$IndexRoute {
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
                Text('ZenRouter', style: theme.textTheme.displayLarge),
                const SizedBox(height: 8),
                Text(
                  'The Art of Navigation in Flutter',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 32),

                const ProseSection(
                  content: '''
Hello there!,

You have arrived at the documentation for ZenRouter, a navigation library that offers not one approach to routing, but three distinct paradigms - each suited to different circumstances, each with its own philosophy.

This documentation is itself built with ZenRouter's Coordinator pattern and file-based routing. As you navigate these pages, you are experiencing the very system we document. The routes you traverse, the layouts that wrap them, the URIs in your address bar - all are demonstrations of the principles explained herein.

We shall begin with the Three Paradigms, for one cannot appreciate a solution without understanding the problem it solves.
''',
                ),

                const SizedBox(height: 48),

                // ─────────────────────────────────────────────────────────────
                // Navigation Cards
                // ─────────────────────────────────────────────────────────────
                Text(
                  'Begin Your Journey',
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
          title: 'The Three Paradigms',
          description:
              'Imperative, Declarative, and Coordinator - understand when to use each approach.',
          onTap: () => coordinator.pushImperative(),
          color: const Color(0xFF1A5F7A),
        ),
        _NavigationCard(
          icon: Icons.account_tree,
          title: 'Core Concepts',
          description:
              'Routes, Paths, and the Stack - the fundamental building blocks.',
          onTap: () => coordinator.pushRoutesAndPaths(),
          color: const Color(0xFF9B6B3D),
        ),
        _NavigationCard(
          icon: Icons.pattern,
          title: 'Patterns',
          description:
              'Layouts, Guards, Deep Linking - practical patterns for real applications.',
          onTap: () => coordinator.pushLayouts(),
          color: const Color(0xFF6B5B95),
        ),
        _NavigationCard(
          icon: Icons.folder_special,
          title: 'File-Based Routing',
          description:
              'Let your file structure define your routes - zero boilerplate.',
          onTap: () => coordinator.pushGettingStarted(),
          color: const Color(0xFF88B04B),
        ),
        _NavigationCard(
          icon: Icons.play_circle_outline,
          title: 'Live Examples',
          description: 'Interactive demonstrations you can explore and modify.',
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
