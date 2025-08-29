// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'replied_events_map.f.freezed.dart';

@freezed
class RepliesMap with _$RepliesMap {
  const factory RepliesMap(Map<String, List<String>> replies) = _RepliesMap;
}
