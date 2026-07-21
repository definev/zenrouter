import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

/// =============================================================================
/// ROUTE GUARD RULES EXAMPLE
/// =============================================================================
/// Demonstrates composable [RouteGuardRule] / [GuardRule]:
///
/// - UnsavedChangesRule — reactive canPop + discard dialog
/// - UploadInProgressRule — block leave while uploading
/// - ConfirmLeaveRule — always confirm
/// - GuardAuditRule — logging only (always continues)
///
/// Run:
///   flutter run -t lib/main_guard_rules.dart
/// =============================================================================

void main() {
  runApp(const GuardRulesApp());
}

class GuardRulesApp extends StatelessWidget {
  const GuardRulesApp({super.key});

  static final coordinator = GuardRulesCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Guard Rules',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// =============================================================================
// Coordinator
// =============================================================================

class GuardRulesCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug {
  @override
  Uri? get initialRoutePath => Uri.parse('/');

  @override
  List<AppRoute> get debugRoutes => [
    HomeRoute(),
    EditorRoute(documentId: 'demo'),
    SettingsRoute(),
    UploadRoute(jobId: 'job-1'),
  ];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['editor', final id] => EditorRoute(documentId: id),
      ['settings'] => SettingsRoute(),
      ['upload', final id] => UploadRoute(jobId: id),
      _ => HomeRoute(),
    };
  }
}

// =============================================================================
// Route base
// =============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// =============================================================================
// Shared dialogs
// =============================================================================

Future<bool> showDiscardDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text('You have unsaved changes. Leave without saving?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Stay'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showCancelUploadDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel upload?'),
      content: const Text('Upload is still in progress.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep uploading'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cancel upload'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showConfirmLeaveDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave this screen?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  return result ?? false;
}

// =============================================================================
// GuardRules
// =============================================================================

/// Blocks leave while a form has unsaved edits.
class UnsavedChangesRule extends GuardRule<AppRoute> {
  const UnsavedChangesRule();

  @override
  bool canPop(AppRoute route) {
    if (route is! EditableRoute) return true;
    return !route.hasUnsavedChanges;
  }

  @override
  ListenableMixin? canPopListenable(AppRoute route) {
    if (route is! EditableRoute) return null;
    return route.dirty.toListenableMixin();
  }

  @override
  Future<bool?> guard(
    covariant GuardRulesCoordinator coordinator,
    AppRoute route,
  ) async {
    if (route is! EditableRoute || !route.hasUnsavedChanges) return null;
    final context = coordinator.navigator.context;
    if (!context.mounted) return false;
    return showDiscardDialog(context);
  }
}

/// Blocks leave while an upload job is running.
class UploadInProgressRule extends GuardRule<AppRoute> {
  const UploadInProgressRule();

  @override
  bool canPop(AppRoute route) {
    if (route is! UploadableRoute) return true;
    return !route.isUploading;
  }

  @override
  ListenableMixin? canPopListenable(AppRoute route) {
    if (route is! UploadableRoute) return null;
    return route.uploading.toListenableMixin();
  }

  @override
  Future<bool?> guard(
    covariant GuardRulesCoordinator coordinator,
    AppRoute route,
  ) async {
    if (route is! UploadableRoute || !route.isUploading) return null;
    final context = coordinator.navigator.context;
    if (!context.mounted) return false;
    final leave = await showCancelUploadDialog(context);
    if (leave) route.cancelUpload();
    return leave;
  }
}

/// Always asks for confirmation.
class ConfirmLeaveRule extends GuardRule<AppRoute> {
  const ConfirmLeaveRule();

  @override
  bool canPop(AppRoute route) => false;

  @override
  Future<bool?> guard(
    covariant GuardRulesCoordinator coordinator,
    AppRoute route,
  ) async {
    final context = coordinator.navigator.context;
    if (!context.mounted) return false;
    return showConfirmLeaveDialog(context);
  }
}

/// Logging only — never decides; always continues.
class GuardAuditRule extends GuardRule<AppRoute> {
  const GuardAuditRule();

  @override
  Future<bool?> guard(
    covariant GuardRulesCoordinator coordinator,
    AppRoute route,
  ) async {
    debugPrint('[GuardAudit] pop attempted from ${route.toUri()}');
    return null;
  }
}

// =============================================================================
// Route capability mixins
// =============================================================================

mixin EditableRoute on AppRoute {
  final dirty = ValueNotifier(false);

  bool get hasUnsavedChanges => dirty.value;

  void markDirty() => dirty.value = true;

  void markClean() => dirty.value = false;

  @override
  void onDiscard() {
    dirty.dispose();
    super.onDiscard();
  }
}

mixin UploadableRoute on AppRoute {
  final uploading = ValueNotifier(false);
  Timer? _uploadTimer;

  bool get isUploading => uploading.value;

  void startUpload({Duration duration = const Duration(seconds: 8)}) {
    _uploadTimer?.cancel();
    uploading.value = true;
    _uploadTimer = Timer(duration, cancelUpload);
  }

  void cancelUpload() {
    _uploadTimer?.cancel();
    _uploadTimer = null;
    uploading.value = false;
  }

  @override
  void onDiscard() {
    cancelUpload();
    uploading.dispose();
    super.onDiscard();
  }
}

// =============================================================================
// Routes
// =============================================================================

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant GuardRulesCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guard Rules Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Try system back / AppBar back on each screen.\n'
            'Clean screens pop freely; dirty / uploading / confirm screens intercept.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          _DemoCard(
            icon: Icons.edit_note,
            title: 'Editor',
            subtitle: 'UnsavedChangesRule — type to mark dirty',
            onTap: () => coordinator.push(EditorRoute(documentId: '42')),
          ),
          _DemoCard(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'ConfirmLeaveRule — always asks',
            onTap: () => coordinator.push(SettingsRoute()),
          ),
          _DemoCard(
            icon: Icons.cloud_upload,
            title: 'Upload',
            subtitle: 'Upload + unsaved caption (rule chain)',
            onTap: () => coordinator.push(UploadRoute(jobId: 'job-1')),
          ),
        ],
      ),
    );
  }
}

