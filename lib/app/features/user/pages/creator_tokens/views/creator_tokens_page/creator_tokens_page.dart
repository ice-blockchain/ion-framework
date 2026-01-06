// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/featured_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/global_search_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/latest_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/creator_tokens_body.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/creator_tokens_header.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/creator_tokens_search_bar.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/filter/creator_tokens_filter_bar.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensPage extends HookConsumerWidget {
  const CreatorTokensPage({
    super.key,
  });

  static final _tabBarHeight = 54.0.s;

  static final _expandedHeaderHeight = 369.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final globalSearchNotifier = ref.watch(globalSearchTokensNotifierProvider.notifier);

    final searchController = useTextEditingController();
    final searchFocusNode = useFocusNode();
    final searchFocused = useNodeFocused(searchFocusNode);
    final searchQuery = useState('');
    final debouncedQuery = useDebounced(searchQuery.value, const Duration(milliseconds: 300)) ?? '';

    useEffect(
      () {
        void listener() => searchQuery.value = searchController.text;
        searchController.addListener(listener);

        return () => searchController.removeListener(listener);
      },
      [searchController],
    );

    final maxScroll = _expandedHeaderHeight -
        NavigationAppBar.screenHeaderHeight -
        _tabBarHeight -
        MediaQuery.paddingOf(context).top;

    final isGlobalSearchVisible = useState<bool>(false);
    final lastSearchQuery = useRef<String?>(null);

    // Collapse header when search field is focused
    useOnInit(
      () {
        if (searchFocused.value) {
          if (scrollController.hasClients) {
            final currentOffset = scrollController.offset;
            final targetOffset = maxScroll;

            // Only scroll if not already collapsed (or close to collapsed)
            if (currentOffset < targetOffset - 5) {
              scrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          }
        }
      },
      [searchFocused.value],
    );

    void resetGlobalSearch() {
      searchFocusNode.unfocus();
      searchController.clear();
      searchQuery.value = '';
      lastSearchQuery.value = null;
      globalSearchNotifier.search(
        query: '',
      );
    }

    final (:opacity) = useAnimatedOpacityOnScroll(
      scrollController,
      topOffset: maxScroll,
    );

    useEffect(
      () {
        return () {
          if (context.mounted) {
            ref
              ..invalidate(latestTokensNotifierProvider)
              ..invalidate(CategoryTokensNotifierProvider(TokenCategoryType.trending))
              ..invalidate(CategoryTokensNotifierProvider(TokenCategoryType.top));
          }
        };
      },
      [],
    );

    // Get featured tokens
    final featuredTokensAsync = ref.watch(featuredTokensProvider);
    final featuredTokens = featuredTokensAsync.valueOrNull ?? <CommunityToken>[];

    useOnInit(
      () {
        if (!isGlobalSearchVisible.value) return;
        if (debouncedQuery == lastSearchQuery.value) return;
        lastSearchQuery.value = debouncedQuery;
        globalSearchNotifier.search(
          query: debouncedQuery,
        );
      },
      [debouncedQuery, isGlobalSearchVisible.value],
    );

    // Create stable identifier for the list (to avoid unnecessary useEffect triggers)
    final tokensIdentifier = featuredTokens.map((t) => t.addresses.ionConnect).join(',');

    final initialToken = featuredTokens.isNotEmpty ? featuredTokens.first : null;
    final selectedToken = useState<CommunityToken?>(initialToken);

    // Update selectedToken when featuredTokens list actually changes
    useOnInit(
      () {
        if (featuredTokens.isNotEmpty) {
          // If no token is selected, or selected token is no longer in the list, select first
          if (selectedToken.value == null ||
              !featuredTokens.any(
                (t) => t.addresses.ionConnect == selectedToken.value!.addresses.ionConnect,
              )) {
            selectedToken.value = featuredTokens.first;
          }
        } else {
          // If list becomes empty, clear selection to avoid showing stale data
          selectedToken.value = null;
        }
      },
      [tokensIdentifier],
    );

    // Get avatar URL from selected token's creator
    final avatarUrl = selectedToken.value?.creator.avatar ?? '';
    final avatarColors = useImageColors(avatarUrl);

    final backgroundColor = context.theme.appColors.secondaryBackground;

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
      color: context.theme.appColors.onPrimaryAccent,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: KeyboardDismissOnTap(
        child: ScrollToTopWrapper(
          scrollController: scrollController,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              DefaultTabController(
                length: CreatorTokensTabType.values.length,
                child: NestedScrollView(
                  controller: scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      CreatorTokensHeader(
                        expandedHeight: _expandedHeaderHeight - MediaQuery.paddingOf(context).top,
                        tabBarHeight: _tabBarHeight,
                        opacity: opacity,
                        featuredTokensAsync: featuredTokensAsync,
                        selectedToken: selectedToken,
                        avatarColors: avatarColors,
                        backButtonIcon: backButtonIcon,
                        scrollController: scrollController,
                        onPop: context.pop,
                        onSearchToggle: () {
                          final nextVisible = !isGlobalSearchVisible.value;
                          isGlobalSearchVisible.value = nextVisible;
                          if (!nextVisible) {
                            resetGlobalSearch();
                          }
                        },
                      ),
                      const SliverToBoxAdapter(
                        child: SectionSeparator(),
                      ),
                      SliverToBoxAdapter(
                        child: CreatorTokensFilterBar(
                          scrollController: scrollController,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SectionSeparator(),
                      ),
                      CreatorTokensSearchBar(
                        isVisible: isGlobalSearchVisible.value,
                        searchController: searchController,
                        searchFocusNode: searchFocusNode,
                        onCancelSearch: () {
                          resetGlobalSearch();
                          isGlobalSearchVisible.value = false;
                        },
                      ),
                    ];
                  },
                  body: CreatorTokensBody(
                    searchQuery: searchQuery.value,
                    isGlobalSearchVisible: isGlobalSearchVisible.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
