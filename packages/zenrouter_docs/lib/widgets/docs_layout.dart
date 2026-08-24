import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:zenrouter_docs/theme/app_theme.dart';
import 'package:zenrouter_docs/widgets/mardown_section.dart';

/// Provides a calm reading column and, on wide screens, a marginal TOC.
class DocsLayoutBuilder extends StatefulWidget {
  const DocsLayoutBuilder({super.key, required this.child});

  final Widget child;

  @override
  State<DocsLayoutBuilder> createState() => _DocsLayoutBuilderState();
}

class _DocsLayoutBuilderState extends State<DocsLayoutBuilder> {
  static const _tocBreakpoint = 1040.0;

  late final TocController _tocController;

  @override
  void initState() {
    super.initState();
    _tocController = TocController();
  }

  @override
  void dispose() {
    _tocController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DocsTocScope(
      controller: _tocController,
      child: AnimatedBuilder(
        animation: _tocController,
        child: widget.child,
        builder: (context, child) => LayoutBuilder(
          builder: (context, constraints) {
            final tocItems = _tocController.items;
            final showToc =
                constraints.maxWidth >= _tocBreakpoint && tocItems.isNotEmpty;
            return Stack(
              fit: StackFit.expand,
              children: [
                child!,
                if (showToc)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: _DocsTocSidebar(
                      controller: _tocController,
                      items: tocItems,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DocsTocSidebar extends StatelessWidget {
  const _DocsTocSidebar({required this.controller, required this.items});

  final TocController controller;
  final List<TocItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.paleBlue,
        border: Border(left: BorderSide(color: AppTheme.divider)),
      ),
      child: items.isEmpty
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 72, 18, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In this chapter',
                    style: AppTypography.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final item in items) ...[
                    _TocLink(
                      item: item,
                      active: controller.activeItem == item,
                      onPress: () => controller.scrollToItem(item),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
    );
  }
}

class _TocLink extends StatelessWidget {
  const _TocLink({
    required this.item,
    required this.active,
    required this.onPress,
  });

  final TocItem item;
  final bool active;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FTappable.static(
      semanticsLabel: 'Jump to ${item.title}',
      onPress: onPress,
      behavior: HitTestBehavior.opaque,
      builder: (context, states, child) => child!,
      child: Padding(
        padding: EdgeInsets.only(left: math.max((item.level - 1) * 8 - 8, 0)),
        child: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.sans(
            fontSize: 12,
            height: 1.35,
            fontWeight: active ? FontWeight.w400 : FontWeight.w400,
            color: active ? AppTheme.primary : AppTheme.mutedInk,
          ),
        ),
      ),
    );
  }
}

/// Supplies the route-scoped TOC controller to each chapter.
class DocsTocScope extends InheritedWidget {
  const DocsTocScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final TocController controller;

  static TocController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocsTocScope>()?.controller;

  @override
  bool updateShouldNotify(DocsTocScope oldWidget) =>
      controller != oldWidget.controller;
}
