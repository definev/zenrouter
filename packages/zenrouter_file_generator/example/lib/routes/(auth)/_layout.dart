import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import '../routes.zen.dart';

part '_layout.g.dart';

/// Auth layout - wraps login and register routes.
///
/// This layout is in a route group folder `(auth)`, which means:
/// - Routes inside are wrapped by this layout
/// - The URL path does NOT include `(auth)` segment
///
/// Example:
/// - `(auth)/login.dart` → URL: `/login`
/// - `(auth)/register.dart` → URL: `/register`
@ZenLayout(type: LayoutType.stack)
class AuthLayout extends _$AuthLayout {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B5CE7), Color(0xFF9B8DFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Auth header
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.lock_outline, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in or create an account',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Auth content (nested routes)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: RouteLayout.buildPrimitivePath(
                      NavigationPath,
                      coordinator,
                      resolvePath(coordinator),
                      this,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
