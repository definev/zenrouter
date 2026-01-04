import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part 'blog.[...slugs].g.dart';

/// Example of catch-all route using dot notation.
///
/// Matches paths like:
/// - /blog/2024/01/my-post
/// - /blog/tutorials/flutter/basics
///
/// Equivalent to: blog/[...slugs]/index.dart
@ZenRoute()
class BlogSlugsRoute extends _$BlogSlugsRoute {
  BlogSlugsRoute({required super.slugs});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Post')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Path: /blog/${slugs.join("/")}'),
            const SizedBox(height: 16),
            Text('Segments: ${slugs.length}'),
            const SizedBox(height: 8),
            ...slugs.map((s) => Text('- $s')),
          ],
        ),
      ),
    );
  }
}
