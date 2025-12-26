// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:collection/collection.dart';

extension ListExtension<T> on List<T>? {
  List<T> get emptyOrValue => this ?? <T>[];

  Type get genericType => T;
}

extension ListRandomExtension<T> on List<T> {
  T? get random {
    return isNotEmpty ? this[Random().nextInt(length)] : null;
  }
}

extension DeepEqualityListExtension on List<dynamic> {
  static const _deepEquality = DeepCollectionEquality();

  bool equalsDeep(List<dynamic> other) {
    return _deepEquality.equals(this, other);
  }

  bool containsList(List<String> target) {
    return any(
      (element) => element is List<String> && const ListEquality<String>().equals(element, target),
    );
  }
}

extension Partition<T> on List<T> {
  /// Splits the list into two lists based on the provided [test] predicate.
  ///
  /// Returns a record with:
  /// - [match]: elements that satisfy the [test] predicate,
  /// - [rest]: elements that do not satisfy the [test] predicate.
  ({List<T1> match, List<T2> rest}) partition<T1 extends T, T2 extends T>(bool Function(T) test) {
    return fold(
      (match: <T1>[], rest: <T2>[]),
      (acc, element) {
        (test(element) ? acc.match : acc.rest).add(element);
        return acc;
      },
    );
  }
}
