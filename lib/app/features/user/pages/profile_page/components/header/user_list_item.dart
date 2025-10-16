// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_items_loading_state/item_loading_state.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class UseListItem extends ConsumerWidget {
  const UseListItem({
    required this.pubkey,
    required this.minHeight,
    super.key,
  });

  final String pubkey;
  final double minHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPreviewResult = ref.watch(userPreviewDataProvider(pubkey));

    return userPreviewResult.maybeWhen(
      data: (userPreviewData) {
        if (userPreviewData == null) {
          return const SizedBox.shrink();
        }
        return BadgesUserListItem(
          title: Text(userPreviewData.data.trimmedDisplayName),
          subtitle: Text(
            prefixUsername(
              username: userPreviewData.data.name,
              context: context,
            ),
          ),
          masterPubkey: pubkey,
          constraints: BoxConstraints(maxHeight: minHeight, minHeight: minHeight),
        );
      },
      orElse: () => ItemLoadingState(
        itemHeight: minHeight,
      ),
    );
  }
}
