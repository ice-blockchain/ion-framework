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
  /// Preserves all attributes (mentions, links, etc.) from the original delta.
  static String? trimBioDeltaJson(String? jsonDelta) {
    if (jsonDelta == null || jsonDelta.trim().isEmpty) return null;

    try {
      final raw = jsonDecode(jsonDelta);
      if (raw is! List) return jsonDelta;

      final delta = Delta.fromJson(raw.cast<Map<String, dynamic>>());
      final deltaInfo = _prepareDeltaForDocument(delta);
      final doc = Document.fromDelta(deltaInfo.deltaForDoc);
      final originalPlain = doc.toPlainText();
      final originalPlainLength = _getOriginalPlainLength(
        originalPlain,
        deltaInfo.needsTrailingNewline,
      );

      if (originalPlain.trim().isEmpty) return null;

      final collapseResult = _collapseWhitespaceOnlyLines(
        originalPlain,
        originalPlainLength,
      );
      final plain = collapseResult.modifiedPlain;
      final trimResult = trimEmptyLines(plain, allowExtraLineBreak: false);
      if (trimResult.trimmedText.isEmpty) return null;

      final keepMap = _buildKeepMap(
        collapseResult.positionMap,
        plain,
        trimResult.trimmedText,
        trimResult.adjustPosition,
        originalPlainLength,
      );

      final trimmedDelta = _rebuildDeltaWithAttributes(delta, keepMap);
      if (trimmedDelta == null) return null;

      final jsonOps = _ensureTrailingNewline(trimmedDelta);
      return jsonEncode(jsonOps);
    } catch (_) {
      return jsonDelta;
    }
  }

  static ({Delta deltaForDoc, bool needsTrailingNewline}) _prepareDeltaForDocument(
    Delta delta,
  ) {
    final deltaOps = delta.toList();
    final lastData = deltaOps.isEmpty ? null : deltaOps.last.data;
    final needsTrailingNewline =
        deltaOps.isEmpty || (lastData is String && !lastData.endsWith('\n'));

    var deltaForDoc = delta;
    if (needsTrailingNewline) {
      final tempDelta = Delta();
      for (final op in deltaOps) {
        tempDelta.push(op);
      }
      final lastOp = deltaOps.isNotEmpty ? deltaOps.last : null;
      tempDelta.insert('\n', lastOp?.attributes);
      deltaForDoc = tempDelta;
    }

    return (deltaForDoc: deltaForDoc, needsTrailingNewline: needsTrailingNewline);
  }

  static int _getOriginalPlainLength(
    String originalPlain,
    bool needsTrailingNewline,
  ) {
    return needsTrailingNewline && originalPlain.endsWith('\n')
        ? originalPlain.length - 1
        : originalPlain.length;
  }

  static ({
    Map<int, int?> positionMap,
    String modifiedPlain,
  }) _collapseWhitespaceOnlyLines(
    String originalPlain,
    int originalPlainLength,
  ) {
    final positionMap = <int, int?>{};
    final modifiedPlain = StringBuffer();
    var modifiedPos = 0;
    var i = 0;

    while (i < originalPlainLength) {
      // Check for pattern: \n[whitespace]+\n (whitespace-only line)
      if (i < originalPlainLength - 1 && originalPlain[i] == '\n') {
        var j = i + 1;
        // Skip whitespace
        while (j < originalPlainLength && (originalPlain[j] == ' ' || originalPlain[j] == '\t')) {
          j++;
        }
        // If next char is \n, we found a whitespace-only line
        if (j < originalPlainLength && originalPlain[j] == '\n') {
          // Keep the first \n
          positionMap[i] = modifiedPos;
          modifiedPlain.write('\n');
          modifiedPos++;
          // Mark whitespace positions as removed
          for (var k = i + 1; k < j; k++) {
            positionMap[k] = null;
          }
          // Now check if there are more consecutive whitespace-only lines
          var currentPos = j; // Position of the \n after whitespace
          while (currentPos < originalPlainLength) {
            // Map and add the \n
            positionMap[currentPos] = modifiedPos;
            modifiedPlain.write('\n');
            modifiedPos++;

            // Check if there's another whitespace-only line after this
            var nextJ = currentPos + 1;
            // Skip whitespace
            while (nextJ < originalPlainLength &&
                (originalPlain[nextJ] == ' ' || originalPlain[nextJ] == '\t')) {
              nextJ++;
            }
            // If next char is \n, we have another whitespace-only line
            if (nextJ < originalPlainLength && originalPlain[nextJ] == '\n') {
              // Mark whitespace as removed
              for (var k = currentPos + 1; k < nextJ; k++) {
                positionMap[k] = null;
              }
              currentPos = nextJ; // Move to the \n
            } else {
              break; // No more consecutive whitespace-only lines
            }
          }
          i = currentPos + 1; // Continue after the last \n
          continue;
        }
      }

      // Normal character - keep it
      positionMap[i] = modifiedPos;
      modifiedPlain.write(originalPlain[i]);
      modifiedPos++;
      i++;
    }

    return (
      positionMap: positionMap,
      modifiedPlain: modifiedPlain.toString(),
    );
  }

  static Map<int, bool> _buildKeepMap(
    Map<int, int?> positionMap,
    String modifiedPlain,
    String trimmedPlain,
    int Function(int) adjustPosition,
    int originalPlainLength,
  ) {
    final keepMap = <int, bool>{};

    // Build a map: modified position -> is kept
    // A character is kept if its adjusted position advances from the previous position
    // AND if the character at that position matches trimmedPlain
    final modifiedKeepMap = <int, bool>{};
    var prevAdjPos = -1;
    for (var modPos = 0; modPos < modifiedPlain.length; modPos++) {
      final adjPos = adjustPosition(modPos);
      if (adjPos != prevAdjPos) {
        // Adjusted position advanced - this character might be kept
        // Check if the character matches what's in trimmedPlain at adjPos
        if (adjPos < trimmedPlain.length && modifiedPlain[modPos] == trimmedPlain[adjPos]) {
          modifiedKeepMap[modPos] = true;
          prevAdjPos = adjPos;
        } else {
          // Character doesn't match - it was removed (leading/trailing newline)
          modifiedKeepMap[modPos] = false;
        }
      } else {
        // Same adjusted position as previous - this character was collapsed/removed
        modifiedKeepMap[modPos] = false;
      }
    }

    // Now map back to original positions (excluding temporary newline if added)
    var lastAdjustedPos = -1;
    for (var origPos = 0; origPos < originalPlainLength; origPos++) {
      final modifiedPos = positionMap[origPos];
      if (modifiedPos == null) {
        // This position was removed (whitespace in whitespace-only line)
        keepMap[origPos] = false;
      } else {
        // Check if this modified position was kept
        final isKept = modifiedKeepMap[modifiedPos] ?? false;
        if (isKept) {
          final adjustedPos = adjustPosition(modifiedPos);
          // Character is kept if its adjusted position is different from previous
          keepMap[origPos] = adjustedPos != lastAdjustedPos;
          if (keepMap[origPos]!) {
            lastAdjustedPos = adjustedPos;
          }
        } else {
          keepMap[origPos] = false;
        }
      }
    }

    return keepMap;
  }

  static Delta? _rebuildDeltaWithAttributes(
    Delta delta,
    Map<int, bool> keepMap,
  ) {
    final trimmedDelta = Delta();
    var plainPos = 0; // Position in original plain text

    for (final op in delta.toList()) {
      final data = op.data;
      if (data is String) {
        final buffer = StringBuffer();
        for (var i = 0; i < data.length; i++) {
          final charPos = plainPos + i;
          if (keepMap[charPos] ?? false) {
            buffer.write(data[i]);
          }
        }

        final trimmedText = buffer.toString();
        if (trimmedText.isNotEmpty) {
          trimmedDelta.insert(trimmedText, op.attributes);
        }

        plainPos += data.length;
      } else {
        // For embeds, keep if their position is kept
        if (keepMap[plainPos] ?? false) {
          trimmedDelta.push(op);
        }
        plainPos += 1; // Embeds count as 1 character
      }
    }

    final trimmedOps = trimmedDelta.toList();
    if (trimmedOps.isEmpty) return null;

    final lastOp = trimmedOps.last;
    final lastOpData = lastOp.data;
    final lastText = lastOpData is String ? lastOpData : '';

    // Ensure trailing newline for Quill format
    // Add newline as separate operation if missing
    if (!lastText.endsWith('\n')) {
      // If last operation has attributes, add newline as separate operation without attributes
      // Otherwise, add newline to the last operation
      if (lastOp.attributes != null && lastOp.attributes!.isNotEmpty) {
        trimmedDelta.insert('\n');
      } else {
        trimmedDelta.insert('\n', lastOp.attributes);
      }
    }

    return trimmedDelta;
  }

  static List<Map<String, dynamic>> _ensureTrailingNewline(Delta trimmedDelta) {
    final finalDoc = Document.fromDelta(trimmedDelta);
    final finalDeltaOps = finalDoc.toDelta().toList();

    // Convert to JSON
    final jsonOps = finalDeltaOps.map((op) => op.toJson()).toList();

    // Always ensure last operation ends with newline (Quill requirement)
    // Check the actual JSON, not the operations, to be sure
    if (jsonOps.isNotEmpty) {
      final lastOpJson = jsonOps.last;
      final lastInsert = lastOpJson['insert'];
      final lastAttributes = lastOpJson['attributes'] as Map<String, dynamic>?;
      if (lastInsert is String && !lastInsert.endsWith('\n')) {
        // If last operation has attributes, add newline as separate operation
        // Otherwise, modify the last operation to include newline
        if (lastAttributes != null && lastAttributes.isNotEmpty) {
          jsonOps.add({'insert': '\n'});
        } else {
          final newLastOp = Map<String, dynamic>.from(lastOpJson);
          newLastOp['insert'] = '$lastInsert\n';
          jsonOps[jsonOps.length - 1] = newLastOp;
        }
      } else if (lastInsert is! String) {
        // Last op is not a string (embed), add newline as separate op
        jsonOps.add({'insert': '\n'});
      }
    } else {
      // Empty ops, add just a newline
      jsonOps.add({'insert': '\n'});
    }

    // Verify the JSON is valid by trying to parse it
    final jsonString = jsonEncode(jsonOps);
    final testDoc = Document.fromJson(jsonDecode(jsonString) as List);
    final testPlain = testDoc.toPlainText();
    if (!testPlain.endsWith('\n')) {
      // If still doesn't end with newline, force it
      final testOps = jsonDecode(jsonString) as List;
      if (testOps.isNotEmpty) {
        final lastTestOp = testOps.last as Map<String, dynamic>;
        final lastTestAttributes = lastTestOp['attributes'] as Map<String, dynamic>?;
        if (lastTestOp['insert'] is String) {
          // If last operation has attributes, add newline as separate operation
          // Otherwise, modify the last operation
          if (lastTestAttributes != null && lastTestAttributes.isNotEmpty) {
            testOps.add({'insert': '\n'});
          } else {
            lastTestOp['insert'] = '${lastTestOp['insert']}\n';
          }
          return testOps.cast<Map<String, dynamic>>();
        }
      }
    }

    return jsonOps;
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
