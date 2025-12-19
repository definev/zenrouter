import 'package:collection/collection.dart';
import 'package:zenrouter/src/path.dart';

/// Returns a `hashCode` for [props].
///
/// This combines the hash codes of all elements in [props] using the Jenkins
/// hash function, similar to how `Equatable` calculates hash codes.
int mapPropsToHashCode(Iterable<Object?>? props) {
  return _finish(props == null ? 0 : props.fold(0, _combine));
}

/// Determines whether two lists ([a] and [b]) are equal.
///
/// Returns `true` if both lists contain the same elements in the same order.
/// Returns `false` if either list is null or if they have different lengths
/// or contents.
// See https://github.com/felangel/equatable/issues/187.
@pragma('vm:prefer-inline')
bool equals(List<Object?>? a, List<Object?>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return iterableEquals(a, b);
}

/// Determines whether two iterables are equal.
///
/// Returns `true` if both iterables contain the same elements in the same order.
/// Throws an [AssertionError] if either argument is a [Set], as sets should
/// be compared using [setEquals].
@pragma('vm:prefer-inline')
bool iterableEquals(Iterable<Object?> a, Iterable<Object?> b) {
  assert(
    a is! Set && b is! Set,
    "iterableEquals doesn't support Sets. Use setEquals instead.",
  );
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!objectsEquals(a.elementAt(i), b.elementAt(i))) return false;
  }
  return true;
}

/// Determines whether two numbers are equal.
///
/// Returns `true` if [a] and [b] are equal.
@pragma('vm:prefer-inline')
bool numEquals(num a, num b) => a == b;

/// Determines whether two sets are equal.
///
/// Returns `true` if both sets contain the same elements, regardless of order.
/// Elements are compared using [objectsEquals].
bool setEquals(Set<Object?> a, Set<Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final element in a) {
    if (!b.any((e) => objectsEquals(element, e))) return false;
  }
  return true;
}

/// Determines whether two maps are equal.
///
/// Returns `true` if both maps contain the same keys and values.
/// Keys and values are compared using [objectsEquals].
bool mapEquals(Map<Object?, Object?> a, Map<Object?, Object?> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!objectsEquals(a[key], b[key])) return false;
  }
  return true;
}

/// Determines whether two objects are equal.
///
/// This handles various types including numbers, [RouteTarget]s, [Set]s,
/// [Iterable]s, and [Map]s. It performs deep equality checks where appropriate.
@pragma('vm:prefer-inline')
bool objectsEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is num && b is num) {
    return numEquals(a, b);
  } else if (_isEquatable(a) && _isEquatable(b)) {
    return a == b;
  } else if (a is Set && b is Set) {
    return setEquals(a, b);
  } else if (a is Iterable && b is Iterable) {
    return iterableEquals(a, b);
  } else if (a is Map && b is Map) {
    return mapEquals(a, b);
  } else if (a?.runtimeType != b?.runtimeType) {
    return false;
  } else if (a != b) {
    return false;
  }
  return true;
}

@pragma('vm:prefer-inline')
bool _isEquatable(Object? object) {
  return object is Equatable;
}

