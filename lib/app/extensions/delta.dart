// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/utils/is_attributed_operation.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

// General-purpose Delta extension for common operations
extension DeltaExt on Delta {
  bool get isSingleLinkOnly {
    return operations.length == 2 &&
        isAttributedOperation(operations.first, attribute: Attribute.link) &&
        operations.last.data == '\n';
  }

  bool get isBlank {
    if (isEmpty) return true;

    return operations.every((op) {
      final attrs = op.attributes;
      if (attrs != null &&
          (attrs.containsKey(Attribute.link.key) ||
              attrs.containsKey('text-editor-single-image'))) {
        return false;
      }
      return op.data.toString().trim().isEmpty;
    });
  }

  Delta get blank => isBlank ? this : Delta()
    ..insert('\n');
}

extension MentionDeltaExt on Delta {
  // Extracts only pubkeys from mentions (without flags)
  List<String> extractMentionPubkeys() {
    return extractMentionsWithFlags().map((m) => m.pubkey).toList();
  }

  // Extracts mention data including pubkey and showMarketCap flag
  List<({String pubkey, bool showMarketCap})> extractMentionsWithFlags() {
    final mentions = <({String pubkey, bool showMarketCap})>[];
    for (final op in operations) {
      if (op.key == 'insert') {
        final attrs = op.attributes;
        if (attrs != null && attrs.containsKey(MentionAttribute.attributeKey)) {
          final encodedRef = attrs[MentionAttribute.attributeKey] as String;
          final eventReference = EventReference.fromEncoded(encodedRef);
          final showMarketCap = attrs[MentionAttribute.showMarketCapKey] == true;

          mentions.add(
            (
              pubkey: eventReference.masterPubkey,
              showMarketCap: showMarketCap,
            ),
          );
        }
      }
    }
    return mentions;
  }
}
