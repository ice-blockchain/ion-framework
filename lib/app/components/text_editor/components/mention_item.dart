// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class MentionItem extends ConsumerWidget {
  const MentionItem({
    required this.pubkey,
    required this.onPress,
    super.key,
  });

  final String pubkey;
  final void Function(({String pubkey, String username})) onPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(pubkey, network: false).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(pubkey, network: false).select(userPreviewNameSelector),
    );

    return BadgesUserListItem(
      onTap: () => onPress((pubkey: pubkey, username: username)),
      title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
      subtitle: Text(prefixUsername(username: username, context: context)),
      masterPubkey: pubkey,
    );
  }
}
