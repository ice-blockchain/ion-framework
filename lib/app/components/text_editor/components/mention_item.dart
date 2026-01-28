// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/market_cap_badge.dart';
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

    final marketCap = ref.watch(userTokenMarketCapProvider(pubkey));

    return BadgesUserListItem(
      onTap: () => onPress((pubkey: pubkey, username: username)),
      title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
      subtitle: Text(withPrefix(input: username, textDirection: Directionality.of(context))),
      masterPubkey: pubkey,
      trailing: marketCap != null ? MarketCapBadge(marketCap: marketCap) : null,
    );
  }
}
