import 'dart:convert';

import 'package:zenrouter/zenrouter.dart';

/// Versioned URI-first document of a matched Observed navigation log.
final class NavigationFlowSession {
  static const currentSchemaVersion = 1;
  static const kind = 'zenrouter.devtools.observedSession';

  const NavigationFlowSession({
    required this.initialUri,
    required this.transitions,
    this.ignoredTransitionCount = 0,
    this.exportedAt,
    this.schemaVersion = currentSchemaVersion,
  });

  final int schemaVersion;
  final Uri initialUri;
  final int ignoredTransitionCount;
  final DateTime? exportedAt;
  final List<NavigationFlowSessionTransition> transitions;

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'kind': kind,
    if (exportedAt != null) 'exportedAt': exportedAt!.toUtc().toIso8601String(),
    'initialUri': initialUri.toString(),
    'ignoredTransitionCount': ignoredTransitionCount,
    'transitions': [for (final transition in transitions) transition.toJson()],
  };

  factory NavigationFlowSession.fromJson(Map<String, Object?> json) {
    final kind = json['kind'];
    if (kind is! String) {
      throw const FormatException('Observed session kind must be a string');
    }
    if (kind != NavigationFlowSession.kind) {
      throw FormatException('Unknown observed session kind: $kind');
    }

    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int) {
      throw const FormatException(
        'Observed session schemaVersion must be an integer',
      );
    }
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException(
        'Unknown observed session schemaVersion: $schemaVersion',
      );
    }

    final initialUri = json['initialUri'];
    if (initialUri is! String) {
      throw const FormatException(
        'Observed session initialUri must be a URI string',
      );
    }

    final ignoredTransitionCount = json['ignoredTransitionCount'];
    if (ignoredTransitionCount != null && ignoredTransitionCount is! int) {
      throw const FormatException(
        'Observed session ignoredTransitionCount must be an integer',
      );
    }
    if (ignoredTransitionCount is int && ignoredTransitionCount < 0) {
      throw const FormatException(
        'Observed session ignoredTransitionCount must not be negative',
      );
    }

    final exportedAt = json['exportedAt'];
    if (exportedAt != null && exportedAt is! String) {
      throw const FormatException(
        'Observed session exportedAt must be an ISO-8601 string',
      );
    }

    return NavigationFlowSession(
      schemaVersion: schemaVersion,
      initialUri: Uri.parse(initialUri),
      ignoredTransitionCount: ignoredTransitionCount as int? ?? 0,
      exportedAt: exportedAt == null
          ? null
          : DateTime.parse(exportedAt as String),
      transitions: _transitionList(json),
    );
  }

  String encode() => jsonEncode(toJson());

  factory NavigationFlowSession.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Observed session must be a JSON object');
    }
    return NavigationFlowSession.fromJson(decoded.cast<String, Object?>());
  }
}

/// One matched commit in a [NavigationFlowSession] document.
final class NavigationFlowSessionTransition {
  const NavigationFlowSessionTransition({
    required this.revision,
    required this.previousUri,
    required this.currentUri,
    required this.historyIntent,
    required this.occurredAt,
    this.actionLabel,
    this.fromId,
    this.toId,
  });

  final int revision;
  final String previousUri;
  final String currentUri;
  final String historyIntent;
  final String? actionLabel;
  final String occurredAt;
  final String? fromId;
  final String? toId;

  Map<String, Object?> toJson() => {
    'revision': revision,
    'previousUri': previousUri,
    'currentUri': currentUri,
    'historyIntent': historyIntent,
    if (actionLabel != null) 'actionLabel': actionLabel,
    'occurredAt': occurredAt,
    if (fromId != null) 'fromId': fromId,
    if (toId != null) 'toId': toId,
  };

  factory NavigationFlowSessionTransition.fromJson(Map<String, Object?> json) {
    final revision = json['revision'];
    if (revision is! int) {
      throw const FormatException(
        'Observed session transition revision must be an integer',
      );
    }

    final previousUri = json['previousUri'];
    if (previousUri is! String) {
      throw const FormatException(
        'Observed session transition previousUri must be a URI string',
      );
    }

    final currentUri = json['currentUri'];
    if (currentUri is! String) {
      throw const FormatException(
        'Observed session transition currentUri must be a URI string',
      );
    }

    final historyIntent = json['historyIntent'];
    if (historyIntent is! String ||
        !_isNavigationHistoryIntentName(historyIntent)) {
      throw FormatException(
        'Unknown observed session historyIntent: $historyIntent',
      );
    }

    final occurredAt = json['occurredAt'];
    if (occurredAt is! String) {
      throw const FormatException(
        'Observed session transition occurredAt must be an ISO-8601 string',
      );
    }
    DateTime.parse(occurredAt);

    final actionLabel = json['actionLabel'];
    if (actionLabel != null && actionLabel is! String) {
      throw const FormatException(
        'Observed session transition actionLabel must be a string',
      );
    }

    final fromId = json['fromId'];
    if (fromId != null && fromId is! String) {
      throw const FormatException(
        'Observed session transition fromId must be a string',
      );
    }

    final toId = json['toId'];
    if (toId != null && toId is! String) {
      throw const FormatException(
        'Observed session transition toId must be a string',
      );
    }

    return NavigationFlowSessionTransition(
      revision: revision,
      previousUri: previousUri,
      currentUri: currentUri,
      historyIntent: historyIntent,
      actionLabel: actionLabel as String?,
      occurredAt: occurredAt,
      fromId: fromId as String?,
      toId: toId as String?,
    );
  }
}

List<NavigationFlowSessionTransition> _transitionList(
  Map<String, Object?> json,
) {
  final value = json['transitions'];
  if (value is! List) {
    throw const FormatException('Observed session transitions must be a list');
  }
  return [
    for (final entry in value)
      NavigationFlowSessionTransition.fromJson(_asJsonObject(entry)),
  ];
}

Map<String, Object?> _asJsonObject(Object? value) {
  if (value is! Map) {
    throw const FormatException(
      'Observed session transitions must contain objects',
    );
  }
  return value.cast<String, Object?>();
}

bool _isNavigationHistoryIntentName(String name) {
  for (final value in NavigationHistoryIntent.values) {
    if (value.name == name) return true;
  }
  return false;
}
