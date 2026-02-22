import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_core/zenrouter_core.dart';
import 'package:zenrouter_nocterm/src/coordinator/base.dart';
import 'package:zenrouter_nocterm/src/internal/reactive.dart';

/// A mutable stack path for standard navigation.
///
/// Supports pushing and popping routes. Used for the main navigation stack
/// and modal flows.
///
/// ## Role in Navigation Flow
///
/// [NavigationPath] is the primary path type for imperative navigation:
/// 1. Stores routes in a mutable list (stack)
/// 2. Supports push/pop/remove operations
/// 3. Renders content via [NavigationStack] widget
/// 4. Implements [RestorablePath] for state restoration
///
/// When navigating:
/// - [push] adds a new route to the top
/// - [pop] removes the top route
/// - [navigate] handles browser back/forward
class NavigationPath<T extends RouteTarget> extends StackPath<T>
    with StackMutatable<T>
    implements ChangeNotifier {
  NavigationPath._([
    String? debugLabel,
    List<T>? stack,
    Coordinator? coordinator,
  ]) : super(stack ?? [], debugLabel: debugLabel, coordinator: coordinator);

  /// Creates a [NavigationPath] with an optional initial stack.
  ///
  /// This is the standard way to create a mutable navigation stack.
  factory NavigationPath.create({
    String? label,
    List<T>? stack,
    Coordinator? coordinator,
  }) => NavigationPath._(label, stack ?? [], coordinator);

  /// Creates a [NavigationPath] associated with a [Coordinator].
  ///
  /// This constructor binds the path to a specific coordinator, allowing it to
  /// interact with the coordinator for navigation actions.
  factory NavigationPath.createWith({
    required CoordinatorCore coordinator,
    required String label,
    List<T>? stack,
  }) => NavigationPath._(label, stack ?? [], coordinator as Coordinator);

  /// The key used to identify this type in [defineLayoutBuilder].
  static const key = PathKey('NavigationPath');

  /// NavigationPath key. This is used to identify this type in [defineLayoutBuilder].
  @override
  PathKey get pathKey => key;

  @override
  void reset() => clear();

  @override
  T? get activeRoute => stack.lastOrNull;

  @override
  Future<void> activateRoute(T route) async {
    reset();
    push(route);
  }

  final _proxy = ReactiveChangeNotifier();

  @override
  void dispose() {
    _proxy.dispose();
    super.dispose();
  }

  @override
  void addListener(VoidCallback listener) => _proxy.addListener(listener);

  @override
  void notifyListeners() => _proxy.notifyListeners();

  @override
  void removeListener(VoidCallback listener) => _proxy.removeListener(listener);
}
