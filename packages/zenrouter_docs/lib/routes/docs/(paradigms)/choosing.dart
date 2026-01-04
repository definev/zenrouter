/// # Choosing Your Paradigm
///
/// For the practical reader who seeks not philosophy but guidance:
/// a decision tree for selecting the right navigation approach.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'choosing.g.dart';

/// The Choosing Your Paradigm documentation page.
@ZenRoute()
class ChoosingRoute extends _$ChoosingRoute with RouteSeo {
  @override
  String get title => 'Choosing Your Paradigm';

  @override
  String get description => 'A Practical Decision Guide';

  @override
  String get keywords => 'Paradigms, Navigation, Decision Guide, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Choosing Your Paradigm',
      subtitle: 'A Practical Decision Guide',
      tocController: tocController,
      markdown: '''
Philosophy has its place, but at some point you must ship. This guide will help you select the right paradigm for your specific needs.

## Decision Flowchart

**Do you need deep linking or web support?**

- **YES** → Use Coordinator
  - URLs, browser back button, shareable links

- **NO** → Is navigation driven by application state?
  - **YES** → Use Declarative
    - Tab bars, wizards, filtered lists
  - **NO** → Use Imperative
    - Simple, event-driven, direct control

## Comparison Table

| Feature | Imperative | Declarative | Coordinator |
|---------|------------|-------------|-------------|
| Complexity | Simple | Moderate | Advanced |
| Deep Linking | No | No | Yes |
| Web Support | No | No | Yes |
| URL Sync | No | No | Yes |
| State-Driven | Manual | Native | Supported |
| File-Based Routing | No | No | Yes |
| Nested Navigation | Manual | Manual | Built-in |
| Best For | Mobile apps | Tab bars | Web, large apps |

## Can I Mix Paradigms?

Yes, and this is often the right approach. Consider:

- Use Coordinator for your app's main navigation (to enable deep linking)
- Use Declarative within a specific screen (a wizard, a tab bar)
- Use Imperative for simple modal flows within a screen

The paradigms are not mutually exclusive. They solve different problems at different scales. A Coordinator can contain screens that internally use declarative navigation, and those screens might spawn imperative modal flows.

> When in doubt, start with Coordinator. It offers the most capability, and zenrouter_file_generator makes it nearly as simple as imperative navigation. You can always simplify later.
''',
    );
  }
}
