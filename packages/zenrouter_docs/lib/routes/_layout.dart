/// # Root Layout
///
/// The foundational layout that wraps the entire documentation site.
/// It provides the header with branding and the main scaffold structure.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenrouter_docs/constants/app_constants.dart';
import 'package:zenrouter_docs/routes/docs/index.dart';
import 'package:zenrouter_docs/routes/index.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/breadcrumb.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';

part '_layout.g.dart';

/// The root layout for the entire ZenRouter documentation site.
///
/// This layout provides:
/// - A persistent header with the ZenRouter logo
/// - Theme toggle functionality
/// - Responsive layout structure
@ZenLayout(type: LayoutType.stack)
class RootLayout extends _$RootLayout {
  @override
  Type? get layout => null;

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return RootLayoutBuilder(child: buildPath(coordinator));
  }
}

class RootLayoutBuilder extends StatelessWidget {
  final Widget child;

  const RootLayoutBuilder({super.key, required this.child});

  PreferredSizeWidget _buildAppBar(
    Coordinator coordinator,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final docs = theme.docs;
    final isDark = theme.brightness == Brightness.dark;

    // Get current route for breadcrumbs
    final breadcrumbItems = _getBreadcrumbs(coordinator);
    final showBreadcrumbs = breadcrumbItems.length > 1;

    return PreferredSize(
      preferredSize: Size.fromHeight(showBreadcrumbs ? 100 : 64),
      child: AppBar(
        flexibleSpace: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: docs.proseMaxWidth * 1.8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main header row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Logo and Title
                      GestureDetector(
                        onTap: () => coordinator.navigate(IndexRoute()),
                        child: Row(
                          children: [
                            ClipRSuperellipse(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                isDark
                                    ? 'assets/logo_dark.png'
                                    : 'assets/logo_light.png',
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'ZEN',
                                    style: theme.textTheme.titleLarge?.merge(
                                      GoogleFonts.aboreto(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Router',
                                    style: theme.textTheme.titleLarge?.merge(
                                      GoogleFonts.aboreto(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Navigation Links
                      _buildNavigationLinks(coordinator, theme),
                    ],
                  ),
                ),
                // Breadcrumb row
                if (showBreadcrumbs)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Breadcrumb(items: breadcrumbItems),
                  ),
              ],
            ),
          ),
        ),
        centerTitle: false,
      ),
    );
  }

  /// Builds the navigation links row with Docs, Blog, GitHub, and X links
  Widget _buildNavigationLinks(Coordinator coordinator, ThemeData theme) {
    return Row(
      spacing: 12,
      children: [
        _NavLink(
          label: AppConstants.docsLabel,
          onTap: () => coordinator.navigate(DocsIndexRoute()),
        ),
        _NavLink(
          label: AppConstants.blogLabel,
          onTap: () => _launchUrl(AppConstants.blogUrl),
        ),
        _IconNavButton(
          icon: Icons.code,
          tooltip: 'GitHub',
          onTap: () => _launchUrl(AppConstants.githubUrl),
        ),
        _IconNavButton(
          icon: Icons.close, // X icon for Twitter/X
          tooltip: 'X (Twitter)',
          onTap: () => _launchUrl(AppConstants.twitterUrl),
        ),
      ],
    );
  }

  /// Extracts breadcrumb items from the current route
  List<BreadcrumbItem> _getBreadcrumbs(Coordinator coordinator) {
    final items = <BreadcrumbItem>[
      BreadcrumbItem(label: 'Home', route: IndexRoute()),
    ];

    // Get the current route from the path
    if (coordinator is! DocsCoordinator) return items;
    if (coordinator.rootPath.stack.isEmpty) return items;
    final currentRoute = coordinator.rootPath.stack.last;

    // Parse route type to build breadcrumbs
    final routeType = currentRoute.runtimeType.toString();

    // Handle docs routes
    if (routeType.contains('Docs') || routeType.contains('Route')) {
      if (routeType != 'IndexRoute') {
        items.add(BreadcrumbItem(label: 'Docs', route: DocsIndexRoute()));
      }

      // Add specific doc sections
      if (routeType.contains('Paradigm')) {
        items.add(const BreadcrumbItem(label: 'Paradigms'));
        if (routeType.contains('Imperative')) {
          items.add(const BreadcrumbItem(label: 'Imperative'));
        } else if (routeType.contains('Declarative')) {
          items.add(const BreadcrumbItem(label: 'Declarative'));
        } else if (routeType.contains('Coordinator')) {
          items.add(const BreadcrumbItem(label: 'Coordinator'));
        } else if (routeType.contains('Choosing')) {
          items.add(const BreadcrumbItem(label: 'Choosing'));
        }
      } else if (routeType.contains('Concept')) {
        items.add(const BreadcrumbItem(label: 'Concepts'));
        if (routeType.contains('RoutesAndPaths')) {
          items.add(const BreadcrumbItem(label: 'Routes and Paths'));
        } else if (routeType.contains('StackManagement')) {
          items.add(const BreadcrumbItem(label: 'Stack Management'));
        } else if (routeType.contains('UriParsing')) {
          items.add(const BreadcrumbItem(label: 'URI Parsing'));
        }
      } else if (routeType.contains('Pattern')) {
        items.add(const BreadcrumbItem(label: 'Patterns'));
        if (routeType.contains('Layout')) {
          items.add(const BreadcrumbItem(label: 'Layouts'));
        } else if (routeType.contains('Guards')) {
          items.add(const BreadcrumbItem(label: 'Guards & Redirects'));
        } else if (routeType.contains('DeepLinking')) {
          items.add(const BreadcrumbItem(label: 'Deep Linking'));
        } else if (routeType.contains('QueryParameters')) {
          items.add(const BreadcrumbItem(label: 'Query Parameters'));
        }
      } else if (routeType.contains('FileRouting') ||
          routeType.contains('GettingStarted') ||
          routeType.contains('Convention') ||
          routeType.contains('Dynamic') ||
          routeType.contains('Deferred')) {
        items.add(const BreadcrumbItem(label: 'File-Based Routing'));
        if (routeType.contains('GettingStarted')) {
          items.add(const BreadcrumbItem(label: 'Getting Started'));
        } else if (routeType.contains('Convention')) {
          items.add(const BreadcrumbItem(label: 'Conventions'));
        } else if (routeType.contains('DynamicRoutes')) {
          items.add(const BreadcrumbItem(label: 'Dynamic Routes'));
        } else if (routeType.contains('DeferredImports')) {
          items.add(const BreadcrumbItem(label: 'Deferred Imports'));
        }
      } else if (routeType.contains('Examples')) {
        items.add(const BreadcrumbItem(label: 'Examples'));
      }
    }

    return items;
  }

  /// Launches an external URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = DocsCoordinatorProvider.of(context);
    return Scaffold(appBar: _buildAppBar(coordinator, context), body: child);
  }
}

/// A text navigation link with hover effects
class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _isHovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon button for navigation with hover effects
class _IconNavButton extends StatefulWidget {
  const _IconNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_IconNavButton> createState() => _IconNavButtonState();
}

class _IconNavButtonState extends State<_IconNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: AppConstants.iconButtonSize,
              color: _isHovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
