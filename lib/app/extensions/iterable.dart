// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/utils/iterable.dart' as utils;

extension IntersperseExtensions<T> on Iterable<T> {
  /// Puts [element] between every element in [list].
  ///
  /// Example:
  ///
  ///     final list1 = <int>[].intersperse(2); // [];
  ///     final list2 = [0].intersperse(2); // [0];
  ///     final list3 = [0, 0].intersperse(2); // [0, 2, 0];
  ///
  Iterable<T> intersperse(T element) {
    return utils.intersperse(element, this);
  }
}

extension DistinctBy<T, K> on Iterable<T> {
  List<T> distinctBy(K Function(T) key) {
    final seen = <K>{};
    return where((e) => seen.add(key(e))).toList();
  }
}
