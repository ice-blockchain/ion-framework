// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/label_namespace_tag.f.dart';
import 'package:ion/app/features/ion_connect/model/label_value_tag.f.dart';

part 'color_label.f.freezed.dart';

@freezed
class ColorLabel with _$ColorLabel {
  const factory ColorLabel({
    required String value,
  }) = _ColorLabel;

  const ColorLabel._();

  List<String> toNamespaceTag() {
    return const LabelNamespaceTag(value: namespace).toTag();
  }

  List<String> toValueTag() {
    return LabelValueTag(value: value, namespace: namespace).toTag();
  }

  static ColorLabel? fromTags(Map<String, List<List<String>>> tags, {required String eventId}) {
    final colorNamespaceTag = LabelNamespaceTag.fromTags(tags, namespace: namespace);

    if (colorNamespaceTag == null) return null;

    final colorTags = LabelValueTag.fromTags(tags, namespace: namespace);

    if (colorTags == null) {
      throw IncorrectEventTagsException(eventId: eventId);
    }

    return ColorLabel(value: colorTags.first.value);
  }

  static const String namespace = 'color';
}
