import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/debug_theme.dart';
import 'navigation_flow.dart';

/// Collapsible Observed replay scrubber: slider plus optional event list.
class ObservedReplayTimeline extends StatefulWidget {
  const ObservedReplayTimeline({
    super.key,
    required this.transitions,
    required this.index,
    required this.listExpanded,
    required this.onSeek,
    required this.onToggleList,
  });

  final List<NavigationFlowTransition<Object>> transitions;
  final int index;
  final bool listExpanded;
  final ValueChanged<int> onSeek;
  final VoidCallback onToggleList;

  @override
  State<ObservedReplayTimeline> createState() => _ObservedReplayTimelineState();
}

class _ObservedReplayTimelineState extends State<ObservedReplayTimeline> {
  final _rowKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCurrentVisible();
    });
  }

  @override
  void didUpdateWidget(ObservedReplayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index ||
        widget.listExpanded != oldWidget.listExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureCurrentVisible();
      });
    }
  }

  void _ensureCurrentVisible() {
    if (!mounted || !widget.listExpanded) return;
    final index = widget.index;
    if (index < 0) return;
    final rowContext = _rowKeys[index]?.currentContext;
    if (rowContext == null) return;
    Scrollable.ensureVisible(
      rowContext,
      alignment: 0.35,
      duration: Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.transitions.length;
    return ColoredBox(
      color: DebugTheme.backgroundDark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DebugTheme.borderDark)),
        ),
        child: Column(
          children: [
            _TimelineSlider(
              length: length,
              index: widget.index,
              listExpanded: widget.listExpanded,
              onSeek: widget.onSeek,
              onToggleList: widget.onToggleList,
            ),
            if (widget.listExpanded)
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: length,
                  itemBuilder: (context, i) {
                    return _TimelineEventRow(
                      key: ValueKey('observed-replay-event-$i'),
                      rowKey: _rowKeys.putIfAbsent(i, GlobalKey.new),
                      transition: widget.transitions[i],
                      selected: widget.index == i,
                      onTap: () => widget.onSeek(i),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSlider extends StatelessWidget {
  const _TimelineSlider({
    required this.length,
    required this.index,
    required this.listExpanded,
    required this.onSeek,
    required this.onToggleList,
  });

  final int length;
  final int index;
  final bool listExpanded;
  final ValueChanged<int> onSeek;
  final VoidCallback onToggleList;

  @override
  Widget build(BuildContext context) {
    final max = length <= 1 ? 0.0 : (length - 1).toDouble();
    final value = index < 0 ? 0.0 : index.toDouble().clamp(0.0, max);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 2,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Color(0xFF60A5FA),
                  inactiveTrackColor: DebugTheme.border,
                  thumbColor: Color(0xFF60A5FA),
                  overlayColor: Color(0x3360A5FA),
                ),
                child: Slider(
                  key: const ValueKey('observed-replay-slider'),
                  min: 0,
                  max: max,
                  divisions: length > 1 ? length - 1 : null,
                  value: value,
                  label: length == 0 ? '0' : '${value.round() + 1} / $length',
                  semanticFormatterCallback: (v) =>
                      'Event ${v.round() + 1} of $length',
                  onChanged: length == 0
                      ? null
                      : (next) => onSeek(next.round()),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleList,
            child: SizedBox(
              width: 28,
              height: 44,
              child: Icon(
                listExpanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_up,
                size: 12,
                color: DebugTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({
    super.key,
    required this.rowKey,
    required this.transition,
    required this.selected,
    required this.onTap,
  });

  final GlobalKey rowKey;
  final NavigationFlowTransition<Object> transition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final local = transition.occurredAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ColoredBox(
        key: rowKey,
        color: selected
            ? const Color(0xFF60A5FA).withValues(alpha: 0.16)
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DebugTheme.spacingMd,
            6,
            DebugTheme.spacingMd,
            6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$time  ${transition.displayLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? DebugTheme.textPrimary
                      : DebugTheme.textSecondary,
                  fontSize: DebugTheme.fontSizeSm,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${transition.previousUri} → ${transition.currentUri}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DebugTheme.textMuted,
                  fontSize: DebugTheme.fontSizeXs,
                  fontFamily: 'monospace',
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
