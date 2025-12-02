import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// =============================================================================
/// SIMPLE DECLARATIVE NAVIGATION WITH MYERS DIFF DEMO
/// =============================================================================
/// This example demonstrates how Myers diff efficiently updates the navigation
/// stack. Add or remove chips to see the navigation stack update with minimal
/// operations - only changed routes are added/removed!
/// =============================================================================

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Declarative Navigation Demo',
      home: DemoScreen(),
    );
  }
}

// Simple route definition
class PageRoute extends RouteTarget {
  final int pageNumber;

  PageRoute(this.pageNumber);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PageRoute && other.pageNumber == pageNumber);

  @override
  int get hashCode => Object.hash(runtimeType, pageNumber);
}

class SpecialRoute extends RouteTarget {}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // State: list of page numbers to show
  final List<int> _pageNumbers = [1];
  int _nextPageNumber = 2;
  bool showSpecial = false;

  void _addPage() {
    setState(() {
      _pageNumbers.add(_nextPageNumber);
      _nextPageNumber++;
    });
  }

  void _removePage(int pageNumber) {
    setState(() {
      _pageNumbers.remove(pageNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Declarative navigation stack
          Expanded(
            child: NavigationStack.declarative(
              routes: <RouteTarget>[
                for (final pageNumber in _pageNumbers) PageRoute(pageNumber),
                if (showSpecial) SpecialRoute(),
              ],
              resolver: (route) => switch (route) {
                SpecialRoute() => RouteDestination.sheet(_buildSpecial()),
                PageRoute(:final pageNumber) => RouteDestination.material(
                  _buildPage(pageNumber),
                ),
                _ => throw UnimplementedError(),
              },
            ),
          ),
          // Chip controls at the top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.amber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: showSpecial,
                      onChanged: (value) =>
                          setState(() => showSpecial = !showSpecial),
                    ),
                    Text('Show special page'),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addPage,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Page'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pageNumbers.isEmpty)
                  const Text(
                    'No pages - add one to get started!',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pageNumbers.map((pageNum) {
                      return Chip(
                        key: ValueKey('Chip-$pageNum'),
                        label: Text('Page $pageNum'),
                        onDeleted: _pageNumbers.length > 1
                            ? () => _removePage(pageNum)
                            : null,
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int pageNumber) {
    return PageView(pageNumber: pageNumber);
  }

  Widget _buildSpecial() {
    return Scaffold(
      appBar: AppBar(title: Text('Super special route with sheet!')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => setState(() => showSpecial = false),
          child: const Text('Pop sheet'),
        ),
      ),
    );
  }
}

// Stateful page widget to demonstrate state preservation
class PageView extends StatefulWidget {
  final int pageNumber;

  const PageView({super.key, required this.pageNumber});

  @override
  State<PageView> createState() => _PageViewState();
}

class _PageViewState extends State<PageView> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page ${widget.pageNumber}'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              'This page is part of a declarative navigation stack',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Counter to demonstrate state preservation
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: Colors.green, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'State Preservation Demo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Counter: $_counter',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _incrementCounter,
                    icon: const Icon(Icons.add),
                    label: const Text('Increment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Try adding/removing other pages.\n'
                    'This counter stays preserved!',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
