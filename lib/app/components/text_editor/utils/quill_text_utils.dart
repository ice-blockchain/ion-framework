// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' show Attribute, Document;
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/features/feed/providers/content_conversion.dart';

class QuillTextUtils {
  /// Trims extra newlines at the end of the text,
  /// keeping only one to match Quill’s format.
  static String? trimDeltaJson(String? jsonDelta) {
    if (jsonDelta == null || jsonDelta.trim().isEmpty) return null;

    try {
      final raw = jsonDecode(jsonDelta);
      if (raw is! List) return jsonDelta;

      final doc = Document.fromJson(raw.cast<Map<String, dynamic>>());
      final plain = doc.toPlainText().trim();

      if (plain.isEmpty) return null;

      // Remove extra trailing newlines
      final ops = List<Map<String, dynamic>>.from(raw);
      if (ops.isNotEmpty) {
        final last = ops.last;
        final insert = last['insert'];
        if (insert is String && insert.contains('\n')) {
          last['insert'] = insert.replaceFirst(RegExp(r'\n+$'), '\n');
        }
      }

      return jsonEncode(ops);
    } catch (_) {
      return jsonDelta; // Fallback for invalid JSON
    }
  }

  /// Trims bio Delta JSON by collapsing all multiple newlines to single newlines.
  /// Bios only allow single line breaks, not multiple empty lines.
  static String? trimBioDeltaJson(String? jsonDelta) {
    if (jsonDelta == null || jsonDelta.trim().isEmpty) return null;

    try {
      final raw = jsonDecode(jsonDelta);
      if (raw is! List) return jsonDelta;

      final doc = Document.fromJson(raw.cast<Map<String, dynamic>>());
      final plain = doc.toPlainText();

      if (plain.trim().isEmpty) return null;

      final trimmedPlain = trimEmptyLines(plain, allowExtraLineBreak: false).trimmedText;

      if (trimmedPlain.isEmpty) return null;

      final textForDelta = trimmedPlain.endsWith('\n') ? trimmedPlain : '$trimmedPlain\n';
      final trimmedDelta = Delta()..insert(textForDelta);
      final trimmedDoc = Document.fromDelta(trimmedDelta);
      return jsonEncode(trimmedDoc.toDelta().toJson());
    } catch (_) {
      return jsonDelta;
    }
  }

  /// Converts bio Delta JSON to trimmed plain text for API submission.
  /// Bios only allow single line breaks, so all multiple newlines are collapsed to single.
  static String? bioDeltaJsonToTrimmedPlainText(String? jsonDelta) {
    final trimmedDeltaJson = trimBioDeltaJson(jsonDelta);
    if (trimmedDeltaJson == null) return null;

    try {
      final raw = jsonDecode(trimmedDeltaJson);
      if (raw is! List) return null;

      final doc = Document.fromJson(raw.cast<Map<String, dynamic>>());
      final plain = doc.toPlainText();

      // Remove trailing newline that Quill Document requires (added in trimBioDeltaJson)
      final trimmedPlain = plain.endsWith('\n') ? plain.substring(0, plain.length - 1) : plain;

      return trimmedPlain.isEmpty ? null : trimmedPlain;
    } catch (_) {
      return null;
    }
  }

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
