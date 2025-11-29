import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// =============================================================================
/// IMPERATIVE MULTI-SCREEN FORM EXAMPLE (Proper State Management)
/// =============================================================================
/// This example demonstrates complex form handling with explicit state passing:
///
/// ✅ Routes carry their own state (no global variables)
/// ✅ State is passed through route constructors
/// ✅ Each route returns updated state via pop()
/// ✅ Testable, self-contained routes
/// ✅ Clear data flow
/// =============================================================================

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeView());
  }
}

// =============================================================================
// FORM DATA MODEL - Immutable state
// =============================================================================

class OnboardingFormData {
  final String? fullName;
  final String? email;
  final DateTime? birthDate;
  final List<String> interests;
  final bool enableNotifications;
  final String? username;
  final String? password;

  const OnboardingFormData({
    this.fullName,
    this.email,
    this.birthDate,
    this.interests = const [],
    this.enableNotifications = true,
    this.username,
    this.password,
  });

  // Validation helpers
  bool get isPersonalInfoComplete =>
      fullName != null && email != null && birthDate != null;

  bool get isPreferencesComplete => interests.isNotEmpty;

  bool get isAccountSetupComplete =>
      username != null && password != null && password!.length >= 6;

  // Copy with method for immutable updates
  OnboardingFormData copyWith({
    String? fullName,
    String? email,
    DateTime? birthDate,
    List<String>? interests,
    bool? enableNotifications,
    String? username,
    String? password,
  }) {
    return OnboardingFormData(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      interests: interests ?? this.interests,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

// =============================================================================
// ROUTE DEFINITIONS - Each route carries its state
// =============================================================================

sealed class OnboardingRoute with RouteTarget {
  Widget build(BuildContext context);
}

// =============================================================================
// STEP 1: Personal Information
// =============================================================================

class PersonalInfoStep extends OnboardingRoute with RouteGuard {
  // Route state passed via constructor
  final OnboardingFormData formData;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  PersonalInfoStep({required this.formData}) {
    // Initialize from route state (not global)
    _nameController.text = formData.fullName ?? '';
    _emailController.text = formData.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final shouldExit = await _showExitConfirmation(context);
            if (shouldExit) {
              // Return to welcome instead of empty path
              onboardingPath.clear();
              onboardingPath.push(WelcomeStep());
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 1 of 3', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const LinearProgressIndicator(value: 0.33),
            const SizedBox(height: 32),
            const Text(
              'Tell us about yourself',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            _DatePickerField(
              label: 'Date of Birth *',
              selectedDate: formData.birthDate,
              onDateSelected: (date) {
                // Update via copyWith
                final updated = formData.copyWith(birthDate: date);
                // Replace current route with updated state
                onboardingPath.stack.last = PersonalInfoStep(formData: updated);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _onNext(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  // Return to welcome instead of empty path
                  onboardingPath.clear();
                  onboardingPath.push(WelcomeStep());
                },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNext(BuildContext context) {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        formData.birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Create updated state
    final updatedData = formData.copyWith(
      fullName: _nameController.text,
      email: _emailController.text,
    );

    // Navigate with state
    onboardingPath.push(PreferencesStep(formData: updatedData));
  }

  @override
  Future<bool> popGuard() async => true;

  Future<bool> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Onboarding?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// =============================================================================
// STEP 2: Preferences
// =============================================================================

class PreferencesStep extends OnboardingRoute {
  // Route state
  final OnboardingFormData formData;

  PreferencesStep({required this.formData});

  final List<String> availableInterests = [
    'Technology',
    'Sports',
    'Music',
    'Art',
    'Travel',
    'Food',
    'Reading',
    'Gaming',
  ];

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Preferences'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => onboardingPath.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Step 2 of 3', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const LinearProgressIndicator(value: 0.66),
                const SizedBox(height: 32),
                const Text(
                  'What interests you?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select at least one interest',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableInterests.map((interest) {
                    final isSelected = formData.interests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          final newInterests = List<String>.from(
                            formData.interests,
                          );
                          if (selected) {
                            newInterests.add(interest);
                          } else {
                            newInterests.remove(interest);
                          }
                          // Update route with new state
                          final updated = formData.copyWith(
                            interests: newInterests,
                          );
                          onboardingPath.stack.last = PreferencesStep(
                            formData: updated,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text(
                    'Get updates about topics you care about',
                  ),
                  value: formData.enableNotifications,
                  onChanged: (value) {
                    setState(() {
                      final updated = formData.copyWith(
                        enableNotifications: value,
                      );
                      onboardingPath.stack.last = PreferencesStep(
                        formData: updated,
                      );
                    });
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: formData.isPreferencesComplete
                      ? () => onboardingPath.push(
                          AccountSetupStep(formData: formData),
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('Continue'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () {
                      final updated = formData.copyWith(
                        interests: ['Technology'],
                      );
                      onboardingPath.push(AccountSetupStep(formData: updated));
                    },
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// STEP 3: Account Setup
// =============================================================================

class AccountSetupStep extends OnboardingRoute with RouteGuard {
  final OnboardingFormData formData;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AccountSetupStep({required this.formData}) {
    _usernameController.text = formData.username ?? '';
    _passwordController.text = formData.password ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onboardingPath.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Step 3 of 3', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const LinearProgressIndicator(value: 1.0),
            const SizedBox(height: 32),
            const Text(
              'Create your account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
                helperText: 'Choose a unique username',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                helperText: 'At least 6 characters',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _onNext(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Review & Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _onNext(BuildContext context) {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final updatedData = formData.copyWith(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    onboardingPath.push(ReviewStep(formData: updatedData));
  }

  @override
  Future<bool> popGuard() async => true;
}

// =============================================================================
// STEP 4: Review & Submit
// =============================================================================

class ReviewStep extends OnboardingRoute {
  final OnboardingFormData formData;

  ReviewStep({required this.formData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onboardingPath.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Review Your Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please review your details before submitting',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _ReviewSection(
              title: 'Personal Information',
              onEdit: () {
                // Pop back to personal info with current state
                onboardingPath.pop();
                onboardingPath.pop();
                onboardingPath.pop();
              },
              children: [
                _ReviewItem('Name', formData.fullName ?? ''),
                _ReviewItem('Email', formData.email ?? ''),
                _ReviewItem(
                  'Birth Date',
                  formData.birthDate?.toString().split(' ')[0] ?? '',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ReviewSection(
              title: 'Preferences',
              onEdit: () {
                onboardingPath.pop();
                onboardingPath.pop();
              },
              children: [
                _ReviewItem('Interests', formData.interests.join(', ')),
                _ReviewItem(
                  'Notifications',
                  formData.enableNotifications ? 'Enabled' : 'Disabled',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ReviewSection(
              title: 'Account',
              onEdit: () => onboardingPath.pop(),
              children: [
                _ReviewItem('Username', formData.username ?? ''),
                _ReviewItem('Password', '••••••••'),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _onSubmit(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
              ),
              child: const Text('Complete Onboarding'),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pop(context);
        onboardingPath.push(SuccessStep(formData: formData));
      }
    });
  }
}

// =============================================================================
// SUCCESS SCREEN
// =============================================================================

class SuccessStep extends OnboardingRoute {
  final OnboardingFormData formData;

  SuccessStep({required this.formData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 32),
              const Text(
                'Welcome aboard!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Hi ${formData.fullName}! Your account has been created successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Return to welcome - path should never be empty
                  onboardingPath.clear();
                  onboardingPath.push(WelcomeStep());
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WELCOME SCREEN
// =============================================================================

class WelcomeStep extends OnboardingRoute {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.rocket_launch, size: 100, color: Colors.blue),
              const SizedBox(height: 32),
              const Text(
                'Multi-Screen Form Demo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Proper state management - each route carries its own state!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // Start with empty state
                  onboardingPath.push(
                    PersonalInfoStep(formData: const OnboardingFormData()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Start Onboarding'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Start with pre-filled state
                  final demoData = OnboardingFormData(
                    fullName: 'Demo User',
                    email: 'demo@example.com',
                    birthDate: DateTime(1990, 1, 1),
                  );
                  onboardingPath.push(PreferencesStep(formData: demoData));
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Skip to Step 2 (Demo)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

class _DatePickerField extends StatefulWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: widget.selectedDate ?? DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          widget.onDateSelected(date);
          setState(() {});
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          widget.selectedDate != null
              ? widget.selectedDate.toString().split(' ')[0]
              : 'Select date',
          style: TextStyle(
            color: widget.selectedDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// NAVIGATION PATH
// =============================================================================

final onboardingPath = NavigationPath<OnboardingRoute>()..push(WelcomeStep());

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationStack<OnboardingRoute>(
      path: onboardingPath,
      resolver: (route) => switch (route) {
        WelcomeStep() => RouteDestination.material(route.build(context)),
        PersonalInfoStep() => RouteDestination.material(
          route.build(context),
          guard: route,
        ),
        PreferencesStep() => RouteDestination.material(route.build(context)),
        AccountSetupStep() => RouteDestination.material(
          route.build(context),
          guard: route,
        ),
        ReviewStep() => RouteDestination.material(route.build(context)),
        SuccessStep() => RouteDestination.material(route.build(context)),
      },
    );
  }
}
