// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list_item.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensList extends HookConsumerWidget {
  const CreatorTokensList({
    required this.pubkey,
    required this.tabType,
    super.key,
  });

  final String pubkey;
  final CreatorTokensTabType tabType;

  TokenCategoryType? get _categoryType {
    return switch (tabType) {
      CreatorTokensTabType.trending => TokenCategoryType.trending,
      CreatorTokensTabType.top => TokenCategoryType.top,
      CreatorTokensTabType.latest => null,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryType = _categoryType;

    if (categoryType == null) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Text('Latest category not yet implemented'),
        ),
      );
    }

    final state = ref.watch(categoryTokensNotifierProvider(categoryType));
    final items = state.browsingItems;
    final isInitialLoading = state.browsingIsInitialLoading;

    if (isInitialLoading && items.isEmpty) {
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
        final token = items[index];
        return ScreenSideOffset.small(
          child: CreatorTokensListItem(
            key: ValueKey(token.addresses.ionConnect),
            token: token,
          ),
        );
      },
    );
  }
}
