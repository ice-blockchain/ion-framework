// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/providers/feed_search_history_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/providers/user_token_market_cap_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/views/components/market_cap_badge.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FeedSimpleSearchListItem extends ConsumerWidget {
  const FeedSimpleSearchListItem({required this.masterPubkey, super.key});

  final String masterPubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(masterPubkey, network: false).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(masterPubkey, network: false).select(userPreviewNameSelector),
    );

    final marketCap = ref.watch(userTokenMarketCapProvider(masterPubkey));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(feedSearchHistoryProvider.notifier).addUserIdToTheHistory(masterPubkey);
        ProfileRoute(pubkey: masterPubkey).push<void>(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0.s),
        child: ScreenSideOffset.small(
          child: BadgesUserListItem(
            title: Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
            subtitle: Text(
              prefixUsername(
                input: username,
                textDirection: Directionality.of(context),
              ),
            ),
            masterPubkey: masterPubkey,
            trailing: marketCap != null ? MarketCapBadge(marketCap: marketCap) : null,
          ),
        ),
      ),
    );
  }
}
