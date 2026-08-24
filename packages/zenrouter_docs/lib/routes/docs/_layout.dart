library;

import 'package:flutter/widgets.dart';
import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

part '_layout.g.dart';

@ZenLayout(type: LayoutType.stack)
class DocsLayout extends _$DocsLayout {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    return DocsLayoutBuilder(child: buildPath(coordinator));
  }
}