class EditorRoute extends AppRoute
    with EditableRoute, RouteGuardRule<AppRoute> {
  EditorRoute({required this.documentId});

  final String documentId;

  @override
  List<Object?> get props => [documentId];

  @override
  List<GuardRule> get guardRules => const [
    GuardAuditRule(),
    UnsavedChangesRule(),
  ];

  @override
  Uri toUri() => Uri.parse('/editor/$documentId');

  @override
  Widget build(covariant GuardRulesCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor $documentId'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: dirty,
            builder: (context, isDirty, _) => TextButton(
              onPressed: isDirty ? markClean : null,
              child: Text(isDirty ? 'Save' : 'Saved'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: dirty,
              builder: (context, isDirty, _) => Text(
                isDirty ? 'Status: unsaved changes' : 'Status: clean (free back)',
                style: TextStyle(
                  color: isDirty ? Colors.orange.shade800 : Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Start typing to mark dirty…',
                ),
                onChanged: (_) => markDirty(),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsRoute extends AppRoute with RouteGuardRule<AppRoute> {
  @override
  List<GuardRule> get guardRules => const [ConfirmLeaveRule()];

  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant GuardRulesCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Back always shows a confirmation dialog '
          '(ConfirmLeaveRule.canPop → false).',
        ),
      ),
    );
  }
}

class UploadRoute extends AppRoute
    with EditableRoute, UploadableRoute, RouteGuardRule<AppRoute> {
  UploadRoute({required this.jobId});

  final String jobId;

  @override
  List<Object?> get props => [jobId];

  @override
  List<GuardRule> get guardRules => const [
    GuardAuditRule(),
    UploadInProgressRule(),
    UnsavedChangesRule(),
  ];

  @override
  Uri toUri() => Uri.parse('/upload/$jobId');

  @override
  Widget build(covariant GuardRulesCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload $jobId')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: uploading,
              builder: (context, isUploading, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: dirty,
                  builder: (context, isDirty, _) => Text(
                    'Upload: ${isUploading ? "in progress" : "idle"} · '
                    'Caption: ${isDirty ? "unsaved" : "clean"}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Caption',
              ),
              onChanged: (_) => markDirty(),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: uploading,
              builder: (context, isUploading, _) => FilledButton.icon(
                onPressed: isUploading ? null : () => startUpload(),
                icon: const Icon(Icons.cloud_upload),
                label: Text(isUploading ? 'Uploading…' : 'Start upload (8s)'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'While uploading, back asks to cancel the upload first.\n'
              'If upload is idle but caption is dirty, discard dialog runs.',
              style: TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// UI helpers
// =============================================================================

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
