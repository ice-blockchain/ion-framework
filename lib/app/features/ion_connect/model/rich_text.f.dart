// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/pmo_tag.f.dart';
import 'package:ion/app/services/markdown/delta_markdown_converter.dart';

part 'rich_text.f.freezed.dart';

@freezed
class RichText with _$RichText {
  const factory RichText({
    required String protocol,
    required String content,
  }) = _RichText;

  const RichText._();

  factory RichText.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length < 3) {
      throw IncorrectEventTagException(tag: tag.toString());
    }
    return RichText(protocol: tag[1], content: tag[2]);
  }

  List<String> toTag() {
    return [tagName, protocol, content];
  }

  static const String tagName = 'rich_text';

  /// Reconstructs richText from event message tags.
  ///
  /// Returns the richText Delta if present, otherwise reconstructs from PMO tags.
  static RichText? fromEventTags(
    Map<String, List<List<String>>> tags,
    String content,
  ) {
    // Check for richText first (prefer existing Delta)
    if (tags[tagName] != null) {
      return RichText.fromTag(tags[tagName]!.first);
    }

    // No richText Delta, check for PMO tags to reconstruct Delta
    final pmoTags = tags[PmoTag.tagName];
    if (pmoTags == null || pmoTags.isEmpty) {
      return null;
    }

    // Map markdown (via PMO tags) to Delta
    final reconstructedDelta = DeltaMarkdownConverter.mapMarkdownToDelta(
      content,
      pmoTags,
    );
    return RichText(
      protocol: 'quill_delta',
      content: jsonEncode(reconstructedDelta.toJson()),
    );
  }
}
