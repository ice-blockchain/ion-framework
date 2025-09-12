// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_items_loading_state/item_loading_state.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class UserPaymentFlowCard extends ConsumerWidget {
  const UserPaymentFlowCard({
    required this.pubkey,
    this.onTap,
    super.key,
  });

  final String pubkey;
  final VoidCallback? onTap;

  static double get itemHeight => 58.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataResult = ref.watch(userMetadataProvider(pubkey));

    return userMetadataResult.maybeWhen(
      data: (userMetadata) {
        if (userMetadata == null) {
          return const SizedBox.shrink();
        }
        return BadgesUserListItem(
          onTap: onTap,
          title: Text(userMetadata.data.displayName),
          subtitle: Text(prefixUsername(username: userMetadata.data.name, context: context)),
          masterPubkey: pubkey,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 8.0.s),
          border: Border.all(
            color: context.theme.appColors.strokeElements,
          ),
          borderRadius: BorderRadius.circular(16.0.s),
          constraints: BoxConstraints(minHeight: itemHeight),
        );
      },
      orElse: () => ItemLoadingState(
        itemHeight: itemHeight,
      ),
    );
  }
}
