import 'package:flutter/cupertino.dart';
import 'package:zenrouter/zenrouter.dart';

import '../coordinator_debug.dart';
import '../widgets/buttons.dart';
import '../widgets/debug_theme.dart';

class DebugRoutesListView<T extends RouteUnique> extends StatelessWidget {
  const DebugRoutesListView({super.key, required this.coordinator});

  final CoordinatorDebug<T> coordinator;

  @override
  Widget build(BuildContext context) {
    if (coordinator.debugRoutes.isEmpty) {
      return const Center(
        child: Text(
          'No debug routes defined.\nOverride debugRoutes in your coordinator.',
          style: TextStyle(
            color: DebugTheme.textDisabled,
            fontSize: DebugTheme.fontSizeMd,
            decoration: TextDecoration.none,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DebugTheme.spacingXs),
      itemCount: coordinator.debugRoutes.length,
      itemBuilder: (context, index) {
        final route = coordinator.debugRoutes[index];
        return DebugRouteItem<T>(route: route, coordinator: coordinator);
      },
    );
  }
}

class DebugRouteItem<T extends RouteUnique> extends StatelessWidget {
  const DebugRouteItem({
    super.key,
    required this.route,
    required this.coordinator,
  });

  final T route;
  final CoordinatorDebug<T> coordinator;

  String get _status {
    try {
      return route.toUri().toString();
    } catch (_) {
      return 'needs implementation [toUri]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DebugTheme.spacingMd,
        vertical: DebugTheme.spacingSm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: route.toString(),
                style: const TextStyle(
                  color: DebugTheme.textPrimary,
                  fontSize: DebugTheme.fontSizeMd,
                  decoration: TextDecoration.none,
                ),
                children: [
                  TextSpan(
                    text: ' $_status',
                    style: TextStyle(
                      color: switch (_status) {
                        'needs implementation [toUri]' => const Color(
                          0xFFE85600,
                        ),
                        _ => DebugTheme.textSecondary,
                      },
                      fontSize: DebugTheme.fontSizeMd,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DebugTheme.spacingXs),
          SmallIconButton(
            icon: CupertinoIcons.add,
            onTap: () {
              coordinator.push(route);
            },
          ),
          const SizedBox(width: DebugTheme.spacingXs),
          SmallIconButton(
            icon: CupertinoIcons.arrow_swap,
            onTap: () {
              coordinator.replace(route);
            },
          ),
          const SizedBox(width: DebugTheme.spacingXs),
          SmallIconButton(
            icon: CupertinoIcons.link,
            onTap: () {
              coordinator.recover(route);
            },
          ),
        ],
      ),
    );
  }
}
