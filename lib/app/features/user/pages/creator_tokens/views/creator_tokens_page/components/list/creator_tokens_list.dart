// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/nothing_is_found/nothing_is_found.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list_item.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list_skeleton.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensList extends StatelessWidget {
  const CreatorTokensList({
    required this.items,
    required this.isInitialLoading,
    super.key,
  });

  final List<CommunityToken> items;
  final bool isInitialLoading;

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading && items.isEmpty) {
      return const SliverToBoxAdapter(
        child: CreatorTokensListSkeleton(),
      );
    }

    if (items.isEmpty) {
      return const NothingIsFound();
    }

    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final token = items[index];
        return ScreenSideOffset.small(
          child: CreatorTokensListItem(
            index: index,
            key: ValueKey(token.externalAddress),
            token: token,
          ),
        );
      },
    );
  }
}
