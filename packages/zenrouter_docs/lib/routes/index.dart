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
                // Navigation Links
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
    );
  }
}

Widget buildNavigationList(BuildContext context, DocsCoordinator coordinator) {
  final items = [
    NavigationItem(
      icon: Icons.route,
      title: 'The Three Paradigms',
      description:
          'Imperative, Declarative, and Coordinator - understand when to use each approach.',
      onTap: () => coordinator.pushImperative(),
      color: const Color(0xFF1A5F7A),
    ),
    NavigationItem(
      icon: Icons.account_tree,
      title: 'Core Concepts',
      description:
          'Routes, Paths, and the Stack - the fundamental building blocks.',
      onTap: () => coordinator.pushRoutesAndPaths(),
      color: const Color(0xFF9B6B3D),
    ),
    NavigationItem(
      icon: Icons.pattern,
      title: 'Patterns',
      description:
          'Layouts, Guards, Deep Linking - practical patterns for real applications.',
      onTap: () => coordinator.pushLayouts(),
      color: const Color(0xFF6B5B95),
    ),
    NavigationItem(
      icon: Icons.folder_special,
      title: 'File-Based Routing',
      description:
          'Let your file structure define your routes - zero boilerplate.',
      onTap: () => coordinator.pushGettingStarted(),
      color: const Color(0xFF88B04B),
    ),
    NavigationItem(
      icon: Icons.play_circle_outline,
      title: 'Live Examples',
      description: 'Interactive demonstrations you can explore and modify.',
      onTap: () => coordinator.pushExamplesSlug(slug: 'basic-navigation'),
      color: const Color(0xFFDD4124),
    ),
  ];

  return Column(
    spacing: 8,
    children: items.map((item) => NavigationLink(item: item)).toList(),
  );
}

/// A navigation item definition
class NavigationItem {
  const NavigationItem({
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
}

/// A clickable navigation link without card styling
class NavigationLink extends StatefulWidget {
  const NavigationLink({super.key, required this.item});

  final NavigationItem item;

  @override
  State<NavigationLink> createState() => _NavigationLinkState();
}

class _NavigationLinkState extends State<NavigationLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 20),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isHovered ? theme.colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
