import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:zenrouter/zenrouter.dart';

import 'navigation_flow_session.dart';

/// One route observed while the application is running.
final class NavigationFlowNode<I extends Object> {
  const NavigationFlowNode({
    required this.id,
    required this.firstSeenRevision,
    required this.lastSeenRevision,
    required this.lastUri,
    required this.visitCount,
    this.screenPreview,
  });

  final I id;
  final int firstSeenRevision;
  final int lastSeenRevision;
  final Uri lastUri;
  final int visitCount;

  /// Latest in-memory screenshot captured for this route.
  final NavigationFlowScreenPreview? screenPreview;
}

/// A memory-only screenshot associated with an observed route.
final class NavigationFlowScreenPreview {
  NavigationFlowScreenPreview({
    required Uint8List bytes,
    required this.revision,
    required this.capturedAt,
    this.width,
    this.height,
  }) : bytes = Uint8List.fromList(bytes);

  /// PNG-encoded image bytes.
  final Uint8List bytes;
  final int revision;
  final DateTime capturedAt;
  final int? width;
  final int? height;

  /// Aspect ratio (width / height) if dimensions are known.
  double? get aspectRatio => (width != null && height != null && height! > 0)
      ? width! / height!
      : null;
}

/// One committed transition in chronological order.
final class NavigationFlowTransition<I extends Object> {
  const NavigationFlowTransition({
    required this.revision,
    required this.fromId,
    required this.toId,
    required this.previousUri,
    required this.currentUri,
    required this.historyIntent,
    required this.actionLabel,
    required this.occurredAt,
  });

  final int revision;
  final I fromId;
  final I toId;
  final Uri previousUri;
  final Uri currentUri;
  final NavigationHistoryIntent historyIntent;

  /// Optional user-facing cause supplied through `debugFlowAction`.
  final String? actionLabel;
  final DateTime occurredAt;

  String get displayLabel => actionLabel ?? historyIntent.name;
}

/// Aggregated directed edge between two routes observed at runtime.
final class NavigationFlowEdge<I extends Object> {
  const NavigationFlowEdge({
    required this.fromId,
    required this.toId,
    required this.count,
    required this.firstSeenRevision,
    required this.lastSeenRevision,
    required this.lastHistoryIntent,
    required this.lastActionLabel,
    required this.historyIntents,
    required this.actionLabels,
  });

  final I fromId;
  final I toId;
  final int count;
  final int firstSeenRevision;
  final int lastSeenRevision;
  final NavigationHistoryIntent lastHistoryIntent;
  final String? lastActionLabel;
  final Set<NavigationHistoryIntent> historyIntents;
  final Set<String> actionLabels;

  String get displayLabel => lastActionLabel ?? lastHistoryIntent.name;
}

/// Records route-to-route transitions from atomic [NavigationCommit]s.
///
/// The recorder deliberately consumes the public manifest and commit seams. It
/// does not inspect widgets or depend on presentation route implementations.
/// Commits whose endpoints cannot be matched by the manifest are counted but
/// omitted from the directed graph.
final class NavigationFlowRecorder<I extends Object> extends ChangeNotifier {
  static const _maxActionLabelsPerEdge = 16;

