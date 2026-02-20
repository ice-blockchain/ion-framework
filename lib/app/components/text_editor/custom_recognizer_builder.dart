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
              // Remove $ sign and pass pure ticker
              final ticker = (attribute.value as String).substring(1);
              FeedAdvancedSearchRoute(query: ticker.toUpperCase()).push<void>(context);
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
