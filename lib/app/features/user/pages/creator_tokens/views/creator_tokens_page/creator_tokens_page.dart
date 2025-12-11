// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/scroll_view/load_more_builder.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/tabs_header/tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/providers/category_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/featured_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/global_search_tokens_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/latest_tokens_provider.r.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel_skeleton.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/list/creator_tokens_list.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_tab_content.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensPage extends HookConsumerWidget {
  const CreatorTokensPage({
    super.key,
  });

  static const _expandedHeaderHeight = 375.0;
  static const _tabBarHeight = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final globalSearch = ref.watch(globalSearchTokensNotifierProvider);
    final globalSearchNotifier = ref.read(globalSearchTokensNotifierProvider.notifier);

    final searchController = useTextEditingController();
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

    void resetGlobalSearch() {
      searchController.clear();
      globalSearchNotifier.search(
        query: '',
        externalAddresses: const [], // TODO: handle external addresses
      );
    }

    final maxScroll =
        _expandedHeaderHeight.s - NavigationAppBar.screenHeaderHeight - _tabBarHeight.s;
    final (:opacity) = useAnimatedOpacityOnScroll(
      scrollController,
      topOffset: maxScroll,
    );

    final isGlobalSearchVisible = useState<bool>(true);
    final lastSearchQuery = useRef<String?>(null);

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

    useEffect(
      () {
        if (debouncedQuery == lastSearchQuery.value) return null;
        lastSearchQuery.value = debouncedQuery;
        Future.microtask(() {
          globalSearchNotifier.search(
            query: debouncedQuery,
            // TODO: handle external addresses
            externalAddresses: [],
          );
        });
        return null;
      },
      [debouncedQuery],
    );

    // Create stable identifier for the list (to avoid unnecessary useEffect triggers)
    final tokensIdentifier = featuredTokens.map((t) => t.addresses.ionConnect).join(',');

    final initialToken = featuredTokens.isNotEmpty ? featuredTokens.first : null;
    final selectedToken = useState<CommunityToken?>(initialToken);

    // Update selectedToken when featuredTokens list actually changes
    useEffect(
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
        return null;
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
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              left: false,
              right: false,
              top: false,
              child: DefaultTabController(
                length: CreatorTokensTabType.values.length,
                child: NestedScrollView(
                  controller: scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        pinned: true,
                        expandedHeight: _expandedHeaderHeight.s,
                        toolbarHeight: NavigationAppBar.screenHeaderHeight,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        leading: NavigationBackButton(
                          context.pop,
                          icon: backButtonIcon,
                        ),
                        flexibleSpace: Builder(
                          builder: (context) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                ProfileBackground(
                                  colors: avatarColors,
                                ),
                                Opacity(
                                  opacity: 1 - opacity,
                                  child: featuredTokensAsync.when(
                                    data: (tokens) {
                                      if (tokens.isEmpty) return const SizedBox.shrink();
                                      return CreatorTokensCarousel(
                                        tokens: tokens,
                                        onItemChanged: (token) {
                                          selectedToken.value = token;
                                        },
                                      );
                                    },
                                    loading: () => const CreatorTokensCarouselSkeleton(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        bottom: PreferredSize(
                          preferredSize: Size.fromHeight(_tabBarHeight.s),
                          child: ColoredBox(
                            color: context.theme.appColors.primaryText,
                            child: TabsHeader(
                              tabs: CreatorTokensTabType.values,
                              trailing: _SearchIconButton(
                                onPressed: () {
                                  final nextVisible = !isGlobalSearchVisible.value;
                                  isGlobalSearchVisible.value = nextVisible;
                                  if (!nextVisible) {
                                    resetGlobalSearch();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SectionSeparator(),
                      ),
                      PinnedHeaderSliver(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: isGlobalSearchVisible.value
                              ? ColoredBox(
                                  color: context.theme.appColors.onPrimaryAccent,
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      top: 12.0.s,
                                      bottom: 8.0.s,
                                    ),
                                    child: ScreenSideOffset.small(
                                      child: SearchInput(
                                        controller: searchController,
                                        onCancelSearch: () {
                                          resetGlobalSearch();
                                          isGlobalSearchVisible.value = false;
                                        },
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ];
                  },
                  body: IndexedStack(
                    index: searchQuery.value.isNotEmpty ? 1 : 0,
                    children: [
                      TabBarView(
                        children: CreatorTokensTabType.values.map(
                          (tabType) {
                            return CreatorTokensTabContent(
                              tabType: tabType,
                            );
                          },
                        ).toList(),
                      ),
                      LoadMoreBuilder(
                        hasMore: globalSearch.activeHasMore,
                        onLoadMore: () => globalSearchNotifier.loadMore(
                          // TODO: handle external addresses
                          externalAddresses: const [],
                        ),
                        builder: (context, slivers) => RefreshIndicator(
                          onRefresh: () => globalSearchNotifier.refresh(
                            // TODO: handle external addresses
                            externalAddresses: const [],
                          ),
                          child: CustomScrollView(
                            slivers: slivers,
                          ),
                        ),
                        slivers: [
                          CreatorTokensList(
                            items: globalSearch.activeItems,
                            isInitialLoading: globalSearch.activeIsInitialLoading,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 4.0.s,
        horizontal: 16.0.s,
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Assets.svg.iconFieldSearch.icon(
          color: context.theme.appColors.tertiaryText,
          size: 18.0.s,
        ),
      ),
    );
  }
}
