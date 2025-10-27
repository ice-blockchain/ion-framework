// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';

extension DeepEqualityMapExtension on Map<dynamic, dynamic> {
  static const _deepEquality = DeepCollectionEquality();

  bool equalsDeep(Map<dynamic, dynamic> other) {
    return _deepEquality.equals(this, other);
  }
}
