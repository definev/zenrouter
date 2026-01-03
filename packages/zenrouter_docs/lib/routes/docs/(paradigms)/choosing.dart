/// # Choosing Your Paradigm
///
/// For the practical reader who seeks not philosophy but guidance:
/// a decision tree for selecting the right navigation approach.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_docs/routes/docs/(concepts)/routes-and-paths.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';

part 'choosing.g.dart';

/// The Choosing Your Paradigm documentation page.
@ZenRoute()
class ChoosingRoute extends _$ChoosingRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choosing Your Paradigm', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'A Practical Decision Guide',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
Philosophy has its place, but at some point you must ship. This guide will help you select the right paradigm for your specific needs.
''',
          ),
          const SizedBox(height: 32),

          // Decision tree
          _buildDecisionTree(context),
          const SizedBox(height: 48),

          Text('Comparison Table', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          _buildComparisonTable(context),
          const SizedBox(height: 48),

          Text('Can I Mix Paradigms?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Yes, and this is often the right approach. Consider:

• Use Coordinator for your app's main navigation (to enable deep linking)
• Use Declarative within a specific screen (a wizard, a tab bar)
• Use Imperative for simple modal flows within a screen

The paradigms are not mutually exclusive. They solve different problems at different scales. A Coordinator can contain screens that internally use declarative navigation, and those screens might spawn imperative modal flows.
''',
          ),
          const SizedBox(height: 32),

          const ProseBlockquote(
            content:
                'When in doubt, start with Coordinator. It offers the most capability, and zenrouter_file_generator makes it nearly as simple as imperative navigation. You can always simplify later.',
          ),
          const SizedBox(height: 48),

          // Navigation to concepts
          _buildNextSectionCard(context, coordinator),

          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildDecisionTree(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Decision Flowchart', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),

          _DecisionNode(
            question: 'Do you need deep linking or web support?',
            yesAnswer: 'Use Coordinator',
            yesExplanation: '→ URLs, browser back button, shareable links',
            noLeadsTo: _DecisionNode(
              question: 'Is navigation driven by application state?',
              yesAnswer: 'Use Declarative',
              yesExplanation: '→ Tab bars, wizards, filtered lists',
              noLeadsTo: _DecisionNode(
                question: '',
                yesAnswer: 'Use Imperative',
                yesExplanation: '→ Simple, event-driven, direct control',
                noLeadsTo: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        columns: const [
          DataColumn(label: Text('Feature')),
          DataColumn(label: Text('Imperative')),
          DataColumn(label: Text('Declarative')),
          DataColumn(label: Text('Coordinator')),
        ],
        rows: const [
          DataRow(
            cells: [
              DataCell(Text('Complexity')),
              DataCell(Text('Simple')),
              DataCell(Text('Moderate')),
              DataCell(Text('Advanced')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Deep Linking')),
              DataCell(Text('No')),
              DataCell(Text('No')),
              DataCell(Text('Yes')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Web Support')),
              DataCell(Text('No')),
              DataCell(Text('No')),
              DataCell(Text('Yes')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('URL Sync')),
              DataCell(Text('No')),
              DataCell(Text('No')),
              DataCell(Text('Yes')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('State-Driven')),
              DataCell(Text('Manual')),
              DataCell(Text('Native')),
              DataCell(Text('Supported')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('File-Based Routing')),
              DataCell(Text('No')),
              DataCell(Text('No')),
              DataCell(Text('Yes')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Nested Navigation')),
              DataCell(Text('Manual')),
              DataCell(Text('Manual')),
              DataCell(Text('Built-in')),
            ],
          ),
          DataRow(
            cells: [
              DataCell(Text('Best For')),
              DataCell(Text('Mobile apps')),
              DataCell(Text('Tab bars')),
              DataCell(Text('Web, large apps')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextSectionCard(
    BuildContext context,
    DocsCoordinator coordinator,
  ) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () => coordinator.navigate(RoutesAndPathsRoute()),
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
                      'Continue to Core Concepts',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Now that you understand the paradigms, dive deeper into Routes, Paths, and the Stack.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.arrow_forward,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A node in the decision tree visualization.
class _DecisionNode extends StatelessWidget {
  const _DecisionNode({
    required this.question,
    required this.yesAnswer,
    required this.yesExplanation,
    required this.noLeadsTo,
  });

  final String question;
  final String yesAnswer;
  final String yesExplanation;
  final Widget? noLeadsTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (question.isEmpty) {
      // Terminal node
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              yesAnswer,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(yesExplanation, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            question,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Yes branch
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'YES',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_right, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yesAnswer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(yesExplanation, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),

        // No branch
        if (noLeadsTo != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_downward, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(left: 48), child: noLeadsTo!),
        ],
      ],
    );
  }
}
