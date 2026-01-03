/// # Root Layout
///
/// The foundational layout that wraps the entire documentation site.
/// It provides the header with branding and the main scaffold structure.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/docs/index.dart';
import 'package:zenrouter_docs/routes/index.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
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
    return Scaffold(
      appBar: _buildAppBar(coordinator, context),
      body: buildPath(coordinator),
    );
  }

  PreferredSizeWidget _buildAppBar(
    Coordinator coordinator,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final docs = theme.docs;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: docs.proseMaxWidth),
          child: Row(
            children: [
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
                    // Title
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Zen',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          TextSpan(
                            text: 'Router',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Logo
              const Spacer(),
              FilledButton(
                onPressed: () => coordinator.navigate(DocsIndexRoute()),
                child: const Text('Documentation'),
              ),
            ],
          ),
        ),
      ),
      centerTitle: false,
    );
  }
}
