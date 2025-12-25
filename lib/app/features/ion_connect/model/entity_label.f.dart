// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'entity_label.f.freezed.dart';

enum EntityLabelNamespace {
  language('ISO-639-1'),
  color('color'),
  ugcSerial('ugc.serial'),
  mentionMarketCap('community.token.marketcap.show');

  const EntityLabelNamespace(this.value);
  final String value;

  static EntityLabelNamespace? fromValue(String value) {
    return EntityLabelNamespace.values.firstWhereOrNull((e) => e.value == value);
  }
}

@freezed
class LabelValue with _$LabelValue {
  const factory LabelValue({
    required String value,
    @Default([]) List<String> additionalElements,
  }) = _LabelValue;
}

@freezed
class EntityLabel with _$EntityLabel {
  const factory EntityLabel({
    required List<LabelValue> values,
    required EntityLabelNamespace namespace,
  }) = _EntityLabel;

  const EntityLabel._();

  // Generates NIP-32 label tags: ['L', namespace], ['l', value, namespace, ...additionalElements]
  List<List<String>> toTags() {
    return [
      LabelNamespaceTag(namespace: namespace).toTag(),
      for (final labelValue in values)
        LabelValueTag(
          value: labelValue.value,
          namespace: namespace,
          additionalElements:
              labelValue.additionalElements.isNotEmpty ? labelValue.additionalElements : null,
        ).toTag(),
    ];
  }

  Map<String, List<List<String>>> toFilterTags() {
    return {
      '#${LabelValueTag.tagName}':
          values.map((labelValue) => [labelValue.value, namespace.value]).toList(),
    };
  }

  static EntityLabel? fromTags(
    Map<String, List<List<String>>> tags, {
    required EntityLabelNamespace namespace,
  }) {
    final namespaceTag = LabelNamespaceTag.fromTags(tags, namespace: namespace);

    if (namespaceTag == null) return null;

    final valueTags = LabelValueTag.fromTags(tags, namespace: namespace);

    if (valueTags == null) {
      throw IncorrectEventTagException(tag: tags);
    }

    return EntityLabel(
      values: valueTags
          .map(
            (valueTag) => LabelValue(
              value: valueTag.value,
              additionalElements: valueTag.additionalElements ?? [],
            ),
          )
          .toList(),
      namespace: namespace,
    );
  }
}

@freezed
class LabelNamespaceTag with _$LabelNamespaceTag {
  const factory LabelNamespaceTag({
    required EntityLabelNamespace namespace,
  }) = _LabelNamespaceTag;

  const LabelNamespaceTag._();

  factory LabelNamespaceTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    final namespace = EntityLabelNamespace.fromValue(tag[1]);

    if (namespace == null) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return LabelNamespaceTag(namespace: namespace);
  }

  static LabelNamespaceTag? fromTags(
    Map<String, List<List<String>>> tags, {
    required EntityLabelNamespace namespace,
  }) {
    // LabelNamespaceTag structure: ['L', 'namespace'], namespace is at index 1
    final namespaceTag =
        tags[tagName]?.firstWhereOrNull((tag) => tag.length == 2 && tag[1] == namespace.value);
    return namespaceTag != null ? LabelNamespaceTag.fromTag(namespaceTag) : null;
  }

  static const String tagName = 'L';

  List<String> toTag() => [tagName, namespace.value];
}

@freezed
class LabelValueTag with _$LabelValueTag {
  const factory LabelValueTag({
    required String value,
    required EntityLabelNamespace namespace,
    // Optional additional tag elements beyond the standard 3 (e.g., ['l', value, namespace, extra1, extra2, ...])
    List<String>? additionalElements,
  }) = _LabelValueTag;

  const LabelValueTag._();

  factory LabelValueTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    // Minimum 3 elements required; 4+ elements allowed for additional data (NIP-32 compliant)
    if (tag.length < 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    final namespace = EntityLabelNamespace.fromValue(tag[2]);

    if (namespace == null) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return LabelValueTag(
      value: tag[1],
      namespace: namespace,
      additionalElements: tag.length > 3 ? tag.sublist(3) : null,
    );
  }

  static List<LabelValueTag>? fromTags(
    Map<String, List<List<String>>> tags, {
    required EntityLabelNamespace namespace,
  }) {
    // Namespace is always at index 2
    final namespaceTags =
        tags[tagName]?.where((tag) => tag.length >= 3 && tag[2] == namespace.value);
    return namespaceTags?.map(LabelValueTag.fromTag).toList();
  }

  static const String tagName = 'l';

  List<String> toTag() {
    return [
      tagName,
      value,
      namespace.value,
      if (additionalElements != null) ...additionalElements!,
    ];
  }
}
