import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:zenrouter/zenrouter.dart';

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
  }) : bytes = Uint8List.fromList(bytes);

  /// PNG-encoded image bytes.
  final Uint8List bytes;
  final int revision;
  final DateTime capturedAt;
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
       _lastRecordedRevision = initialRevision {
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

  final RouteManifest<I> manifest;
  final int maxTransitions;
  final int maxScreenPreviews;
  final DateTime Function() _clock;

  final Map<I, NavigationFlowNode<I>> _nodes = {};
  final Map<_NavigationFlowEdgeKey<I>, NavigationFlowEdge<I>> _edges = {};
  final List<NavigationFlowTransition<I>> _transitions = [];
  final LinkedHashSet<I> _screenPreviewOrder = LinkedHashSet();
  int _lastRecordedRevision;
  int _ignoredTransitionCount = 0;
  I? _entryNodeId;

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

  /// Captures [commit] once, returning whether recorder state changed.
  bool record(NavigationCommit commit, {String? actionLabel}) {
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
      notifyListeners();
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
    notifyListeners();
    return true;
  }

  /// Stores the latest PNG preview for [id] and evicts older previews.
  ///
  /// Screenshots remain in memory only and are discarded by [clear].
  bool attachScreenPreview(I id, Uint8List pngBytes, {required int revision}) {
    final node = _nodes[id];
    if (node == null || pngBytes.isEmpty || maxScreenPreviews == 0) {
      return false;
    }

    _nodes[id] = _copyNode(
      node,
      screenPreview: NavigationFlowScreenPreview(
        bytes: pngBytes,
        revision: revision,
        capturedAt: _clock(),
      ),
    );
    _screenPreviewOrder
      ..remove(id)
      ..add(id);

    while (_screenPreviewOrder.length > maxScreenPreviews) {
      final evictedId = _screenPreviewOrder.first;
      _screenPreviewOrder.remove(evictedId);
      final evictedNode = _nodes[evictedId];
      if (evictedNode != null) {
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
    _ignoredTransitionCount = 0;
    _entryNodeId = null;
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
    screenPreview:
        clearScreenPreview ? null : screenPreview ?? node.screenPreview,
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
