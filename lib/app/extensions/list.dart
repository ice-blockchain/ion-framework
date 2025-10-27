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

  bool containsDeep(List<String> target) {
    return any((list) => list is List<String> && const ListEquality<String>().equals(list, target));
  }
}
