library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

class NotFoundRoute extends DocsRoute {
  NotFoundRoute({required this.uri, this.queries = const {}});

  final Uri uri;
  final Map<String, String> queries;

  @override
  List<Object?> get props => [uri, queries];

  @override
  Uri toUri() => uri;

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return FScaffold(
      childPad: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                FLucideIcons.signpost,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Page not found',
                style: AppTypography.sans(
                  fontSize: 42,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The path “${uri.path}” does not lead anywhere we know.',
                style: AppTypography.serif(
                  fontSize: 16,
                  height: 1.7,
                  color: AppTheme.mutedInk,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              FButton(
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(FLucideIcons.house),
                onPress: coordinator.replaceIndex,
                child: const Text('Return home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