  NavigationFlowRecorder({
    required this.manifest,
    required Uri initialUri,
    this.maxTransitions = 500,
    this.maxScreenPreviews = 24,
    int initialRevision = -1,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _lastRecordedRevision = initialRevision,
       _initialUri = initialUri {
    if (maxTransitions <= 0) {
      throw ArgumentError.value(
        maxTransitions,
        'maxTransitions',
        'must be greater than zero',
      );
    }
    if (initialRevision < -1) {
      throw ArgumentError.value(
        initialRevision,
        'initialRevision',
        'must be at least -1',
      );
    }
    if (maxScreenPreviews < 0) {
      throw ArgumentError.value(
        maxScreenPreviews,
        'maxScreenPreviews',
        'must not be negative',
      );
    }
    _observeInitialUri(initialUri);
  }

  /// Rebuild nodes/edges/transitions by rematching [session] URIs
  /// against [manifest]. Does not attach previews.
  factory NavigationFlowRecorder.fromSession(
    RouteManifest<I> manifest,
    NavigationFlowSession session, {
    int maxTransitions = 500,
    int maxScreenPreviews = 24,
  }) {
    var hydrateIndex = 0;
    var hydrating = true;
    final recorder = NavigationFlowRecorder<I>(
      manifest: manifest,
      initialUri: session.initialUri,
      maxTransitions: maxTransitions,
      maxScreenPreviews: maxScreenPreviews,
      initialRevision: -1,
      clock: () {
        if (!hydrating || hydrateIndex >= session.transitions.length) {
          return DateTime.now();
        }
        return DateTime.parse(session.transitions[hydrateIndex].occurredAt);
      },
    );

    var newlyUnmatched = 0;
    for (; hydrateIndex < session.transitions.length; hydrateIndex++) {
      final row = session.transitions[hydrateIndex];
      final ignoredBefore = recorder._ignoredTransitionCount;
      recorder._record(
        NavigationCommit(
          revision: row.revision,
          previousUri: Uri.parse(row.previousUri),
          currentUri: Uri.parse(row.currentUri),
          historyIntent: NavigationHistoryIntent.values.byName(
            row.historyIntent,
          ),
        ),
        actionLabel: row.actionLabel,
      );
      if (recorder._ignoredTransitionCount > ignoredBefore) {
        newlyUnmatched += 1;
      }
    }
    hydrating = false;
    recorder._ignoredTransitionCount =
        session.ignoredTransitionCount + newlyUnmatched;
    return recorder;
  }

  final RouteManifest<I> manifest;
  final int maxTransitions;
  final int maxScreenPreviews;
  final DateTime Function() _clock;

  final Map<I, NavigationFlowNode<I>> _nodes = {};
  final Map<_NavigationFlowEdgeKey<I>, NavigationFlowEdge<I>> _edges = {};
  final List<NavigationFlowTransition<I>> _transitions = [];
  final LinkedHashSet<I> _screenPreviewOrder = LinkedHashSet();
  final Map<int, NavigationFlowScreenPreview> _previewsByRevision = {};
  int _lastRecordedRevision;
  int _ignoredTransitionCount = 0;
  I? _entryNodeId;
  Uri _initialUri;

  Map<I, NavigationFlowNode<I>> get nodes => UnmodifiableMapView(_nodes);

  List<NavigationFlowEdge<I>> get edges => List.unmodifiable(
    _edges.values.toList(growable: false)..sort(
      (left, right) =>
          left.firstSeenRevision.compareTo(right.firstSeenRevision),
    ),
  );

  List<NavigationFlowTransition<I>> get transitions =>
      List.unmodifiable(_transitions);

  I? get entryNodeId => _entryNodeId;
  int get lastRecordedRevision => _lastRecordedRevision;
  int get ignoredTransitionCount => _ignoredTransitionCount;
  bool get isEmpty => _edges.isEmpty;

  /// The node-latest preview whose [NavigationFlowScreenPreview.revision]
  /// equals [revision], if any. Same instance as `nodes[id].screenPreview`.
  NavigationFlowScreenPreview? previewForRevision(int revision) =>
      _previewsByRevision[revision];

  /// Captures [commit] once, returning whether recorder state changed.
  bool record(NavigationCommit commit, {String? actionLabel}) {
    final changed = _record(commit, actionLabel: actionLabel);
    if (changed) notifyListeners();
    return changed;
  }

  /// URI-first document of the current matched log. No preview bytes.
  NavigationFlowSession exportSession() {
    return NavigationFlowSession(
      initialUri: _initialUri,
      ignoredTransitionCount: _ignoredTransitionCount,
      exportedAt: _clock(),
      transitions: [
        for (final transition in _transitions)
          NavigationFlowSessionTransition(
            revision: transition.revision,
            previousUri: transition.previousUri.toString(),
            currentUri: transition.currentUri.toString(),
            historyIntent: transition.historyIntent.name,
            actionLabel: transition.actionLabel,
            occurredAt: transition.occurredAt.toUtc().toIso8601String(),
            fromId: _encodeRouteId(transition.fromId),
            toId: _encodeRouteId(transition.toId),
          ),
      ],
    );
  }

  String _encodeRouteId(I id) {
    final codec = manifest.idCodec;
    if (codec == null) return id.toString();
    try {
      return codec.encode(id);
    } catch (_) {
      return id.toString();
    }
  }

  bool _record(NavigationCommit commit, {String? actionLabel}) {
    if (commit.revision <= _lastRecordedRevision) return false;
    _lastRecordedRevision = commit.revision;

    final fromId = manifest.match(commit.previousUri)?.id;
    final toId = manifest.match(commit.currentUri)?.id;
    if (fromId == null || toId == null) {
      _ignoredTransitionCount += 1;
      if (fromId != null) {
        _observeNode(fromId, commit.previousUri, commit.revision);
      }
      if (toId != null) {
        _observeNode(
          toId,
          commit.currentUri,
          commit.revision,
          incrementVisit: true,
        );
      }
      return true;
    }

    final normalizedLabel = switch (actionLabel?.trim()) {
      final label? when label.isNotEmpty => label,
      _ => null,
    };
    _observeNode(fromId, commit.previousUri, commit.revision);
    _observeNode(
      toId,
      commit.currentUri,
      commit.revision,
      incrementVisit: true,
    );

    final transition = NavigationFlowTransition<I>(
      revision: commit.revision,
      fromId: fromId,
      toId: toId,
      previousUri: commit.previousUri,
      currentUri: commit.currentUri,
      historyIntent: commit.historyIntent,
      actionLabel: normalizedLabel,
      occurredAt: _clock(),
    );
    _transitions.add(transition);
    if (_transitions.length > maxTransitions) {
      _transitions.removeAt(0);
    }

    final key = _NavigationFlowEdgeKey(fromId, toId);
    final previousEdge = _edges[key];
    final intents = {...?previousEdge?.historyIntents, commit.historyIntent};
    final labels = LinkedHashSet<String>.of(
      previousEdge?.actionLabels ?? const {},
    );
    if (normalizedLabel != null) labels.add(normalizedLabel);
    while (labels.length > _maxActionLabelsPerEdge) {
      labels.remove(labels.first);
    }
    _edges[key] = NavigationFlowEdge<I>(
      fromId: fromId,
      toId: toId,
      count: (previousEdge?.count ?? 0) + 1,
      firstSeenRevision: previousEdge?.firstSeenRevision ?? commit.revision,
      lastSeenRevision: commit.revision,
      lastHistoryIntent: commit.historyIntent,
      lastActionLabel: normalizedLabel,
      historyIntents: Set.unmodifiable(intents),
      actionLabels: Set.unmodifiable(labels),
    );
    return true;
  }

  /// Stores the latest PNG preview for [id] and evicts older previews.
  ///
  /// Screenshots remain in memory only and are discarded by [clear].
  bool attachScreenPreview(
    I id,
    Uint8List pngBytes, {
    required int revision,
    int? width,
    int? height,
  }) {
    final node = _nodes[id];
    if (node == null || pngBytes.isEmpty || maxScreenPreviews == 0) {
      return false;
    }

    final previousPreview = node.screenPreview;
    if (previousPreview != null) {
      _previewsByRevision.remove(previousPreview.revision);
    }

    final preview = NavigationFlowScreenPreview(
      bytes: pngBytes,
      revision: revision,
      capturedAt: _clock(),
      width: width,
      height: height,
    );
    _nodes[id] = _copyNode(node, screenPreview: preview);
    _previewsByRevision[revision] = preview;
    _screenPreviewOrder
      ..remove(id)
      ..add(id);

    while (_screenPreviewOrder.length > maxScreenPreviews) {
      final evictedId = _screenPreviewOrder.first;
      _screenPreviewOrder.remove(evictedId);
      final evictedNode = _nodes[evictedId];
      if (evictedNode != null) {
        final evictedPreview = evictedNode.screenPreview;
        if (evictedPreview != null) {
          _previewsByRevision.remove(evictedPreview.revision);
        }
        _nodes[evictedId] = _copyNode(evictedNode, clearScreenPreview: true);
      }
    }
    notifyListeners();
    return true;
  }

  /// Clears observed edges while keeping revision deduplication intact.
  void clear({required Uri initialUri}) {
    _nodes.clear();
    _edges.clear();
    _transitions.clear();
    _screenPreviewOrder.clear();
    _previewsByRevision.clear();
    _ignoredTransitionCount = 0;
    _entryNodeId = null;
    _initialUri = initialUri;
    _observeInitialUri(initialUri);
    notifyListeners();
  }

  void _observeInitialUri(Uri uri) {
    final id = manifest.match(uri)?.id;
    if (id == null) return;
    _entryNodeId = id;
    _observeNode(id, uri, _lastRecordedRevision, incrementVisit: true);
  }

  void _observeNode(
    I id,
    Uri uri,
    int revision, {
    bool incrementVisit = false,
  }) {
    final previous = _nodes[id];
    final shouldIncrement = incrementVisit || previous == null;
    _nodes[id] = NavigationFlowNode<I>(
      id: id,
      firstSeenRevision: previous?.firstSeenRevision ?? revision,
      lastSeenRevision: revision,
      lastUri: uri,
      visitCount: (previous?.visitCount ?? 0) + (shouldIncrement ? 1 : 0),
      screenPreview: previous?.screenPreview,
    );
    _entryNodeId ??= id;
  }

  NavigationFlowNode<I> _copyNode(
    NavigationFlowNode<I> node, {
    NavigationFlowScreenPreview? screenPreview,
    bool clearScreenPreview = false,
  }) => NavigationFlowNode<I>(
    id: node.id,
    firstSeenRevision: node.firstSeenRevision,
    lastSeenRevision: node.lastSeenRevision,
    lastUri: node.lastUri,
    visitCount: node.visitCount,
    screenPreview: clearScreenPreview
        ? null
        : screenPreview ?? node.screenPreview,
  );
}

final class _NavigationFlowEdgeKey<I extends Object> {
  const _NavigationFlowEdgeKey(this.fromId, this.toId);

  final I fromId;
  final I toId;

  @override
  bool operator ==(Object other) =>
      other is _NavigationFlowEdgeKey<I> &&
      other.fromId == fromId &&
      other.toId == toId;

  @override
  int get hashCode => Object.hash(fromId, toId);
}
