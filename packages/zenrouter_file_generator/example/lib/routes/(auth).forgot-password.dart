import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part '(auth).forgot-password.g.dart';

/// Example of route group using dot notation.
///
/// URL: /forgot-password (not /(auth)/forgot-password)
///
/// This route is wrapped by the (auth)/_layout.dart layout
/// but the (auth) segment is not part of the URL.
///
/// Equivalent to: (auth)/forgot-password.dart
@ZenRoute()
class ForgotPasswordRoute extends _$ForgotPasswordRoute {
  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_reset, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Enter your email to reset password',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.pushLogin(),
              child: const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
