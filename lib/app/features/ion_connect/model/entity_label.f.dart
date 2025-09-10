// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';

part 'entity_label.f.freezed.dart';

enum EntityLabelNamespace {
  language('ISO-639-1'),
  color('color');

  const EntityLabelNamespace(this.value);
  final String value;

  static EntityLabelNamespace? fromValue(String value) {
    return EntityLabelNamespace.values.firstWhereOrNull((e) => e.value == value);
  }
}

@freezed
class EntityLabel with _$EntityLabel {
  const factory EntityLabel({
    required List<String> values,
    required EntityLabelNamespace namespace,
  }) = _EntityLabel;

  const EntityLabel._();

  List<List<String>> toTags() {
    return [
      LabelNamespaceTag(namespace: namespace).toTag(),
      for (final value in values) LabelValueTag(value: value, namespace: namespace).toTag(),
    ];
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
      values: valueTags.map((valueTag) => valueTag.value).toList(),
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
    final namespaceTag =
        tags[tagName]?.firstWhereOrNull((tag) => tag.lastOrNull == namespace.value);
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
  }) = _LabelValueTag;

  const LabelValueTag._();

  factory LabelValueTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    final namespace = EntityLabelNamespace.fromValue(tag[2]);

    if (namespace == null) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return LabelValueTag(value: tag[1], namespace: namespace);
  }

  static List<LabelValueTag>? fromTags(
    Map<String, List<List<String>>> tags, {
    required EntityLabelNamespace namespace,
  }) {
    final namespaceTags = tags[tagName]?.where((tag) => tag.lastOrNull == namespace.value);
    return namespaceTags?.map(LabelValueTag.fromTag).toList();
  }

  static const String tagName = 'l';

  List<String> toTag() => [tagName, value, namespace.value];
}
