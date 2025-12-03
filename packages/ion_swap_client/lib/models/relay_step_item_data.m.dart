// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';

part 'relay_step_item_data.m.freezed.dart';
part 'relay_step_item_data.m.g.dart';

@freezed
class RelayStepItemData with _$RelayStepItemData {
  factory RelayStepItemData({
    required String to,
  }) = _RelayStepItemData;

  factory RelayStepItemData.fromJson(Map<String, dynamic> json) =>
      _$RelayStepItemDataFromJson(json);
}
