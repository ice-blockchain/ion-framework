import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

part 'entity_list_item.f.freezed.dart';

@freezed
abstract class IonEntityListItem with _$IonEntityListItem {
  const factory IonEntityListItem.event({required EventReference eventReference}) =
      EventIonEntityListItem;
  const factory IonEntityListItem.custom({required Widget child}) = CustomIonEntityListItem;
}
