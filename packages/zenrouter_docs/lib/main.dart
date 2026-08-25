/// ZenRouter documentation: a book that happens to be a Flutter application.
library;

import 'package:dynamic_path_url_strategy/dynamic_path_url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:meta_seo/meta_seo.dart';
import 'package:zenrouter_docs/content/book_content.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';

final docsCoordinator = CustomDocsCoordinator();

void main() {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) MetaSEO().config();
  final content = BookContentRepository.load().then((repository) {
    registerLoadedContent(repository);
    return repository;
  });
  runApp(DocsBootstrap(content: content));
}

/// Paints immediately while the small Markdown outline is loading.
class DocsBootstrap extends StatelessWidget {
  const DocsBootstrap({super.key, required this.content});

  final Future<BookContentRepository> content;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookContentRepository>(
      future: content,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ZenRouterDocsApp(content: snapshot.data!);
        }
        return _BootstrapSurface(error: snapshot.hasError);
      },
    );
  }
}

class _BootstrapSurface extends StatelessWidget {
  const _BootstrapSurface({required this.error});

  final bool error;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppTheme.canvas,
        child: Center(
          child: DefaultTextStyle(
            style: AppTypography.sans(
              color: AppTheme.ink,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ZenRouter',
                  style: AppTypography.sans(
                    color: AppTheme.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error
                      ? 'Documentation could not start. Refresh to retry.'
                      : 'Preparing documentation…',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZenRouterDocsApp extends StatelessWidget {
  const ZenRouterDocsApp({super.key, required this.content});

  final BookContentRepository content;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp.router(
      title: 'ZenRouter Documentation',
      debugShowCheckedModeBanner: false,
      color: AppTheme.canvas,
      textStyle: AppTypography.sans(
        color: AppTheme.ink,
        decoration: TextDecoration.none,
      ),
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: FLocalizations.localizationsDelegates,
      routerConfig: docsCoordinator,
      builder: (context, child) => DocsContentScope(
        content: content,
        child: FTheme(
          data: AppTheme.light,
          child: DocsTheme(
            child: FToaster(
              child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}
