// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart' show Attribute;
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';

class QuillTextUtils {
  static Delta truncateDelta(Delta original, int maxChars) {
    final truncated = Delta();
    var consumed = 0;
    for (final op in original.toList()) {
      final data = op.data;
      if (data is String) {
        if (consumed >= maxChars) break;
        final remaining = maxChars - consumed;
        if (data.length <= remaining) {
          truncated.push(op);
          consumed += data.length;
        } else {
          truncated.insert(data.substring(0, remaining), op.attributes);
          break;
        }
      } else {
        // preserve embeds until overflow
        if (consumed < maxChars) {
          truncated.push(op);
        }
      }
    }
    return truncated;
  }

  static final blockedInlineAttributeKeys = {
    MentionAttribute.attributeKey,
    HashtagAttribute.attributeKey,
    CashtagAttribute.attributeKey,
    Attribute.link.key,
  };

  /// Returns true if the range [rangeStart, rangeStart + rangeLength) overlaps
  /// any operation that carries at least one attribute whose key is in [attributeKeys].
  static bool rangeOverlapsOpsWithAttributes(
    List<Operation> ops,
    int rangeStart,
    int rangeLength,
  ) {
    var acc = 0;
    for (final op in ops) {
      final opLen = op.data is String ? (op.data! as String).length : 1;
      final opStart = acc;
      final opEnd = acc + opLen;
      final overlap = rangeStart < opEnd && (rangeStart + rangeLength) > opStart;
      if (overlap) {
        final attrs = op.attributes;
        if (attrs != null && attrs.keys.any(blockedInlineAttributeKeys.contains)) {
          return true;
        }
      }
      acc += opLen;
    }
    return false;
  }
}
