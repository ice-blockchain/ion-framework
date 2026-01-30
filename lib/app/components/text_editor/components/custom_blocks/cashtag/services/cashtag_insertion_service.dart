// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/models/cashtag_embed_data.f.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/cashtag/text_editor_cashtag_embed_builder.dart';

/// Service for inserting cashtag embeds into Quill documents.
class CashtagInsertionService {
  CashtagInsertionService._();

  static int insertCashtag(
    QuillController controller,
    int tagStart,
    int tagLength,
    CashtagEmbedData cashtagData,
  ) {
    final cashtagWithId = cashtagData.copyWith(
      id: DateTime.now().toString(),
    );

    final embedData = cashtagWithId.toJson();

    // After: embed (1) + space (1) = tagStart + 2
    final newCursorPosition = tagStart + 2;

    controller
      ..replaceText(
        tagStart,
        tagLength,
        '',
        TextSelection.collapsed(offset: tagStart),
      )
      ..replaceText(
        tagStart,
        0,
        Embeddable(cashtagEmbedKey, embedData),
        TextSelection.collapsed(offset: tagStart + 1),
      )
      ..replaceText(
        tagStart + 1,
        0,
        ' ',
        TextSelection.collapsed(offset: newCursorPosition),
      );

    return newCursorPosition;
  }

  static void downgradeCashtagEmbedToText(
    QuillController controller,
    int embedPosition,
    CashtagEmbedData cashtagData, {
    bool showMarketCap = true,
  }) {
    if (embedPosition < 0 || embedPosition >= controller.document.length) {
      return;
    }

    final cashtagText = r'$' + cashtagData.symbolGroup;

    // Preserve author's intent:
    // - showMarketCap=true: keep externalAddress in the attribute so it can upgrade back.
    // - showMarketCap=false: downgrade to plain cashtag (no market cap) and persist choice.
    final attributes = <String, dynamic>{
      CashtagAttribute.attributeKey: showMarketCap ? cashtagData.externalAddress : r'$',
      if (showMarketCap) CashtagAttribute.showMarketCapKey: true,
      if (!showMarketCap) CashtagAttribute.showMarketCapKey: false,
    };

    final replaceDelta = Delta()
      ..retain(embedPosition)
      ..delete(1)
      ..insert(cashtagText, attributes);

    controller.compose(
      replaceDelta,
      TextSelection.collapsed(offset: embedPosition + cashtagText.length),
      ChangeSource.local,
    );
  }

  // Replaces the text cashtag (with cashtag attribute) with an embed widget.
  // Validates document state and text match before replacing.
  static void upgradeCashtagToEmbed(
    QuillController controller,
    int start,
    int cashtagTextLength,
    CashtagEmbedData cashtagData,
    double marketCap,
  ) {
    // Keep signature aligned with mention upgrade flow; marketCap is used by the UI widget.
    // This service only replaces document ops.
    // ignore: unused_local_variable
    final unusedMarketCap = marketCap;

    final end = start + cashtagTextLength;
    if (start < 0 || end > controller.document.length) {
      return;
    }

    // Verify text matches before replacing (prevents replacing wrong text if document was edited)
    final documentText = controller.document.toPlainText();
    final textAtPosition = documentText.substring(start, end);
    if (textAtPosition != r'$' + cashtagData.symbolGroup) {
      return;
    }

    // Generate unique ID if not present (ephemeral, not saved to Nostr)
    final cashtagWithId =
        cashtagData.id == null ? cashtagData.copyWith(id: DateTime.now().toString()) : cashtagData;

    controller
      ..replaceText(start, cashtagTextLength, '', null)
      ..replaceText(
        start,
        0,
        Embeddable(cashtagEmbedKey, cashtagWithId.toJson()),
        null,
      );
  }

  static void removeCashtagEmbed(
    QuillController controller,
    Embed embedNode,
  ) {
    final nodeData = _parseCashtagDataFromNode(embedNode.value.data);
    if (nodeData == null) return;

    final embedOffset = _findEmbedOffsetInDelta(
      controller.document.toDelta(),
      nodeData,
    );

    if (embedOffset != -1) {
      // Persist author's choice to NOT display with market cap.
      downgradeCashtagEmbedToText(
        controller,
        embedOffset,
        nodeData,
        showMarketCap: false,
      );
    }
  }

  static CashtagEmbedData? _parseCashtagDataFromNode(dynamic nodeData) {
    if (nodeData is! Map) return null;

    final map = Map<String, dynamic>.from(nodeData);
    final data = (map.containsKey(cashtagEmbedKey) && map.length == 1)
        ? Map<String, dynamic>.from(map[cashtagEmbedKey] as Map)
        : map;

    try {
      return CashtagEmbedData.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  static int _findEmbedOffsetInDelta(Delta delta, CashtagEmbedData target) {
    var currentIndex = 0;

    for (final op in delta.operations) {
      final length = op.length ?? 1;

      if (op.isInsert && op.data is Map<String, dynamic>) {
        final data = op.data! as Map<String, dynamic>;
        if (data.containsKey(cashtagEmbedKey)) {
          try {
            final opData = CashtagEmbedData.fromJson(
              Map<String, dynamic>.from(data[cashtagEmbedKey] as Map),
            );

            if (opData.id != null && target.id != null && opData.id == target.id) {
              return currentIndex;
            }
          } catch (_) {
            // Ignore malformed embeds.
          }
        }
      }

      currentIndex += length;
    }

    return -1;
  }
}
