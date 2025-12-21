import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part 'index.g.dart';

/// Home route at /
@ZenRoute()
class IndexRoute extends _$IndexRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to ZenRouter File-based Routing!'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => coordinator.pushAbout(),
                child: const Text('Go to About'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    coordinator.pushProfileId(profileId: 'user-123'),
                child: const Text('Go to Profile'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => coordinator.pushFollowing(),
                child: const Text('Go to Tabs'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => coordinator.recoverForYouSheet(),
                child: const Text('Go to For you sheets'),
              ),
              const SizedBox(height: 24),
              // Dot Notation Demo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Dot Notation Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Routes defined using dots instead of folders\n'
                      'e.g., blog.[...slugs].dart → /blog/*',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => coordinator.pushBlogSlugs(
                        slugs: ['2024', '12', 'hello-world'],
                      ),
                      icon: const Icon(Icons.article),
                      label: const Text('Blog Post (catch-all)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          coordinator.pushShopProductsProductIdReviews(
                            productId: 'prod-456',
                          ),
                      icon: const Icon(Icons.reviews),
                      label: const Text('Product Reviews'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => coordinator.pushSettingsAccountIndex(),
                      icon: const Icon(Icons.settings),
                      label: const Text('Account Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => coordinator.pushForgotPassword(),
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Forgot Password'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => coordinator.pushCollectionsCollectionId(
                        profileId: 'user-123',
                        collectionId: 'col-789',
                      ),
                      icon: const Icon(Icons.collections),
                      label: const Text('Collections (hybrid)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Route Groups Demo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Routes in (auth) folder are wrapped by AuthLayout\n'
                      'but the URL does NOT include "(auth)"',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => coordinator.pushLogin(),
                      icon: const Icon(Icons.login),
                      label: const Text('Go to Login (/login)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => coordinator.pushRegister(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Go to Register (/register)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
