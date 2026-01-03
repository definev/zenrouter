/// # Deep Linking
///
/// When your app is opened from a link - an email, a notification, a QR code -
/// you must reconstruct the appropriate navigation state. This is deep linking.
library;

import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'package:zenrouter_docs/routes/routes.zen.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/prose_section.dart';
import 'package:zenrouter_docs/widgets/code_block.dart';

part 'deep-linking.g.dart';

/// The Deep Linking documentation page.
@ZenRoute()
class DeepLinkingRoute extends _$DeepLinkingRoute {
  @override
  Widget build(covariant DocsCoordinator coordinator, BuildContext context) {
    final theme = Theme.of(context);
    final docs = theme.docs;

    return SingleChildScrollView(
      padding: docs.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deep Linking', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Universal Links and External Navigation',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          const ProseSection(
            content: '''
A deep link is a URL that opens your app at a specific location. When the user clicks a link like `myapp://product/abc123` or `https://myapp.com/product/abc123`, your app should open directly to that product - not to the home screen with no context.

The Coordinator handles deep links automatically through `parseRouteFromUri`. But sometimes you need more control over how the navigation stack is constructed.
''',
          ),
          const SizedBox(height: 32),

          Text('Default Behavior', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
By default, when a deep link arrives, the Coordinator:

1. Calls `parseRouteFromUri` to convert the URL to a route
2. Replaces the current navigation stack with the new route
3. The URL bar (on web) updates to reflect the new state

This works well for simple cases, but sometimes you need the deep link to set up a proper navigation hierarchy.
''',
          ),
          const SizedBox(height: 32),

          Text(
            'Custom Deep Link Handling',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
The RouteDeepLink mixin lets you customize how a route handles being the target of a deep link. You can set up the navigation stack however you like - ensuring that "back" navigation makes sense.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Custom Deep Link Handler',
            code: '''
class ProductRoute extends AppRoute with RouteDeepLink {
  ProductRoute({required this.productId});
  
  final String productId;
  
  // Use custom handling instead of default replace
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(
    AppCoordinator coordinator,
    Uri uri,
  ) async {
    // Build a sensible navigation stack:
    // Home → Shop Tab → Product
    
    // First, ensure we're on the shop tab
    coordinator.replace(TabsLayout());
    
    // Wait for layout to build
    await Future.delayed(Duration.zero);
    
    // Push to shop tab's stack
    coordinator.push(ShopTabLayout());
    
    // Finally, push this product
    coordinator.push(this);
    
    // Now "back" goes to shop list, then tabs, then home
    // Much better UX than orphaned product page!
  }
}''',
          ),
          const SizedBox(height: 32),

          Text('Deep Link Strategies', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
The `DeeplinkStrategy` enum provides three options:

**replace** (default) - Clear the stack and push this route. Simple but may lose navigation context.

**push** - Push onto the existing stack. Good when the current context is relevant.

**custom** - Use the `deeplinkHandler` method for full control.
''',
          ),
          const SizedBox(height: 16),

          const CodeBlock(
            title: 'Strategy Selection',
            code: '''
// Default: replaces stack
class ArticleRoute extends AppRoute {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.replace;
}

// Push onto existing stack
class NotificationDetailRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;
  // Good for notifications - preserves user's current context
}

// Full control
class CheckoutRoute extends AppRoute with RouteDeepLink {
  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;
  
  @override
  Future<void> deeplinkHandler(...) async {
    // Maybe check auth first, redirect if needed
    // Set up cart context
    // Then navigate to checkout
  }
}''',
          ),
          const SizedBox(height: 32),

          Text('Platform Setup', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          const ProseSection(
            content: '''
Deep linking requires platform configuration beyond ZenRouter. You'll need to:

**iOS**: Configure Associated Domains in Xcode and host an `apple-app-site-association` file on your domain.

**Android**: Add intent filters in `AndroidManifest.xml` and host an `assetlinks.json` file.

**Web**: Deep linking works automatically via the browser's URL bar.

See the official Flutter documentation on deep linking for platform-specific setup instructions.
''',
          ),
          const SizedBox(height: 48),

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
        onTap: () => coordinator.pushQueryParameters(),
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
                      'Next: Query Parameters',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reactive URL query parameters with selectorBuilder',
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
