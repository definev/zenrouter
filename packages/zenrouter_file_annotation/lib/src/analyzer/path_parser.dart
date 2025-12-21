/// Utility for parsing file paths into route segments and parameters.
///
/// This centralizes path parsing logic used by both route and coordinator generators.
class PathParser {
  /// Parse a relative file path into segments and parameters.
  ///
  /// Example:
  /// - `profile/[profileId]/collections/[collectionId]`
  ///   → segments: ['profile', ':profileId', 'collections', ':collectionId']
  ///   → params: [ParamInfo(name: 'profileId'), ParamInfo(name: 'collectionId')]
  /// - `posts/[...slug]`
  ///   → segments: ['posts', '...:slug']
  ///   → params: [ParamInfo(name: 'slug', isRest: true)]
  static (List<String>, List<ParamInfo>, bool, String) parsePath(
    String relativePath,
  ) {
    final segments = <String>[];
    final params = <ParamInfo>[];

    // Remove .dart extension and normalize dot-notation
    var path = relativePath;
    if (path.endsWith('.dart')) {
      path = path.substring(0, path.length - 5);
    }
    path = _normalizeFilePath(path);

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    final fileName = parts.isNotEmpty ? parts.last : '';
    final isIndexFile = fileName == 'index';

    // Track if we've seen a rest parameter
    bool hasRestParam = false;

    // Process each path segment, extracting dynamic parameters
    // This correctly handles multiple parameters in nested routes
    for (final part in parts) {
      // Skip private files
      if (part.startsWith('_')) continue;

      // Skip route groups (name) - they don't add to URL path
      if (part.startsWith('(') && part.endsWith(')')) continue;

      // Check for rest parameter [...name] - captures remaining segments
      if (part.startsWith('[...') && part.endsWith(']')) {
        final paramName = part.substring(4, part.length - 1);
        if (paramName.isEmpty) {
          throw ArgumentError(
            'Rest parameter name cannot be empty in path: $relativePath',
          );
        }
        if (hasRestParam) {
          throw ArgumentError(
            'Only one rest parameter [...] is allowed per route: $relativePath',
          );
        }
        hasRestParam = true;
        segments.add('...:$paramName');
        params.add(ParamInfo(name: paramName, isRest: true));
      }
      // Check for dynamic parameter [name]
      // Supports multiple parameters like [profileId] and [collectionId]
      else if (part.startsWith('[') && part.endsWith(']')) {
        final paramName = part.substring(1, part.length - 1);
        if (paramName.isEmpty) {
          throw ArgumentError(
            'Dynamic parameter name cannot be empty in path: $relativePath',
          );
        }
        segments.add(':$paramName');
        params.add(ParamInfo(name: paramName));
      } else if (part == 'index') {
        // index.dart doesn't add a segment
        continue;
      } else {
        segments.add(part);
      }
    }

    return (segments, params, isIndexFile, fileName);
  }

  /// Parse layout path segments (excludes dynamic parameters).
  static List<String> parseLayoutPath(String relativePath) {
    final segments = <String>[];

    // Remove .dart extension and _layout, then normalize dot-notation
    var path = relativePath;
    if (path.endsWith('.dart')) {
      path = path.substring(0, path.length - 5);
    }
    path = _normalizeFilePath(path);
    if (path.endsWith('/_layout')) {
      path = path.substring(0, path.length - 8);
    }

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    for (final part in parts) {
      if (part.startsWith('_')) continue;
      if (part.startsWith('(') && part.endsWith(')')) continue;
      segments.add(part);
    }

    return segments;
  }

  /// Normalize a file path that may contain dot-notation segments.
  ///
  /// Converts dot-notation to folder structure:
  /// - `docs.[id].detail` → `docs/[id]/detail`
  /// - `feed/tab/[id].detail` → `feed/tab/[id]/detail` (hybrid)
  ///
  /// Rules:
  /// - Dots inside brackets are preserved: `[...slugs]` stays as `[...slugs]`
  /// - Dots outside brackets become `/` separators
  /// - Works with hybrid paths mixing `/` and `.`
  static String _normalizeFilePath(String path) {
    final buffer = StringBuffer();
    int bracketDepth = 0;

    for (int i = 0; i < path.length; i++) {
      final char = path[i];

      if (char == '[') {
        bracketDepth++;
        buffer.write(char);
      } else if (char == ']') {
        bracketDepth--;
        buffer.write(char);
      } else if (char == '.' && bracketDepth == 0) {
        // Dot outside brackets becomes a path separator
        buffer.write('/');
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }
}

/// Simplified parameter info for path parsing.
class ParamInfo {
  final String name;

  /// Whether this is a rest parameter that captures multiple segments.
  final bool isRest;

  ParamInfo({required this.name, this.isRest = false});
}
