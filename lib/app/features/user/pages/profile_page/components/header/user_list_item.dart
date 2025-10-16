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
    this.textColor,
    super.key,
  });

  final String pubkey;
  final double minHeight;
  final Color? textColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataResult = ref.watch(userMetadataProvider(pubkey));

    return userMetadataResult.maybeWhen(
      data: (userMetadata) {
        if (userMetadata == null) {
          return const SizedBox.shrink();
        }
        final textStyle = textColor != null ? TextStyle(color: textColor) : null;
        return BadgesUserListItem(
          title: Text(
            userMetadata.data.trimmedDisplayName,
            style: textStyle,
          ),
          subtitle: Text(
            prefixUsername(
              username: userMetadata.data.name,
              context: context,
            ),
            style: textStyle,
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
