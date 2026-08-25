import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/debug_theme.dart';
import 'navigation_flow.dart';

/// Fixed row height so [ScrollController] can jump to an unbuilt index.
const _observedReplayEventRowExtent = 44.0;

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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  @override
  void didUpdateWidget(ObservedReplayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index ||
        widget.listExpanded != oldWidget.listExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrent();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!mounted || !widget.listExpanded) return;
    final index = widget.index;
    if (index < 0 || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target =
        index * _observedReplayEventRowExtent -
        position.viewportDimension * 0.35;
    _scrollController.jumpTo(target.clamp(0.0, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final length = widget.transitions.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
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
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemExtent: _observedReplayEventRowExtent,
                  itemCount: length,
                  itemBuilder: (context, i) {
                    return _TimelineEventRow(
                      key: ValueKey('observed-replay-event-$i'),
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
      height: 32,
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
              height: 32,
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
    required this.transition,
    required this.selected,
    required this.onTap,
  });

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
