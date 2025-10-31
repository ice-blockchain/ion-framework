// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list_item.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';

class CreatorTokensList extends HookConsumerWidget {
  const CreatorTokensList({
    required this.pubkey,
    required this.tabType,
    super.key,
  });

  final String pubkey;
  final CreatorTokensTabType tabType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace followListProvider with creator tokens category provider
    // Using followeePubkeys as temporary mock data
    final items = ref.watch(followListProvider(pubkey)).valueOrNull?.masterPubkeys;

    if (items == null) {
      return const SliverToBoxAdapter(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0.s),
            child: const Text('No creator tokens found'),
          ),
        ),
      );
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final itemPubkey = items[index];
        return ScreenSideOffset.small(
          child: CreatorTokensListItem(
            key: ValueKey(itemPubkey),
            pubkey: itemPubkey,
          ),
        );
      },
    );
  }
}
