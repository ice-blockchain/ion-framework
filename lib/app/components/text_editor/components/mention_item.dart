// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
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
    final userPreviewData = ref.watch(userPreviewDataProvider(pubkey)).valueOrNull;

    if (userPreviewData == null) {
      return const Skeleton(child: ListItemUserShape());
    }

    final username = prefixUsername(username: userPreviewData.data.name, context: context);
    return BadgesUserListItem(
      onTap: () => onPress((pubkey: pubkey, username: username)),
      title: Text(userPreviewData.data.displayName),
      subtitle: Text(username),
      masterPubkey: pubkey,
    );
  }
}
