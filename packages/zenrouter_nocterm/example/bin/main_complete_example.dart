import 'dart:async';

import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_nocterm/zenrouter_nocterm.dart';

// ============================================================================
// DevOps Dashboard — A terminal-native zenrouter_nocterm example
// ============================================================================
//
// This example demonstrates zenrouter_nocterm with patterns natural to
// terminal UIs: keyboard-driven navigation, split panes, status bars,
// interactive text fields, progress bars, and real-time counters.
//
// Architecture:
//
//   AppCoordinator
//   └── DashboardLayout (IndexedStackPath — tab switching via 1/2/3/4)
//       ├── [1] Dashboard   — system overview with live counters
//       ├── [2] Tasks       — interactive task list with add/complete
//       ├── [3] Logs        — scrollable log viewer with filter
//       └── [4] Settings    — form-like settings editor
//
//   Nested push-stack routes (deep navigation):
//
//   Dashboard drill-down (4 levels deep):
//       Dashboard → ServiceDetailRoute → ServiceLogsRoute → LogEntryDetailRoute
//
//   Task comments chain (3 levels deep):
//       TaskDetailRoute → TaskCommentsRoute → CommentReplyRoute
//
// Navigation:
//   • 1-4 to switch tabs (from any tab)
//   • Tab-specific shortcuts shown in each view
//   • ESC to go back from pushed routes (pops one level)
//   • q to quit from any tab
//
// ============================================================================

void main() {
  runApp(const DevDashboardApp());
}

class DevDashboardApp extends StatefulComponent {
  const DevDashboardApp({super.key});

  @override
  State<DevDashboardApp> createState() => _DevDashboardAppState();
}

class _DevDashboardAppState extends State<DevDashboardApp> {
  final coordinator = AppCoordinator();

  @override
  Component build(BuildContext context) {
    return NoctermApp(child: CoordinatorComponent(coordinator: coordinator));
  }
}

// ============================================================================
// Coordinator
// ============================================================================

final class AppCoordinator extends Coordinator<AppRoute> {
  late final tabPath = IndexedStackPath.createWith(
    coordinator: this,
    label: 'tabs',
    [DashboardTab(), TasksTab(), LogsTab(), SettingsTab()],
  )..bindLayout(DashboardLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, tabPath];

  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] || ['dashboard'] => DashboardTab(),
      ['tasks'] => TasksTab(),
      ['logs'] => LogsTab(),
      ['settings'] => SettingsTab(),
      // Nested: Dashboard → Service → Logs → LogEntry
      ['services', final id] => ServiceDetailRoute(serviceId: id),
      ['services', final id, 'logs'] => ServiceLogsRoute(serviceId: id),
      ['services', final id, 'logs', final logId] => LogEntryDetailRoute(
        serviceId: id,
        logId: logId,
      ),
      // Nested: Tasks → Detail → Comments → Reply
      ['tasks', final id] => TaskDetailRoute(taskId: id),
      ['tasks', final id, 'comments'] => TaskCommentsRoute(taskId: id),
      ['tasks', final id, 'comments', final cId] => CommentReplyRoute(
        taskId: id,
        commentId: cId,
      ),
      _ => DashboardTab(),
    };
  }

  @override
  Component layoutBuilder(BuildContext context) {
    return Column(
      children: [
        Expanded(child: super.layoutBuilder(context)),
        ListenableBuilder(
          listenable: this,
          builder: (context, child) => _StatusBar(currentUri: currentUri),
        ),
      ],
    );
  }
}

// ============================================================================
// Route Base
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Dashboard Layout — header/tab-bar/content/status-bar
// ============================================================================

class DashboardLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.tabPath;

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    final path = coordinator.tabPath;
    return ListenableBuilder(
      listenable: path,
      builder: (context, _) {
        return Column(
          children: [
            // ── Header ──
            _Header(),
            // ── Tab bar ──
            _TabBar(path: path),
            // ── Content ──
            Expanded(child: buildPath(coordinator)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.cyan),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: Row(
          children: [
            Text(
              '◈ DevOps Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Expanded(child: SizedBox()),
            Text(
              'zenrouter_nocterm',
              style: TextStyle(color: Colors.brightBlack),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessComponent {
  const _TabBar({required this.path});
  final IndexedStackPath<AppRoute> path;

  @override
  Component build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: BoxBorder(bottom: BorderSide())),
      child: Row(
        children: [
          _TabButton(label: '[1] Dashboard', isActive: path.activeIndex == 0),
          _TabButton(label: '[2] Tasks', isActive: path.activeIndex == 1),
          _TabButton(label: '[3] Logs', isActive: path.activeIndex == 2),
          _TabButton(label: '[4] Settings', isActive: path.activeIndex == 3),
          Expanded(child: SizedBox()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Text('[q] Quit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessComponent {
  const _TabButton({required this.label, required this.isActive});
  final String label;
  final bool isActive;

  @override
  Component build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : null,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessComponent {
  const _StatusBar({required this.currentUri});

  final Uri currentUri;

  @override
  Component build(BuildContext context) {
    final routeName = currentUri;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.brightBlack),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 1),
        child: Row(
          children: [
            Text(' $routeName ', style: TextStyle(color: Colors.white)),
            Expanded(child: SizedBox()),
            Text('q: quit', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// [1] Dashboard Tab — system overview with live counters & progress bars
// ============================================================================

class DashboardTab extends AppRoute {
  @override
  Type get layout => DashboardLayout;
  @override
  Uri toUri() => Uri.parse('/dashboard');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return _DashboardView(coordinator: coordinator);
  }
}

class _DashboardView extends StatefulComponent {
  const _DashboardView({required this.coordinator});
  final AppCoordinator coordinator;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  int _requestCount = 1247;
  double _cpuUsage = 0.42;
  double _memUsage = 0.68;
  final double _diskUsage = 0.35;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 2), (_) {
      setState(() {
        _requestCount += 3;
        _cpuUsage = (_cpuUsage + 0.02) % 1.0;
        _memUsage = ((_memUsage + 0.01) % 0.5) + 0.5;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _selectedService = 0;
  static const _services = [
    ('api-gateway', 'Running', Colors.green, 0.12),
    ('auth-service', 'Running', Colors.green, 0.34),
    ('worker-pool', 'Warning', Colors.yellow, 0.82),
    ('db-primary', 'Running', Colors.green, 0.45),
    ('cache-layer', 'Running', Colors.green, 0.21),
    ('cdn-edge', 'Degraded', Colors.red, 0.91),
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (_handleGlobalKeys(event, component.coordinator)) return true;
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(
            () => _selectedService = (_selectedService + 1).clamp(
              0,
              _services.length - 1,
            ),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(
            () => _selectedService = (_selectedService - 1).clamp(
              0,
              _services.length - 1,
            ),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.enter) {
          final svc = _services[_selectedService];
          component.coordinator.push(ServiceDetailRoute(serviceId: svc.$1));
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '◈ System Overview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1),
            // Stats row
            Row(
              children: [
                _StatCard(label: 'Requests', value: '$_requestCount'),
                SizedBox(width: 2),
                _StatCard(label: 'Uptime', value: '14d 7h'),
                SizedBox(width: 2),
                _StatCard(label: 'Services', value: '12/12'),
                SizedBox(width: 2),
                _StatCard(label: 'Errors', value: '3'),
              ],
            ),
            SizedBox(height: 1),
            // Progress bars
            Text(
              'Resource Usage:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1),
            Row(
              children: [
                SizedBox(width: 6, child: Text('CPU  ')),
                Expanded(
                  child: ProgressBar(
                    value: _cpuUsage,
                    showPercentage: true,
                    valueColor: _cpuUsage > 0.8 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 6, child: Text('MEM  ')),
                Expanded(
                  child: ProgressBar(
                    value: _memUsage,
                    showPercentage: true,
                    valueColor: _memUsage > 0.8 ? Colors.red : Colors.yellow,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 6, child: Text('DISK ')),
                Expanded(
                  child: ProgressBar(
                    value: _diskUsage,
                    showPercentage: true,
                    valueColor: Colors.cyan,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1),
            Divider(),
            SizedBox(height: 1),
            // Services list — selectable, ENTER to drill down
            Text(
              'Services (ENTER to inspect):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            for (var i = 0; i < _services.length; i++)
              _ServiceRow(
                name: _services[i].$1,
                status: _services[i].$2,
                statusColor: _services[i].$3,
                load: _services[i].$4,
                isSelected: i == _selectedService,
              ),
            Expanded(child: SizedBox()),
            Divider(),
            Text(
              '↑↓ select service  ENTER inspect  1-4 tabs  q quit',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessComponent {
  const _ServiceRow({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.load,
    required this.isSelected,
  });
  final String name;
  final String status;
  final Color statusColor;
  final double load;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    final prefix = isSelected ? '▸ ' : '  ';
    final nameStr = name.padRight(16);
    final statusStr = status.padRight(10);
    return Text(
      '$prefix$nameStr $statusStr ${(load * 100).toStringAsFixed(0).padLeft(3)}%',
      style: TextStyle(
        color: isSelected ? Colors.white : statusColor,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}

class _StatCard extends StatelessComponent {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Component build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(border: BoxBorder.all()),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            Text(label, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// [2] Tasks Tab — interactive task list with add/complete/delete
// ============================================================================

class TasksTab extends AppRoute {
  @override
  Type get layout => DashboardLayout;
  @override
  Uri toUri() => Uri.parse('/tasks');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return _TasksView(coordinator: coordinator);
  }
}

class _TaskItem {
  _TaskItem(this.title, {this.done = false});
  final String title;
  bool done;
}

class _TasksView extends StatefulComponent {
  const _TasksView({required this.coordinator});
  final AppCoordinator coordinator;

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView> {
  final _tasks = <_TaskItem>[
    _TaskItem('Set up CI/CD pipeline'),
    _TaskItem('Configure monitoring alerts'),
    _TaskItem('Update SSL certificates', done: true),
    _TaskItem('Migrate database to v3'),
    _TaskItem('Review security audit findings'),
    _TaskItem('Deploy canary release'),
  ];
  int _selectedIndex = 0;
  bool _adding = false;
  final _addController = TextEditingController();

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: !_adding,
      onKeyEvent: (event) {
        if (_handleGlobalKeys(event, component.coordinator)) return true;
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(
            () => _selectedIndex = (_selectedIndex + 1).clamp(
              0,
              _tasks.length - 1,
            ),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(
            () => _selectedIndex = (_selectedIndex - 1).clamp(
              0,
              _tasks.length - 1,
            ),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.space) {
          setState(
            () => _tasks[_selectedIndex].done = !_tasks[_selectedIndex].done,
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.keyD) {
          setState(() {
            _tasks.removeAt(_selectedIndex);
            _selectedIndex = _selectedIndex.clamp(0, _tasks.length - 1);
          });
          return true;
        }
        if (event.logicalKey == LogicalKey.keyA) {
          setState(() => _adding = true);
          return true;
        }
        if (event.logicalKey == LogicalKey.enter) {
          component.coordinator.push(
            TaskDetailRoute(taskId: '$_selectedIndex'),
          );
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '◈ Tasks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Expanded(child: SizedBox()),
                Text(
                  '${_tasks.where((t) => t.done).length}/${_tasks.length} done',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 1),
            // Task list
            for (var i = 0; i < _tasks.length; i++)
              _TaskRow(task: _tasks[i], isSelected: i == _selectedIndex),
            SizedBox(height: 1),
            // Add new task
            if (_adding)
              Row(
                children: [
                  Text('  + ', style: TextStyle(color: Colors.green)),
                  Expanded(
                    child: TextField(
                      controller: _addController,
                      focused: true,
                      placeholder: 'New task name...',
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _tasks.add(_TaskItem(value));
                            _adding = false;
                            _addController.clear();
                          });
                        }
                      },
                      onKeyEvent: (event) {
                        if (event.logicalKey == LogicalKey.escape) {
                          setState(() {
                            _adding = false;
                            _addController.clear();
                          });
                          return true;
                        }
                        return false;
                      },
                    ),
                  ),
                ],
              ),
            // Shortcuts help
            Expanded(child: SizedBox()),
            Divider(),
            Text(
              '↑↓ select  SPACE toggle  a add  d delete  ENTER detail',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessComponent {
  const _TaskRow({required this.task, required this.isSelected});
  final _TaskItem task;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    final check = task.done ? '✓' : '○';
    final prefix = isSelected ? '▸ ' : '  ';
    return Text(
      '$prefix$check ${task.title}',
      style: TextStyle(
        color: task.done
            ? Colors.grey
            : isSelected
            ? Colors.white
            : Colors.brightWhite,
        fontWeight: isSelected ? FontWeight.bold : null,
        decoration: task.done ? TextDecoration.lineThrough : null,
      ),
    );
  }
}

// ============================================================================
// Task Detail Route — pushed on top of layout
// ============================================================================

class TaskDetailRoute extends AppRoute {
  TaskDetailRoute({required this.taskId});
  final String taskId;

  @override
  Uri toUri() => Uri.parse('/tasks/$taskId');
  @override
  List<Object?> get props => [taskId];

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        if (event.logicalKey == LogicalKey.keyC) {
          coordinator.push(TaskCommentsRoute(taskId: taskId));
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: ' Task #$taskId '),
        ),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Detail #$taskId',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              SizedBox(height: 1),
              Text('Status:     In Progress'),
              Text('Priority:   High'),
              Text('Assigned:   dev-team'),
              Text('Created:    2026-02-20'),
              SizedBox(height: 1),
              Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('This is a sample task for the DevOps Dashboard demo.'),
              Text('It showcases nested route pushing with parameters.'),
              SizedBox(height: 1),
              ProgressBar(
                value: 0.6,
                showPercentage: true,
                label: 'Progress',
                valueColor: Colors.green,
              ),
              SizedBox(height: 1),
              Text('Subtasks:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('  ✓ Create database migration'),
              Text('  ✓ Update API endpoints'),
              Text('  ○ Write integration tests'),
              Text('  ○ Deploy to staging'),
              Expanded(child: SizedBox()),
              Divider(),
              Text(
                '[c] View Comments (3)    [ESC] Back',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Task → Comments → Reply (3-level nested push stack)
// ============================================================================

class TaskCommentsRoute extends AppRoute {
  TaskCommentsRoute({required this.taskId});
  final String taskId;

  @override
  Uri toUri() => Uri.parse('/tasks/$taskId/comments');
  @override
  List<Object?> get props => [taskId];

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return _TaskCommentsView(coordinator: coordinator, taskId: taskId);
  }
}

class _TaskCommentsView extends StatefulComponent {
  const _TaskCommentsView({required this.coordinator, required this.taskId});
  final AppCoordinator coordinator;
  final String taskId;

  @override
  State<_TaskCommentsView> createState() => _TaskCommentsViewState();
}

class _TaskCommentsViewState extends State<_TaskCommentsView> {
  int _selected = 0;
  static const _comments = [
    ('alice', 'Migration script looks good, ready for review.'),
    ('bob', 'Found an edge case with nullable fields — see PR #247.'),
    ('carol', 'Staging deploy passed all smoke tests. LGTM!'),
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          component.coordinator.pop();
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(
            () => _selected = (_selected + 1).clamp(0, _comments.length - 1),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(
            () => _selected = (_selected - 1).clamp(0, _comments.length - 1),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.enter) {
          component.coordinator.push(
            CommentReplyRoute(
              taskId: component.taskId,
              commentId: '$_selected',
            ),
          );
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: ' Comments — Task #${component.taskId} '),
        ),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments (${_comments.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              SizedBox(height: 1),
              for (var i = 0; i < _comments.length; i++) ...[
                Text(
                  '${i == _selected ? "▸" : " "} @${_comments[i].$1}:',
                  style: TextStyle(
                    fontWeight: i == _selected ? FontWeight.bold : null,
                    color: i == _selected ? Colors.green : Colors.cyan,
                  ),
                ),
                Text(
                  '  ${_comments[i].$2}',
                  style: TextStyle(
                    color: i == _selected ? Colors.white : Colors.grey,
                  ),
                ),
                SizedBox(height: 1),
              ],
              Expanded(child: SizedBox()),
              Divider(),
              Text(
                'Stack: Tasks → Detail #${component.taskId} → Comments',
                style: TextStyle(color: Colors.brightBlack),
              ),
              Text(
                '↑↓ select  ENTER reply  ESC back to task',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CommentReplyRoute extends AppRoute {
  CommentReplyRoute({required this.taskId, required this.commentId});
  final String taskId;
  final String commentId;

  @override
  Uri toUri() => Uri.parse('/tasks/$taskId/comments/$commentId');
  @override
  List<Object?> get props => [taskId, commentId];

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return _CommentReplyView(
      coordinator: coordinator,
      taskId: taskId,
      commentId: commentId,
    );
  }
}

class _CommentReplyView extends StatefulComponent {
  const _CommentReplyView({
    required this.coordinator,
    required this.taskId,
    required this.commentId,
  });
  final AppCoordinator coordinator;
  final String taskId;
  final String commentId;

  @override
  State<_CommentReplyView> createState() => _CommentReplyViewState();
}

class _CommentReplyViewState extends State<_CommentReplyView> {
  bool _editing = false;
  final _controller = TextEditingController();

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: !_editing,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          component.coordinator.pop();
          return true;
        }
        if (event.logicalKey == LogicalKey.keyR) {
          setState(() => _editing = true);
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: ' Reply — Comment #${component.commentId} '),
        ),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reply to Comment #${component.commentId}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              SizedBox(height: 1),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder(left: BorderSide(color: Colors.grey)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 1),
                  child: Text(
                    'Original comment content here...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Your reply:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_editing)
                TextField(
                  controller: _controller,
                  focused: true,
                  placeholder: 'Type your reply...',
                  decoration: InputDecoration(border: BoxBorder.all()),
                  onSubmitted: (value) {
                    setState(() => _editing = false);
                  },
                  onKeyEvent: (event) {
                    if (event.logicalKey == LogicalKey.escape) {
                      setState(() => _editing = false);
                      return true;
                    }
                    return false;
                  },
                )
              else
                Text(
                  _controller.text.isEmpty
                      ? '(no reply yet)'
                      : '"${_controller.text}"',
                  style: TextStyle(
                    color: _controller.text.isEmpty
                        ? Colors.grey
                        : Colors.green,
                  ),
                ),
              Expanded(child: SizedBox()),
              Divider(),
              Text(
                'Stack: Tasks → Detail #${component.taskId} → Comments → Reply #${component.commentId}',
                style: TextStyle(color: Colors.brightBlack),
              ),
              Text(
                '[r] Write reply  [ESC] Back to comments',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Dashboard → Service → Logs → LogEntry (4-level nested push stack)
// ============================================================================

class ServiceDetailRoute extends AppRoute {
  ServiceDetailRoute({required this.serviceId});
  final String serviceId;

  @override
  Uri toUri() => Uri.parse('/services/$serviceId');
  @override
  List<Object?> get props => [serviceId];

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        if (event.logicalKey == LogicalKey.keyL) {
          coordinator.push(ServiceLogsRoute(serviceId: serviceId));
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: ' Service: $serviceId '),
        ),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceId,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 1),
              Text('Replicas:    3/3 running'),
              Text('Image:       $serviceId:v2.4.1'),
              Text('Port:        8080'),
              Text('Memory:      256MB / 512MB'),
              Text('Restarts:    0'),
              SizedBox(height: 1),
              Text(
                'Health Checks:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '  ✓ Liveness    OK    (2s ago)',
                style: TextStyle(color: Colors.green),
              ),
              Text(
                '  ✓ Readiness   OK    (5s ago)',
                style: TextStyle(color: Colors.green),
              ),
              Text(
                '  ✓ Startup     OK    (14d ago)',
                style: TextStyle(color: Colors.green),
              ),
              SizedBox(height: 1),
              ProgressBar(
                value: 0.50,
                showPercentage: true,
                label: 'Memory',
                valueColor: Colors.cyan,
              ),
              ProgressBar(
                value: 0.34,
                showPercentage: true,
                label: 'CPU',
                valueColor: Colors.green,
              ),
              Expanded(child: SizedBox()),
              Divider(),
              Text(
                'Stack: Dashboard → Service: $serviceId',
                style: TextStyle(color: Colors.brightBlack),
              ),
              Text(
                '[l] View Logs    [ESC] Back to Dashboard',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceLogsRoute extends AppRoute with RouteTransition {
  ServiceLogsRoute({required this.serviceId});
  final String serviceId;

  @override
  Uri toUri() => Uri.parse('/services/$serviceId/logs');
  @override
  List<Object?> get props => [serviceId];

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: _ServiceLogsView(coordinator: coordinator, serviceId: serviceId),
      ),
    );
  }

  @override
  Route<T> transition<T extends RouteUnique>(AppCoordinator coordinator) =>
      ModalRoute(
        builder: (context) => build(coordinator, context),
        settings: settings,
      );
}

class _ServiceLogsView extends StatefulComponent {
  const _ServiceLogsView({required this.coordinator, required this.serviceId});
  final AppCoordinator coordinator;
  final String serviceId;

  @override
  State<_ServiceLogsView> createState() => _ServiceLogsViewState();
}

class _ServiceLogsViewState extends State<_ServiceLogsView> {
  int _selected = 0;

  List<(String, String, String)> get _logs => [
    ('INFO', '23:24:01', '[${component.serviceId}] Started successfully'),
    ('INFO', '23:24:02', '[${component.serviceId}] Listening on :8080'),
    ('DEBUG', '23:25:00', '[${component.serviceId}] GC pause: 12ms'),
    ('WARN', '23:26:14', '[${component.serviceId}] Slow query: 450ms'),
    ('INFO', '23:27:00', '[${component.serviceId}] Request rate: 142/s'),
    ('ERROR', '23:28:30', '[${component.serviceId}] Connection pool exhausted'),
    (
      'INFO',
      '23:28:31',
      '[${component.serviceId}] Pool recovered (3 new connections)',
    ),
    ('DEBUG', '23:29:00', '[${component.serviceId}] Metrics exported'),
  ];

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          component.coordinator.pop();
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowDown) {
          setState(
            () => _selected = (_selected + 1).clamp(0, _logs.length - 1),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.arrowUp) {
          setState(
            () => _selected = (_selected - 1).clamp(0, _logs.length - 1),
          );
          return true;
        }
        if (event.logicalKey == LogicalKey.enter) {
          component.coordinator.push(
            LogEntryDetailRoute(
              serviceId: component.serviceId,
              logId: '$_selected',
            ),
          );
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: ' Logs: ${component.serviceId} '),
          color: Colors.black,
        ),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Logs (${_logs.length} entries)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 1),
              for (var i = 0; i < _logs.length; i++)
                Text(
                  '${i == _selected ? "▸" : " "} ${_logs[i].$1.padRight(5)} ${_logs[i].$2} ${_logs[i].$3}',
                  style: TextStyle(
                    fontWeight: i == _selected ? FontWeight.bold : null,
                    color: switch (_logs[i].$1) {
                      'ERROR' => Colors.red,
                      'WARN' => Colors.yellow,
                      'DEBUG' => Colors.grey,
                      _ => i == _selected ? Colors.white : Colors.green,
                    },
                  ),
                ),
              Expanded(child: SizedBox()),
              Divider(),
              Text(
                'Stack: Dashboard → Service: ${component.serviceId} → Logs',
                style: TextStyle(color: Colors.brightBlack),
              ),
              Text(
                '↑↓ select  ENTER inspect  ESC back to service',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LogEntryDetailRoute extends AppRoute {
  LogEntryDetailRoute({required this.serviceId, required this.logId});
  final String serviceId;
  final String logId;

  @override
  Uri toUri() => Uri.parse('/services/$serviceId/logs/$logId');
  @override
  List<Object?> get props => [serviceId, logId];

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape) {
          coordinator.pop();
          return true;
        }
        return false;
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BoxBorder.all(),
          title: BorderTitle(text: ' Log Entry #$logId '),
        ),
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Entry #$logId',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              SizedBox(height: 1),
              Text('Service:     $serviceId'),
              Text('Timestamp:   2026-02-22T23:28:30.142Z'),
              Text('Level:       ERROR'),
              Text('Thread:      worker-3'),
              Text('Request ID:  req-a7f3c2e1'),
              SizedBox(height: 1),
              Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              DecoratedBox(
                decoration: BoxDecoration(color: Colors.brightBlack),
                child: Padding(
                  padding: EdgeInsets.all(1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection pool exhausted after 30s timeout.',
                        style: TextStyle(color: Colors.red),
                      ),
                      Text(
                        'Active connections: 50/50',
                        style: TextStyle(color: Colors.yellow),
                      ),
                      Text(
                        'Waiting requests: 12',
                        style: TextStyle(color: Colors.yellow),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Stack Trace:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '  at ConnectionPool.acquire (pool.dart:142)',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '  at DatabaseClient.query (client.dart:87)',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '  at UserService.findById (user_service.dart:34)',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '  at AuthHandler.handle (auth.dart:56)',
                style: TextStyle(color: Colors.grey),
              ),
              Expanded(child: SizedBox()),
              Divider(),
              Text(
                'Stack: Dashboard → Service: $serviceId → Logs → Entry #$logId',
                style: TextStyle(color: Colors.brightBlack),
              ),
              Text('ESC back to logs', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// [3] Logs Tab — scrollable log viewer with level indicators
// ============================================================================

class LogsTab extends AppRoute {
  @override
  Type get layout => DashboardLayout;
  @override
  Uri toUri() => Uri.parse('/logs');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return _LogsView(coordinator: coordinator);
  }
}

class _LogEntry {
  const _LogEntry(this.level, this.time, this.message);
  final String level;
  final String time;
  final String message;
}

const _sampleLogs = [
  _LogEntry('INFO', '23:24:01', 'Server started on port 8080'),
  _LogEntry('INFO', '23:24:02', 'Connected to database cluster'),
  _LogEntry('INFO', '23:24:03', 'Cache warmed: 1247 entries loaded'),
  _LogEntry('DEBUG', '23:24:05', 'Health check endpoint registered'),
  _LogEntry('INFO', '23:24:10', 'Worker pool initialized (8 threads)'),
  _LogEntry('WARN', '23:25:14', 'High memory usage on worker-3 (82%)'),
  _LogEntry('INFO', '23:25:30', 'Deploy #482 started'),
  _LogEntry('INFO', '23:25:45', 'Rolling update: 1/4 pods updated'),
  _LogEntry('INFO', '23:26:01', 'Rolling update: 2/4 pods updated'),
  _LogEntry('INFO', '23:26:15', 'Rolling update: 3/4 pods updated'),
  _LogEntry('INFO', '23:26:30', 'Rolling update: 4/4 pods updated'),
  _LogEntry('INFO', '23:26:31', 'Deploy #482 completed successfully'),
  _LogEntry('DEBUG', '23:27:00', 'Garbage collection: freed 42MB'),
  _LogEntry('INFO', '23:28:00', 'Health check passed'),
  _LogEntry('ERROR', '23:29:12', 'Timeout on api-gateway after 30s'),
  _LogEntry('WARN', '23:29:13', 'Retrying api-gateway request (1/3)'),
  _LogEntry('INFO', '23:29:15', 'api-gateway request succeeded on retry'),
  _LogEntry('INFO', '23:30:00', 'Backup started: db-production'),
  _LogEntry('INFO', '23:32:45', 'Backup completed: 2.4GB written'),
  _LogEntry('DEBUG', '23:33:00', 'Metrics flushed to monitoring service'),
];

class _LogsView extends StatefulComponent {
  const _LogsView({required this.coordinator});
  final AppCoordinator coordinator;

  @override
  State<_LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<_LogsView> {
  String _filter = 'ALL';
  final _filters = ['ALL', 'INFO', 'WARN', 'ERROR', 'DEBUG'];
  int _filterIndex = 0;

  List<_LogEntry> get _filtered => _filter == 'ALL'
      ? _sampleLogs
      : _sampleLogs.where((l) => l.level == _filter).toList();

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (_handleGlobalKeys(event, component.coordinator)) return true;
        if (event.logicalKey == LogicalKey.tab) {
          setState(() {
            _filterIndex = (_filterIndex + 1) % _filters.length;
            _filter = _filters[_filterIndex];
          });
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '◈ Logs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 2),
                Text('Filter: ', style: TextStyle(color: Colors.grey)),
                for (final f in _filters) ...[
                  Text(
                    '[$f]',
                    style: TextStyle(
                      fontWeight: f == _filter ? FontWeight.bold : null,
                      color: f == _filter ? Colors.white : Colors.grey,
                    ),
                  ),
                  SizedBox(width: 1),
                ],
                Expanded(child: SizedBox()),
                Text(
                  '${_filtered.length} entries',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 1),
            // Log header
            Text(
              'LEVEL  TIME      MESSAGE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                decoration: TextDecoration.underline,
              ),
            ),
            // Log entries
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final log in _filtered) _LogRow(entry: log)],
                ),
              ),
            ),
            Divider(),
            Text('TAB cycle filter', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessComponent {
  const _LogRow({required this.entry});
  final _LogEntry entry;

  @override
  Component build(BuildContext context) {
    final levelColor = switch (entry.level) {
      'ERROR' => Colors.red,
      'WARN' => Colors.yellow,
      'DEBUG' => Colors.grey,
      _ => Colors.green,
    };
    final levelPad = entry.level.padRight(5);
    return Text(
      '$levelPad  ${entry.time}  ${entry.message}',
      style: TextStyle(color: levelColor),
    );
  }
}

// ============================================================================
// [4] Settings Tab — form-like settings with text fields
// ============================================================================

class SettingsTab extends AppRoute {
  @override
  Type get layout => DashboardLayout;
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Component build(AppCoordinator coordinator, BuildContext context) {
    return _SettingsView(coordinator: coordinator);
  }
}

class _SettingsView extends StatefulComponent {
  const _SettingsView({required this.coordinator});
  final AppCoordinator coordinator;

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  int _focusedField = -1;
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '8080');
  final _nameController = TextEditingController(text: 'devops-dashboard');
  bool _darkMode = true;
  bool _notifications = true;
  String _logLevel = 'INFO';

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: _focusedField < 0,
      onKeyEvent: (event) {
        if (_handleGlobalKeys(event, component.coordinator)) return true;
        // F1/F2/F3 to focus text fields (no conflict with tab switching)
        if (event.logicalKey == LogicalKey.f1) {
          setState(() => _focusedField = 0);
          return true;
        }
        if (event.logicalKey == LogicalKey.f2) {
          setState(() => _focusedField = 1);
          return true;
        }
        if (event.logicalKey == LogicalKey.f3) {
          setState(() => _focusedField = 2);
          return true;
        }
        if (event.logicalKey == LogicalKey.keyD) {
          setState(() => _darkMode = !_darkMode);
          return true;
        }
        if (event.logicalKey == LogicalKey.keyN) {
          setState(() => _notifications = !_notifications);
          return true;
        }
        if (event.logicalKey == LogicalKey.keyL) {
          final levels = ['DEBUG', 'INFO', 'WARN', 'ERROR'];
          final idx = levels.indexOf(_logLevel);
          setState(() => _logLevel = levels[(idx + 1) % levels.length]);
          return true;
        }
        return false;
      },
      child: Padding(
        padding: EdgeInsets.all(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '◈ Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 1),
            // Text field settings
            Text(
              'Server Configuration:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1),
            _SettingsTextField(
              label: '[F1] Host',
              controller: _hostController,
              focused: _focusedField == 0,
              onDone: () => setState(() => _focusedField = -1),
            ),
            _SettingsTextField(
              label: '[F2] Port',
              controller: _portController,
              focused: _focusedField == 1,
              onDone: () => setState(() => _focusedField = -1),
            ),
            _SettingsTextField(
              label: '[F3] Name',
              controller: _nameController,
              focused: _focusedField == 2,
              onDone: () => setState(() => _focusedField = -1),
            ),
            SizedBox(height: 1),
            Divider(),
            SizedBox(height: 1),
            // Toggle settings
            Text('Preferences:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 1),
            Text(
              '  [d] Dark Mode:      ${_darkMode ? "●" : "○"} ${_darkMode ? "ON" : "OFF"}',
              style: TextStyle(color: _darkMode ? Colors.green : Colors.grey),
            ),
            Text(
              '  [n] Notifications:  ${_notifications ? "●" : "○"} ${_notifications ? "ON" : "OFF"}',
              style: TextStyle(
                color: _notifications ? Colors.green : Colors.grey,
              ),
            ),
            Text(
              '  [l] Log Level:      $_logLevel',
              style: TextStyle(color: Colors.cyan),
            ),
            Expanded(child: SizedBox()),
            Divider(),
            Text(
              'F1-F3 edit fields  d/n toggle  l cycle log level  ESC unfocus',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTextField extends StatelessComponent {
  const _SettingsTextField({
    required this.label,
    required this.controller,
    required this.focused,
    required this.onDone,
  });

  final String label;
  final TextEditingController controller;
  final bool focused;
  final VoidCallback onDone;

  @override
  Component build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 12,
          child: Text('  $label: ', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focused: focused,
            placeholder: '...',
            decoration: InputDecoration(border: BoxBorder.all()),
            onSubmitted: (_) => onDone(),
            onKeyEvent: (event) {
              if (event.logicalKey == LogicalKey.escape) {
                onDone();
                return true;
              }
              return false;
            },
          ),
        ),
        SizedBox(width: 1),
      ],
    );
  }
}

// ============================================================================
// Global Key Handler — shared tab switching & quit
// ============================================================================

bool _handleGlobalKeys(KeyboardEvent event, AppCoordinator coordinator) {
  final path = coordinator.tabPath;
  if (event.logicalKey == LogicalKey.digit1 && path.activeIndex != 0) {
    path.goToIndexed(0);
    return true;
  }
  if (event.logicalKey == LogicalKey.digit2 && path.activeIndex != 1) {
    path.goToIndexed(1);
    return true;
  }
  if (event.logicalKey == LogicalKey.digit3 && path.activeIndex != 2) {
    path.goToIndexed(2);
    return true;
  }
  if (event.logicalKey == LogicalKey.digit4 && path.activeIndex != 3) {
    path.goToIndexed(3);
    return true;
  }
  if (event.logicalKey == LogicalKey.keyQ) {
    shutdownApp();
    return true;
  }
  return false;
}
