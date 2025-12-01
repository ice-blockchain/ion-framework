// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

@immutable
class ParticipantKeys {
  const ParticipantKeys({required this.keys});
  final List<String> keys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantKeys && const ListEquality<String>().equals(keys, other.keys);

  @override
  int get hashCode => const ListEquality<String>().hash(keys);
}
