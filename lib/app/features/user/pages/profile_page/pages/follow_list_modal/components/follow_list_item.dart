// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/user/follow_user_button/follow_user_button.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/username.dart';

class FollowListItem extends ConsumerWidget {
  const FollowListItem({
    required this.pubkey,
    this.network = false,
    super.key,
  });

  final String pubkey;

  final bool network;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(pubkey, network: network)
          .select((value) => value.valueOrNull?.data.trimmedDisplayName ?? ''),
    );

    final username = ref.watch(
      userPreviewDataProvider(pubkey, network: network)
          .select((value) => value.valueOrNull?.data.name ?? ''),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: BadgesUserListItem(
        title: Text(
          displayName,
          strutStyle: const StrutStyle(forceStrutHeight: true),
        ),
        trailing: FollowUserButton(
          pubkey: pubkey,
        ),
        subtitle: Text(
          prefixUsername(
            username: username,
            context: context,
          ),
        ),
        masterPubkey: pubkey,
        onTap: () => context.pop(pubkey),
      ),
    );
  }
}
