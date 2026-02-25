// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/attributes.dart';
import 'package:ion/app/components/text_editor/utils/mention_delta_converter.dart';
import 'package:ion/app/router/app_routes.gr.dart';

GestureRecognizer? customRecognizerBuilder(
  BuildContext context,
  Attribute<dynamic> attribute, {
  bool isEditing = false,
}) {
  if (attribute.key == HashtagAttribute.attributeKey) {
    return TapGestureRecognizer()
      ..onTap = isEditing
          ? null
          : () {
              FeedAdvancedSearchRoute(query: attribute.value as String).push<void>(context);
            };
  }
  if (attribute.key == CashtagAttribute.attributeKey) {
    return TapGestureRecognizer()
      ..onTap = isEditing
          ? null
          : () {
              final cashtagValue = (attribute.value as String).trim();

              final isTokenizedCashtag =
                  cashtagValue.isNotEmpty && cashtagValue != r'$' && !cashtagValue.startsWith(r'$');

              if (isTokenizedCashtag) {
                TokenizedCommunityRoute(externalAddress: cashtagValue).push<void>(context);
                return;
              }

              if (cashtagValue.startsWith(r'$') && cashtagValue.length > 1) {
                final ticker = cashtagValue.substring(1);
                FeedAdvancedSearchRoute(query: ticker.toUpperCase()).push<void>(context);
              }
            };
  }
  if (attribute.key == MentionAttribute.attributeKey) {
    return TapGestureRecognizer()
      ..onTap = isEditing
          ? null
          : () {
              final pubkey = MentionDeltaConverter.tryGetMentionPubkey(
                attribute.value as String,
              );
              if (pubkey != null) {
                ProfileRoute(pubkey: pubkey).push<void>(context);
              }
            };
  }
  return null;
}
