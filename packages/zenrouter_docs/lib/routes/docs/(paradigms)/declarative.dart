/// # Declarative Navigation
///
/// A shift in perspective: what if we did not *tell* the stack what to do,
/// but instead *described* what it should contain? The stack becomes a
/// function of state, not a sequence of commands.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/_coordinator.dart';
import 'package:zenrouter_docs/widgets/docs_layout.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/widgets/doc_page.dart';

part 'declarative.g.dart';

/// The Declarative Navigation documentation page.
@ZenRoute()
class DeclarativeRoute extends _$DeclarativeRoute with RouteSeo {
  @override
  String get title => 'Declarative Navigation';

  @override
  String get description => 'State-Driven Routing';

  @override
  String get keywords => 'Declarative Navigation, State-Driven, Flutter';

  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    super.build(coordinator, context);
    final tocController = DocsTocScope.of(context);

    return DocPage(
      title: 'Declarative Navigation',
      subtitle: 'State-Driven Routing',
      tocController: tocController,
      markdown: '''
Consider the philosophy that underlies Flutter itself: you do not tell widgets how to update - you describe what they should look like given the current state, and Flutter reconciles your description with reality.

What if navigation worked the same way?

In declarative navigation, you do not push and pop. Instead, you maintain state - a list of items, a selected tab, a series of form steps - and derive your navigation stack from that state. When state changes, the stack updates automatically.

## NavigationStack.declarative

ZenRouter provides a declarative variant of NavigationStack. Instead of binding to a NavigationPath that you mutate, you provide a list of routes directly - typically derived from your widget's state.

\`\`\`dart
class MultiStepForm extends StatefulWidget {
  @override
  State<MultiStepForm> createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<MultiStepForm> {
  final List<FormStep> _completedSteps = [];
  FormStep _currentStep = FormStep.personal;

  @override
  Widget build(BuildContext context) {
    return NavigationStack.declarative(
      // The stack is derived from state
      routes: [
        for (final step in _completedSteps) StepRoute(step),
        StepRoute(_currentStep),
      ],
      resolver: (route) => StackTransition.material(
        route.build(context),
      ),
    );
  }
  
  void completeStep() {
    setState(() {
      _completedSteps.add(_currentStep);
      _currentStep = _currentStep.next;
    });
    // No push() call needed - the stack updates from state
  }
}
\`\`\`

## The Myers Diff Algorithm

When your route list changes, ZenRouter must determine what actually changed. Did you add a route? Remove one? Replace one? The answer matters for animations - a push should animate differently than a pop.

ZenRouter uses the Myers diff algorithm (the same algorithm that powers `git diff`) to compute the minimal set of changes between the old and new route lists. Routes are compared using their `props` - the list of values that define their identity.

> This is why equality matters: if two routes have the same props, they are considered the same route. The diff algorithm can then determine that you added a new route rather than replaced everything.

## When to Use Declarative

The declarative paradigm excels when:

• Your navigation is state-driven - tab selection, wizard steps, filtered lists
• You want navigation to stay in sync with application state automatically
• You're building interfaces where the "current screen" is a function of data
• You prefer React-like patterns where UI is a pure function of state

It struggles when:

• You need URLs to reflect navigation state
• You need deep linking from external sources  
• Your navigation is primarily event-driven (user taps → push)

\`\`\`dart
class TabExample extends StatefulWidget {
  @override
  State<TabExample> createState() => _TabExampleState();
}

class _TabExampleState extends State<TabExample> {
  int _selectedTab = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NavigationStack.declarative(
        routes: [
          // Base route is always present
          HomeRoute(),
          // The visible tab depends on state
          switch (_selectedTab) {
            0 => FeedRoute(),
            1 => SearchRoute(),
            2 => ProfileRoute(),
            _ => FeedRoute(),
          },
        ],
        resolver: (route) => StackTransition.fade(
          route.build(context),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        items: [...],
      ),
    );
  }
}
\`\`\`
''',
    );
  }
}
