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

/// Second Observed header row: playhead transport, speed, export/import.
class ObservedReplayTransport extends StatelessWidget {
  const ObservedReplayTransport({
    super.key,
    required this.isLive,
    required this.isPlaying,
    required this.enabled,
    required this.speed,
    this.banner,
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
    this.onConfirmDrive,
    this.onCancelDrive,
    this.driveArmed = false,
    this.driveConfirmPending = false,
    this.timelineOpen = false,
  });

  final bool isLive;
  final bool isPlaying;
  final bool enabled;
  final bool timelineOpen;
  final double speed;
  final String? banner;
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
  final VoidCallback? onConfirmDrive;
  final VoidCallback? onCancelDrive;
  final bool driveArmed;
  final bool driveConfirmPending;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 32,
          decoration: const BoxDecoration(
            color: DebugTheme.backgroundDark,
            border: Border(bottom: BorderSide(color: DebugTheme.borderDark)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: DebugTheme.spacingXs,
            ),
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
                  color: enabled
                      ? const Color(0xFF60A5FA)
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
                if (!isLive)
                  _ReplayTransportButton(
                    key: const ValueKey('observed-replay-exit'),
                    semanticsLabel: 'Exit replay',
                    icon: CupertinoIcons.xmark,
                    onTap: onExit,
                  ),
                _ReplaySpeedButton(speed: speed, onTap: onCycleSpeed),
                if (onToggleDrive != null)
                  _ReplayTransportButton(
                    key: const ValueKey('observed-replay-drive'),
                    semanticsLabel: driveArmed
                        ? 'Stop driving the live app'
                        : 'Drive the live app to the playhead',
                    icon: CupertinoIcons.car,
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
                  color: !enabled
                      ? DebugTheme.textDisabled
                      : timelineOpen
                      ? const Color(0xFF60A5FA)
                      : DebugTheme.textSecondary,
                  onTap: enabled ? onToggleTimeline : null,
                ),
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
              ],
            ),
          ),
        ),
        if (driveConfirmPending)
          _DriveConfirmBar(onConfirm: onConfirmDrive, onCancel: onCancelDrive)
        else if (banner != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              DebugTheme.spacingMd,
              4,
              DebugTheme.spacingMd,
              6,
            ),
            color: const Color(0xFF1A1408),
            child: Text(
              banner!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: DebugTheme.fontSizeSm,
                decoration: TextDecoration.none,
              ),
            ),
          ),
      ],
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

class _DriveConfirmBar extends StatelessWidget {
  const _DriveConfirmBar({this.onConfirm, this.onCancel});

  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DebugTheme.spacingMd,
        6,
        DebugTheme.spacingXs,
        6,
      ),
      color: const Color(0xFF1A1408),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Drive the live app via navigate? Redirects may re-run.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: DebugTheme.fontSizeSm,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          GestureDetector(
            key: const ValueKey('observed-replay-drive-cancel'),
            onTap: onCancel,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: DebugTheme.spacingSm),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: DebugTheme.textSecondary,
                  fontSize: DebugTheme.fontSizeSm,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          GestureDetector(
            key: const ValueKey('observed-replay-drive-confirm'),
            onTap: onConfirm,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: DebugTheme.spacingSm),
              child: Text(
                'Drive',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: DebugTheme.fontSizeSm,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplayTransportButton extends StatelessWidget {
  const _ReplayTransportButton({
    super.key,
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 32,
          child: Icon(
            icon,
            size: 13.5,
            color: enabled
                ? (color ?? DebugTheme.textSecondary)
                : DebugTheme.textDisabled,
          ),
        ),
      ),
    );
  }
}

class _ReplaySpeedButton extends StatelessWidget {
  const _ReplaySpeedButton({required this.speed, required this.onTap});

  final double speed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = speed == speed.roundToDouble()
        ? '${speed.toInt()}×'
        : '$speed×';
    return Semantics(
      button: true,
      label: 'Replay speed $label',
      child: GestureDetector(
        key: const ValueKey('observed-replay-speed'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 32,
          child: Center(
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
    );
  }
}
