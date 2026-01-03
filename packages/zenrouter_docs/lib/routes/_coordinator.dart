/// # Coordinator Configuration
///
/// Here we configure the generated coordinator. The `@ZenCoordinator`
/// annotation tells the generator what to name our coordinator and
/// route base class.
///
/// This file is discovered by zenrouter_file_generator and influences
/// the generated `routes.zen.dart` file.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta_seo/meta_seo.dart';
import 'package:zenrouter_docs/routes/docs/_configuration/seo_title.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

@ZenCoordinator(name: 'DocsCoordinator', routeBase: 'DocsRoute')
class CoordinatorConfig {}

class CustomDocsCoordinator extends DocsCoordinator {
  @override
  DefaultTransitionStrategy get transitionStrategy =>
      DefaultTransitionStrategy.none;
}

mixin RouteSeo on RouteUnique {
  String get title;
  String get description;
  String get keywords;
  // Optional meta tags with defaults
  String get author => 'Dai Duong';
  String? get ogImage => null; // URL to social media preview image
  String get ogType => 'website';
  TwitterCard? get twitterCard => TwitterCard.summaryLargeImage;
  String? get twitterSite => null; // e.g., '@yourusername'
  String? get canonicalUrl => null; // Canonical URL for this page
  String get language => 'en';
  String? get robots => null; // e.g., 'index, follow'

  final meta = MetaSEO();

  @override
  void onUpdate(covariant RouteTarget newRoute) {
    super.onUpdate(newRoute);
    buildSeo();
  }

  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) {
    buildSeo();
    return const SizedBox.shrink();
  }

  void buildSeo() {
    // Add MetaSEO just into Web platform condition
    if (kIsWeb) {
      // Basic meta tags
      meta.author(author: author);
      meta.description(description: description);
      meta.keywords(keywords: keywords);
      // Open Graph meta tags (for Facebook, LinkedIn, etc.)
      setWebTitle(title);
      meta.ogTitle(ogTitle: title);
      meta.ogDescription(ogDescription: description);
      if (ogImage != null) {
        meta.ogImage(ogImage: ogImage!);
      }
      // Twitter Card meta tags
      if (twitterCard != null) {
        meta.twitterCard(twitterCard: twitterCard!);
      }
      meta.twitterTitle(twitterTitle: title);
      meta.twitterDescription(twitterDescription: description);
      if (ogImage != null) {
        meta.twitterImage(twitterImage: ogImage!);
      }
      if (twitterSite != null) {
        // Note: You may need to add this manually if MetaSEO doesn't support it
        // or use meta.config() for custom tags
      }
      // Additional SEO tags
      if (robots != null) {
        // Use meta.config() for custom tags
        meta.robots(robotsName: RobotsName.robots, content: robots!);
      }
    }
  }
}
