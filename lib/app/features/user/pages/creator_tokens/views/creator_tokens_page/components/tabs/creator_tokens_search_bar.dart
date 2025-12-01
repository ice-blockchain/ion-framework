// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/communities/providers/latest_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/providers/creator_tokens_search_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensSearchBar extends HookConsumerWidget {
  const CreatorTokensSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchActive = ref.watch(creatorTokensIsSearchActiveProvider);
    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();

    // Watch loading states from all token providers
    final latestTokensState = ref.watch(latestTokensNotifierProvider);
    final trendingTokensState =
        ref.watch(categoryTokensNotifierProvider(TokenCategoryType.trending));
    final topTokensState = ref.watch(categoryTokensNotifierProvider(TokenCategoryType.top));

    // Determine if any tab is loading during search
    final isLoading = isSearchActive &&
        (latestTokensState.activeIsLoading ||
            trendingTokensState.activeIsLoading ||
            topTokensState.activeIsLoading);

    if (!isSearchActive) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    useOnInit(
      () {
        // Clear search controller immediately (local state, safe during build)
        searchController.clear();
        // Clear search query when search is first activated to show empty results
        ref.read(creatorTokensSearchProvider.notifier).clearSearch();
        // Request focus after the frame is rendered to ensure the search bar is fully laid out
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNode.requestFocus();
        });
      },
      [isSearchActive],
    );

    return PinnedHeaderSliver(
      child: ColoredBox(
        color: context.theme.appColors.secondaryBackground,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            top: 12.s,
            bottom: 12.s,
            start: 16.s,
            end: 16.s,
          ),
          child: SearchInput(
            controller: searchController,
            loading: isLoading,
            onTextChanged: (value) {
              ref.read(creatorTokensSearchProvider.notifier).searchQuery = value;
            },
            onCancelSearch: () {
              searchController.clear();
              ref.read(creatorTokensSearchProvider.notifier).clearSearch();
              ref.read(creatorTokensIsSearchActiveProvider.notifier).isSearching = false;
            },
            focusNode: searchFocusNode,
          ),
        ),
      ),
    );
  }
}
