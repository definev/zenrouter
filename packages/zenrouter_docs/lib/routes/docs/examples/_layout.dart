/// # Examples Section Layout
///
/// Pass-through layout - navigation is handled by the parent (docs) layout.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';

part '_layout.g.dart';

/// Pass-through layout for the Examples section.
@ZenLayout(type: LayoutType.stack)
class ExamplesLayout extends _$ExamplesLayout {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return buildPath(coordinator);
  }
}
