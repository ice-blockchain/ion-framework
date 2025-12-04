// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion_swap_client/models/relay_step_item_data.m.dart';

part 'relay_step_item.m.freezed.dart';
part 'relay_step_item.m.g.dart';

@freezed
class RelayStepItem with _$RelayStepItem {
  factory RelayStepItem({
    required RelayStepItemData data,
  }) = _RelayStepItem;

  factory RelayStepItem.fromJson(Map<String, dynamic> json) => _$RelayStepItemFromJson(json);
}
