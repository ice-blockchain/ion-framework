// SPDX-License-Identifier: ice License 1.0

extension SeparatedExtensions<T> on Iterable<T> {
  /// Puts [separator] between every element in [iterable].
  ///
  /// Example:
  ///
  ///     final list1 = <int>[].separated(2); // [];
  ///     final list2 = [0].separated(2); // [0];
  ///     final list3 = [0, 0].separated(2); // [0, 2, 0];
  ///
  Iterable<T> separated(T element) sync* {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      yield iterator.current;
      while (iterator.moveNext()) {
        yield element;
        yield iterator.current;
      }
    }
  }
}

extension DistinctBy<T, K> on Iterable<T> {
  List<T> distinctBy(K Function(T) key) {
    final seen = <K>{};
    return where((e) => seen.add(key(e))).toList();
  }
}
