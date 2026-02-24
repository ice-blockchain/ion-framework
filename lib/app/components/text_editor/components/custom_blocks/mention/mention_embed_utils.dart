// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/mention/models/mention_embed_data.f.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';

const String mentionEmbedKey = 'mention';
const String mentionPrefix = '@';

/// Parses raw mention embed data from Quill into [MentionEmbedData].
/// Handles both formats: `{pubkey, username}` (edit mode) and
/// `{mention: {pubkey, username}}` (view mode).
MentionEmbedData? parseMentionEmbedData(dynamic data) {
  try {
    if (data is Map) {
      final unwrappedData =
          data.containsKey(mentionEmbedKey) && data.length == 1 ? data[mentionEmbedKey] : data;

      if (unwrappedData is Map) {
        return MentionEmbedData.fromJson(
          Map<String, dynamic>.from(unwrappedData),
        );
      }
    }
  } catch (_) {
    // Invalid data
  }
  return null;
}

// Navigates to the profile for pubkey, unless already there or on self-profile.
void navigateToMentionProfile(BuildContext context, WidgetRef ref, String pubkey) {
  final currentLocation = GoRouterState.of(context).uri.toString();
  final targetLocation = ProfileRoute(pubkey: pubkey).location;

  if (currentLocation == targetLocation) return;

  if (currentLocation == SelfProfileRoute().location) {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey == pubkey) return;
  }

  ProfileRoute(pubkey: pubkey).push<void>(context);
}
