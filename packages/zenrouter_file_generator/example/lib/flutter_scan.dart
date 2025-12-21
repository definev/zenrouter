import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that visualizes widget rebuilds by drawing a flashing rectangle
/// over widgets that have just rebuilt.
///
/// Usage:
/// ```dart
/// void main() {
///   runApp(
///     FlutterScan(
///       enabled: true,
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class FlutterScan extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const FlutterScan({super.key, required this.child, this.enabled = true});

  @override
  State<FlutterScan> createState() => _FlutterScanState();
}

class _FlutterScanState extends State<FlutterScan>
    with SingleTickerProviderStateMixin {
  final ListQueue<_RebuildInfo> _rebuilds = ListQueue();
  late final Ticker _ticker;
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);
  final List<Element> _dirtyElements = [];
  bool _frameCallbackScheduled = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.enabled) {
      _enableScanning();
    }
  }

  @override
  void didUpdateWidget(FlutterScan oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _enableScanning();
      } else {
        _disableScanning();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _disableScanning();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _tickNotifier.value++;

    // Cleanup old rebuilds
    final now = DateTime.now();
    while (_rebuilds.isNotEmpty) {
      final info = _rebuilds.first;
      if (now.difference(info.timestamp).inMilliseconds > 500) {
        _rebuilds.removeFirst();
      } else {
        break;
      }
    }

    if (_rebuilds.isEmpty) {
      _ticker.stop();
    }
  }

  void _enableScanning() {
    debugOnRebuildDirtyWidget = _onRebuildDirtyWidget;
  }

  void _disableScanning() {
    if (debugOnRebuildDirtyWidget == _onRebuildDirtyWidget) {
      debugOnRebuildDirtyWidget = null;
    }
    _rebuilds.clear();
    _ticker.stop();
  }

  void _onRebuildDirtyWidget(Element element, bool builtOnce) {
    // Avoid scanning our own internal widgets to prevent infinite loops
    if (element.widget is FlutterScan) {
      if (element.widget.runtimeType.toString() == '_RebuildPainter' ||
          element.widget is FlutterScan) {
        return;
      }
    }

    // We only care about elements that have a render object attached directly
    // or indirectly that we can measure.
    if (element.renderObject == null || !element.renderObject!.attached) {
      return;
    }

    _dirtyElements.add(element);
    if (!_frameCallbackScheduled) {
      _frameCallbackScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback(_onPostFrame);
    }
  }

  void _onPostFrame(Duration timeStamp) {
    _frameCallbackScheduled = false;
    if (!mounted) {
      _dirtyElements.clear();
      return;
    }

    final now = DateTime.now();
    bool addedAny = false;

    for (final element in _dirtyElements) {
      // The logic from _processElement is now inlined here.
      if (!element.mounted || element.renderObject == null) continue;

      final renderObject = element.renderObject!;
      if (!renderObject.attached) continue;

      // We don't calculate rect here anymore, we just store the renderObject.
      // But we do check if it's visible/valid to avoid adding junk.
      try {
        // Quick check if it has size (optional, but good for perf)
        if (!renderObject.paintBounds.isEmpty) {
          _rebuilds.add(
            _RebuildInfo(renderObject: renderObject, timestamp: now),
          );
          addedAny = true;
        }
      } catch (e) {
        // Ignore
      }
    }
    _dirtyElements.clear();

    if (addedAny && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        // Overlay for rebuilds
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _RebuildPainter(
              rebuilds: _rebuilds,
              repaint: _tickNotifier,
            ),
          ),
        ),
      ],
    );
  }
}

class _RebuildInfo {
  final WeakReference<RenderObject> renderObjectRef;
  final DateTime timestamp;

  _RebuildInfo({required RenderObject renderObject, required this.timestamp})
    : renderObjectRef = WeakReference(renderObject);
}

class _RebuildPainter extends CustomPainter {
  final ListQueue<_RebuildInfo> rebuilds;

  _RebuildPainter({required this.rebuilds, required super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    for (final info in rebuilds) {
      final renderObject = info.renderObjectRef.target;
      if (renderObject == null || !renderObject.attached) continue;

      final age = now.difference(info.timestamp).inMilliseconds;
      if (age > 500) continue;

      try {
        final transform = renderObject.getTransformTo(null);
        final paintBounds = renderObject.paintBounds;
        final rect = MatrixUtils.transformRect(transform, paintBounds);

        if (rect.isEmpty) continue;

        final opacity = 1.0 - (age / 500.0);

        const strokeWidth = 2.0;
        final insideRect = rect.deflate(strokeWidth / 2);

        final borderPaint = Paint()
          ..color = const Color.fromARGB(
            255,
            104,
            167,
            159,
          ).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

        canvas.drawRect(insideRect, borderPaint);
      } catch (e) {
        // RenderObject might be detached during paint
      }
    }
  }

  @override
  bool shouldRepaint(_RebuildPainter oldDelegate) => true;
}
