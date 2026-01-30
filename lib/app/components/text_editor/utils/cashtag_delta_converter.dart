// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/models/cashtag_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/text_editor_cashtag_embed_builder.dart';

class CashtagDeltaConverter {
  CashtagDeltaConverter._();

  // Converts cashtag embeds to text with cashtag attributes for persistence.
  // Example: {'cashtag': {'symbolGroup': 'fantastic', 'externalAddress': '0:...'}}
  //   -> '$fantastic' with cashtag attribute + showMarketCap=true.
  static Delta convertEmbedsToAttributes(Delta input) {
    final out = Delta();
    final ops = input.toList();

    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      final data = op.data;
      final attrs = op.attributes;

      final unwrappedData = _unwrapEmbedData(data);
      final cashtagData = _parseCashtagData(unwrappedData);

      // Only process pure embed ops (length == 1) to avoid capturing adjacent characters.
      if (cashtagData != null && (op.length ?? 1) == 1) {
        final cashtagText = r'$' + cashtagData.symbolGroup;

        final mergedAttrs = {
          ...?attrs,
          // Store externalAddress as the cashtag attribute value so we can restore the embed
          // without needing async DB lookups.
          CashtagAttribute.attributeKey: cashtagData.externalAddress,
          CashtagAttribute.showMarketCapKey: true,
        };

        out.insert(cashtagText, mergedAttrs);

        // Insert zero-width space in case if there's a next operation with content
        // to prevent merging.
        if (i + 1 < ops.length &&
            ops[i + 1].data is String &&
            (ops[i + 1].data! as String).trim().isNotEmpty) {
          out.insert('\u200B');
        }
      } else {
        out.push(op);
      }
    }

    return out;
  }

  // Converts cashtag attributes to embed operations for editor/preview rendering.
  // Only converts if author chose to display with market cap (showMarketCap == true)
  // AND we have a resolvable externalAddress (stored in the cashtag attribute value).
  static Delta convertAttributesToEmbeds(Delta input) {
    final out = Delta();

    for (final op in input.toList()) {
      final attrs = op.attributes;
      final data = op.data;

      // Skip zero-width space separator (structural only, not content)
      if (data is String && data == '\u200B') {
        continue;
      }

      final cashtagAttr = attrs?[CashtagAttribute.attributeKey];
      if (cashtagAttr is String && data is String && data.startsWith(r'$')) {
        final showMarketCap = attrs?[CashtagAttribute.showMarketCapKey] == true;
        final symbolGroup = data.substring(1);

        // We store externalAddress in the cashtag attribute value when showMarketCap is enabled.
        final externalAddress =
            (cashtagAttr.trim().isEmpty || cashtagAttr == r'$') ? null : cashtagAttr.trim();

        if (showMarketCap && externalAddress != null) {
          final cashtagData = CashtagEmbedData(
            symbolGroup: symbolGroup,
            externalAddress: externalAddress,
            id: DateTime.now().toString(),
          );
          out.insert({cashtagEmbedKey: cashtagData.toJson()});
        } else {
          out.push(op);
        }
      } else if (data is Map && data.containsKey(cashtagEmbedKey)) {
        // Already an embed, keep as-is.
        out.push(op);
      } else {
        out.push(op);
      }
    }

    return out;
  }

  static dynamic _unwrapEmbedData(dynamic data) {
    if (data is Map && data.containsKey(cashtagEmbedKey) && data.length == 1) {
      return data[cashtagEmbedKey];
    }
    return data;
  }

  static CashtagEmbedData? _parseCashtagData(dynamic data) {
    try {
      if (data is Map) {
        return CashtagEmbedData.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Invalid data
    }
    return null;
  }
}
