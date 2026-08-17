import 'package:flutter/cupertino.dart';

import '../widgets/debug_theme.dart';

/// Copy shown while a live-export replay holds the recording lease.
const observedReplayLiveExportBanner =
    'Recording paused for replay. Navigations will not be added to this session.';

/// Copy shown while an imported document is on the canvas.
const observedReplayImportBanner = 'Replaying imported session.';

/// Copy shown when import rematch produced no transitions.
const observedReplayUnmatchedBanner =
    'Imported session did not match this manifest.';

/// Copy shown when the playhead preview is an id fallback, not this revision.
const observedReplayStalePreviewCaption = 'Preview from a later visit';

/// Copy shown when pasted JSON cannot be decoded.
const observedReplayImportFailedBanner = 'Could not import session.';

/// Copy appended while Drive is armed.
const observedReplayDriveBanner =
    'Driving the live app via navigate. Redirects may re-run.';

/// Floating Observed playback dock: transport, speed, export/import.
class ObservedReplayTransport extends StatelessWidget {
  const ObservedReplayTransport({
    super.key,
    required this.isLive,
    required this.isPlaying,
    required this.enabled,
    required this.speed,
    required this.onJumpStart,
    required this.onStepBack,
    required this.onPlayPause,
    required this.onStepForward,
    required this.onJumpEnd,
    required this.onExit,
    required this.onCycleSpeed,
    required this.onToggleTimeline,
    required this.onExport,
    required this.onImport,
    this.onToggleDrive,
    this.driveArmed = false,
    this.timelineOpen = false,
  });

  final bool isLive;
  final bool isPlaying;
  final bool enabled;
  final bool timelineOpen;
  final double speed;
  final VoidCallback onJumpStart;
  final VoidCallback onStepBack;
  final VoidCallback onPlayPause;
  final VoidCallback onStepForward;
  final VoidCallback onJumpEnd;
  final VoidCallback onExit;
  final VoidCallback onCycleSpeed;
  final VoidCallback onToggleTimeline;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback? onToggleDrive;
  final bool driveArmed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF2141416),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          height: 40,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-start'),
                  semanticsLabel: 'Jump to first replay event',
                  icon: CupertinoIcons.backward_end_fill,
                  onTap: enabled ? onJumpStart : null,
                ),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-prev'),
                  semanticsLabel: 'Step to previous replay event',
                  icon: CupertinoIcons.backward_fill,
                  onTap: enabled ? onStepBack : null,
                ),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-play'),
                  semanticsLabel: isPlaying ? 'Pause replay' : 'Play replay',
                  icon: isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  emphasized: true,
                  color: enabled
                      ? const Color(0xFF0B1220)
                      : DebugTheme.textDisabled,
                  onTap: enabled ? onPlayPause : null,
                ),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-next'),
                  semanticsLabel: 'Step to next replay event',
                  icon: CupertinoIcons.forward_fill,
                  onTap: enabled ? onStepForward : null,
                ),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-end'),
                  semanticsLabel: 'Jump to last replay event',
                  icon: CupertinoIcons.forward_end_fill,
                  onTap: enabled ? onJumpEnd : null,
                ),
                const _DockDivider(),
                _ReplaySpeedButton(speed: speed, onTap: onCycleSpeed),
                if (onToggleDrive != null)
                  _ReplayTransportButton(
                    key: const ValueKey('observed-replay-drive'),
                    semanticsLabel: driveArmed
                        ? 'Stop driving the live app'
                        : 'Drive the live app to the playhead',
                    icon: CupertinoIcons.car,
                    active: driveArmed,
                    color: !enabled
                        ? DebugTheme.textDisabled
                        : driveArmed
                        ? const Color(0xFFFBBF24)
                        : DebugTheme.textSecondary,
                    onTap: enabled ? onToggleDrive : null,
                  ),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-timeline'),
                  semanticsLabel: timelineOpen
                      ? 'Hide replay event list'
                      : 'Show replay event list',
                  icon: CupertinoIcons.list_bullet,
                  active: timelineOpen,
                  color: !enabled
                      ? DebugTheme.textDisabled
                      : timelineOpen
                      ? const Color(0xFF60A5FA)
                      : DebugTheme.textSecondary,
                  onTap: enabled ? onToggleTimeline : null,
                ),
                const _DockDivider(),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-export'),
                  semanticsLabel: 'Export observed session JSON',
                  icon: CupertinoIcons.square_arrow_up,
                  onTap: onExport,
                ),
                _ReplayTransportButton(
                  key: const ValueKey('observed-replay-import'),
                  semanticsLabel: 'Import observed session JSON',
                  icon: CupertinoIcons.square_arrow_down,
                  onTap: onImport,
                ),
                if (!isLive) ...[
                  const _DockDivider(),
                  _ReplayTransportButton(
                    key: const ValueKey('observed-replay-exit'),
                    semanticsLabel: 'Exit replay',
                    icon: CupertinoIcons.xmark,
                    onTap: onExit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner or Drive confirm chip that overlays the canvas above the dock.
class ObservedReplayDockMessage extends StatelessWidget {
  const ObservedReplayDockMessage({
    super.key,
    this.banner,
    this.confirmPending = false,
    this.onConfirm,
    this.onCancel,
  });

  final String? banner;
  final bool confirmPending;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF21A1610),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x663F2F12)),
      ),
      child: confirmPending
          ? _DriveConfirmBar(onConfirm: onConfirm, onCancel: onCancel)
          : _DockBanner(banner: banner ?? ''),
    );
  }
}

