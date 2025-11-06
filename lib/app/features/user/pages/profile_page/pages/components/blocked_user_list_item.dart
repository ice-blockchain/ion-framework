// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/components/block_user_button.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class BlockedUserListItem extends ConsumerWidget {
  const BlockedUserListItem({
    required this.pubkey,
    super.key,
  });

  final String pubkey;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(pubkey, network: false).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(pubkey, network: false).select(userPreviewNameSelector),
    );

    return BadgesUserListItem(
      title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
      trailing: BlockUserButton(masterPubkey: pubkey),
      subtitle: Text(prefixUsername(username: username, context: context)),
      masterPubkey: pubkey,
    );
  }
}