/// Jenkins Hash Functions
/// https://en.wikipedia.org/wiki/Jenkins_hash_function
int _combine(int hash, Object? object) {
  if (object is Map) {
    object.keys
        .sorted((Object? a, Object? b) => a.hashCode - b.hashCode)
        .forEach((Object? key) {
          hash = hash ^ _combine(hash, [key, (object! as Map)[key]]);
        });
    return hash;
  }
  if (object is Set) {
    object = object.sorted((Object? a, Object? b) => a.hashCode - b.hashCode);
  }
  if (object is Iterable) {
    for (final value in object) {
      hash = hash ^ _combine(hash, value);
    }
    return hash ^ object.length;
  }

  hash = 0x1fffffff & (hash + object.hashCode);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

/// Returns a string for [props].
String mapPropsToString(Type runtimeType, List<Object?> props) {
  return '$runtimeType(${props.map((prop) => prop.toString()).join(', ')})';
}

/// Base class for objects that can be compared for equality.
///
/// [Equatable] provides value-based equality for ZenRouter routes and paths.
/// Unlike Dart's default reference equality, two [Equatable] objects are
/// equal if they have the same [runtimeType] and [props].
///
/// ## Why ZenRouter has its own Equatable
///
/// While similar to the `equatable` package, this implementation:
/// - Integrates with ZenRouter's internal state ([internalProps])
/// - Provides [compareWith] for controlled equality checks
/// - Avoids external dependencies
///
/// ## props vs internalProps
///
/// | Property       | Purpose                                    | When to override? |
/// |----------------|-------------------------------------------|-------------------|
/// | [props]        | User-defined equality (route parameters)   | **Yes** - always  |
/// | [internalProps]| Framework state (path, completer, etc.)    | **Never**         |
///
/// **Example:**
/// ```dart
/// class ProductRoute extends RouteTarget with RouteUnique {
///   final String productId;
///   final String? variant;
///
///   ProductRoute(this.productId, {this.variant});
///
///   // Include all parameters that make this route unique
///   @override
///   List<Object?> get props => [productId, variant];
///
///   // Do NOT override internalProps - framework manages it
/// }
/// ```
///
/// ## Equality Behavior
///
/// Two routes are equal when:
/// 1. Same [runtimeType] (e.g., both are `ProductRoute`)
/// 2. Same [props] values (e.g., same `productId`)
///
/// [internalProps] are NOT compared in [compareWith] but ARE used for:
/// - Hash code generation
/// - Internal framework identity checks
abstract class Equatable {
  /// Framework-managed properties for internal identity.
  ///
  /// **Do not override.** This is used by ZenRouter to track:
  /// - Runtime type
  /// - Path binding (`_path`)
  /// - Result completer (`_onResult`)
  ///
  /// These are combined with [props] for hash code generation but are
  /// NOT compared in [compareWith] / `==` operator.
  List<Object?> get internalProps => [];

  /// User-defined properties for equality comparison.
  ///
  /// Override this to include all parameters that make this route unique.
  ///
  /// **Guidelines:**
  /// - Include all constructor parameters that affect identity
  /// - Use consistent ordering across instances
  /// - Avoid including mutable state
  ///
  /// **Example:**
  /// ```dart
  /// class OrderRoute extends RouteTarget with RouteUnique {
  ///   final String orderId;
  ///   final bool isReadOnly;
  ///
  ///   OrderRoute(this.orderId, {this.isReadOnly = false});
  ///
  ///   @override
  ///   List<Object?> get props => [orderId, isReadOnly];
  /// }
  /// ```
  List<Object?> get props => [];

  @override
  operator ==(Object other) => compareWith(other);

  /// Compares this object with another for equality.
  ///
  /// This is the implementation behind the `==` operator. It checks:
  /// 1. Identity (same reference)
  /// 2. Type equality
  /// 3. [props] equality (deep comparison)
  ///
  /// **When to use directly:**
  /// Call this from a custom `==` override if you need pre/post processing:
  /// ```dart
  /// @override
  /// operator ==(Object other) {
  ///   if (other is! MyRoute) return false;
  ///   // Custom pre-check
  ///   return compareWith(other);
  /// }
  /// ```
  @pragma('vm:prefer-inline')
  bool compareWith(Object other) {
    if (identical(this, other)) return true;
    return other is Equatable &&
        other.runtimeType == runtimeType &&
        iterableEquals(props, other.props);
  }

  @override
  int get hashCode =>
      mapPropsToHashCode(internalProps) ^ mapPropsToHashCode(props);

  @override
  String toString() {
    if (props.isEmpty) return runtimeType.toString();
    return '$runtimeType[${props.map((prop) => prop.toString()).join(',')}]';
  }
}
