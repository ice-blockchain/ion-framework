// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_items_loading_state/item_loading_state.dart';
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
    final userMetadataResult = ref.watch(userMetadataProvider(pubkey));

    return userMetadataResult.maybeWhen(
      data: (userMetadata) {
        if (userMetadata == null) {
          return const SizedBox.shrink();
        }
        return BadgesUserListItem(
          title: Text(userMetadata.data.displayName),
          trailing: BlockUserButton(masterPubkey: pubkey),
          subtitle: Text(
            prefixUsername(
              username: userMetadata.data.name,
              context: context,
            ),
          ),
          masterPubkey: pubkey,
        );
      },
      orElse: () => ItemLoadingState(itemHeight: itemHeight),
    );
  }
}