/// Paste dialog that returns session JSON, or null if cancelled.
Future<String?> showObservedSessionImportDialog(BuildContext context) async {
  final controller = TextEditingController();
  try {
    final result = await showCupertinoDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Import session'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CupertinoTextField(
              key: const ValueKey('observed-replay-import-field'),
              controller: controller,
              maxLines: 6,
              minLines: 4,
              placeholder: 'Paste session JSON',
              style: const TextStyle(
                fontSize: DebugTheme.fontSizeMd,
                fontFamily: 'monospace',
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              key: const ValueKey('observed-replay-import-confirm'),
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
    final source = result?.trim();
    if (source == null || source.isEmpty) return null;
    return source;
  } finally {
    controller.dispose();
  }
}

class _DockBanner extends StatelessWidget {
  const _DockBanner({required this.banner});

  final String banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          banner,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE8C872),
            fontSize: DebugTheme.fontSizeSm,
            height: 1.3,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _DriveConfirmBar extends StatelessWidget {
  const _DriveConfirmBar({this.onConfirm, this.onCancel});

  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Drive the live app via navigate? Redirects may re-run.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFE8C872),
                fontSize: DebugTheme.fontSizeSm,
                height: 1.3,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _DockTextAction(
            key: const ValueKey('observed-replay-drive-cancel'),
            label: 'Cancel',
            color: DebugTheme.textSecondary,
            onTap: onCancel,
          ),
          _DockTextAction(
            key: const ValueKey('observed-replay-drive-confirm'),
            label: 'Drive',
            color: const Color(0xFFFBBF24),
            emphasized: true,
            onTap: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _DockTextAction extends StatelessWidget {
  const _DockTextAction({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: emphasized
                ? const Color(0x26FBBF24)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(DebugTheme.radiusFull),
            border: emphasized
                ? Border.all(color: const Color(0x66FBBF24))
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: emphasized ? 8 : 6,
              vertical: 4,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: DebugTheme.fontSizeSm,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockDivider extends StatelessWidget {
  const _DockDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 1,
        height: 14,
        child: ColoredBox(color: Color(0xFF2A2A2E)),
      ),
    );
  }
}

class _ReplayTransportButton extends StatefulWidget {
  const _ReplayTransportButton({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.color,
    this.emphasized = false,
    this.active = false,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final bool emphasized;
  final bool active;

  @override
  State<_ReplayTransportButton> createState() => _ReplayTransportButtonState();
}

class _ReplayTransportButtonState extends State<_ReplayTransportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final emphasized = widget.emphasized && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticsLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: emphasized ? 28 : 26,
              height: emphasized ? 28 : 26,
              decoration: BoxDecoration(
                color: emphasized
                    ? const Color(0xFF60A5FA)
                    : widget.active
                    ? const Color(0x1A60A5FA)
                    : _hovered && enabled
                    ? const Color(0xFF222226)
                    : const Color(0x00000000),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: emphasized ? 13 : 13.5,
                color: enabled
                    ? (widget.color ?? DebugTheme.textSecondary)
                    : DebugTheme.textDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplaySpeedButton extends StatefulWidget {
  const _ReplaySpeedButton({required this.speed, required this.onTap});

  final double speed;
  final VoidCallback onTap;

  @override
  State<_ReplaySpeedButton> createState() => _ReplaySpeedButtonState();
}

class _ReplaySpeedButtonState extends State<_ReplaySpeedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.speed == widget.speed.roundToDouble()
        ? '${widget.speed.toInt()}×'
        : '${widget.speed}×';
    return Semantics(
      button: true,
      label: 'Replay speed $label',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: const ValueKey('observed-replay-speed'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _hovered
                    ? const Color(0xFF222226)
                    : const Color(0xFF1A1A1D),
                borderRadius: BorderRadius.circular(DebugTheme.radiusFull),
                border: Border.all(color: const Color(0xFF2E2E32)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: DebugTheme.textSecondary,
                  fontSize: DebugTheme.fontSizeSm,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
