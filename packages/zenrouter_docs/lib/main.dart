/// # ZenRouter Documentation
///
/// *A Self-Referential Guide to Navigation in Flutter*
///
/// ---
///
/// Dear Reader,
///
/// You hold before you not merely a documentation application, but a living
/// demonstration of the very principles it seeks to explain. In the tradition
/// of Knuth's literate programs, where code and explanation interweave as
/// threads in a tapestry, this application teaches the Coordinator pattern
/// by *being* a Coordinator-based application.
///
/// The routes you shall navigate mirror the concepts you shall learn. The
/// layouts that wrap your journey demonstrate the layouts we document. Even
/// the deferred imports that speed your initial load are themselves a feature
/// we shall explain in due course.
///
/// We begin, as all journeys must, at the beginning.
///
/// ---
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta_seo/meta_seo.dart';
import 'package:dynamic_path_url_strategy/dynamic_path_url_strategy.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';

import 'package:zenrouter_docs/theme/app_theme.dart';

/// The coordinator that shall guide us through this documentation.
///
/// Observe: we instantiate it once, at the root of our application.
/// It shall manage all navigation state, parse all URIs, and orchestrate
/// all transitions. A single point of truth for a single concern.
final docsCoordinator = CustomDocsCoordinator();

void main() {
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) MetaSEO().config();
  runApp(const ZenRouterDocsApp());
}

/// The root of our documentation application.
///
/// Here we see the Coordinator pattern in its simplest integration:
/// `MaterialApp.router` accepts our coordinator's delegate and parser,
/// and from that point forward, all navigation flows through our
/// centralized system.
class ZenRouterDocsApp extends StatelessWidget {
  const ZenRouterDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Documentation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerDelegate: docsCoordinator.routerDelegate,
      routeInformationParser: docsCoordinator.routeInformationParser,
    );
  }
}
