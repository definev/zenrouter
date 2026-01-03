/// # Declarative Navigation
///
/// A shift in perspective: what if we did not *tell* the stack what to do,
/// but instead *described* what it should contain? The stack becomes a
/// function of state, not a sequence of commands.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'declarative.g.dart';

/// The Declarative Navigation documentation page.
@ZenRoute()
class DeclarativeRoute extends _$DeclarativeRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Declarative Navigation', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'State-Driven Routing',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
Consider the philosophy that underlies Flutter itself: you do not tell widgets how to update - you describe what they should look like given the current state, and Flutter reconciles your description with reality.

What if navigation worked the same way?

In declarative navigation, you do not push and pop. Instead, you maintain state - a list of items, a selected tab, a series of form steps - and derive your navigation stack from that state. When state changes, the stack updates automatically.
''',
          ),
          const SizedBox(height: 32),

          Text(
            'NavigationStack.declarative',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
ZenRouter provides a declarative variant of NavigationStack. Instead of binding to a NavigationPath that you mutate, you provide a list of routes directly - typically derived from your widget's state.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Declarative Navigation',
            code: '''
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
}''',
          ),
          const SizedBox(height: 32),

          Text(
            'The Myers Diff Algorithm',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
When your route list changes, ZenRouter must determine what actually changed. Did you add a route? Remove one? Replace one? The answer matters for animations - a push should animate differently than a pop.

ZenRouter uses the Myers diff algorithm (the same algorithm that powers `git diff`) to compute the minimal set of changes between the old and new route lists. Routes are compared using their `props` - the list of values that define their identity.
''',
          ),
          const SizedBox(height: 16),

          const ProseBlockquote(
            content:
                'This is why equality matters: if two routes have the same props, they are considered the same route. The diff algorithm can then determine that you added a new route rather than replaced everything.',
          ),
          const SizedBox(height: 32),

          Text(
            'When to Use Declarative',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
The declarative paradigm excels when:

• Your navigation is state-driven - tab selection, wizard steps, filtered lists
• You want navigation to stay in sync with application state automatically
• You're building interfaces where the "current screen" is a function of data
• You prefer React-like patterns where UI is a pure function of state

It struggles when:

• You need URLs to reflect navigation state
• You need deep linking from external sources  
• Your navigation is primarily event-driven (user taps → push)
''',
          ),
          const SizedBox(height: 32),

          const CodeBlock(
            title: 'Tab Bar Example',
            code: '''
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
}''',
          ),
          const SizedBox(height: 48),

          // Navigation to next page
          _buildNextPageCard(context, coordinator),

          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildNextPageCard(BuildContext context, DocsCoordinator coordinator) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => coordinator.pushCoordinator(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next: The Coordinator Pattern',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deep linking, URLs, and the synthesis of paradigms',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
