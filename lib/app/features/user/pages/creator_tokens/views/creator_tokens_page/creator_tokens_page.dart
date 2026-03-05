// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
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
import 'package:ion/app/hooks/use_has_android_button_nav_bar.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/app/router/utils/back_gesture_exclusion.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class CreatorTokensPage extends StatefulHookConsumerWidget {
  const CreatorTokensPage({
    super.key,
  });

  @override
  ConsumerState<CreatorTokensPage> createState() => _CreatorTokensPageState();
}

class _CreatorTokensPageState extends ConsumerState<CreatorTokensPage>
    with SingleTickerProviderStateMixin, RestorationMixin {
  static final _tabBarHeight = 54.0.s;
  static final _expandedHeaderHeight = 369.s;

  late final ScrollController _scrollController;
  late final TabController _tabController;
  final RestorableInt _tabIndex = RestorableInt(0);

  @override
  String? get restorationId => 'creator_tokens_tab';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(
      length: CreatorTokensTabType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _tabIndex.value = _tabController.index;
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_tabIndex, 'tab_index');
    _tabController.index = _tabIndex.value;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _scrollController.dispose();
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabController = _tabController;
    final scrollController = _scrollController;
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

    useEffect(
      () {
        void tabListener() {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }

        tabController.addListener(tabListener);
        return () => tabController.removeListener(tabListener);
      },
      [tabController, scrollController],
    );

    final maxScroll = _expandedHeaderHeight -
        NavigationAppBar.screenHeaderHeight -
        _tabBarHeight -
        MediaQuery.paddingOf(context).top;

    final isGlobalSearchVisible = useState<bool>(false);
    final lastSearchQuery = useRef<String?>(null);

    final carouselKey = useMemoized(GlobalKey.new);
    final carouselRect = useMemoized(() => ValueNotifier<Rect?>(null));
    final route = ModalRoute.of(context);

    void updateCarouselRect() {
      final carouselContext = carouselKey.currentContext;
      if (carouselContext == null) {
        if (carouselRect.value != null) {
          carouselRect.value = null;
        }
        return;
      }

      final renderObject = carouselContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return;
      }

      final origin = renderObject.localToGlobal(Offset.zero);
      final rect = origin & renderObject.size;
      if (carouselRect.value != rect) {
        carouselRect.value = rect;
      }
    }

    useEffect(
      () {
        if (route == null) {
          return null;
        }

        BackGestureExclusionRegistry.register(route, carouselRect);
        return () => BackGestureExclusionRegistry.unregister(route, carouselRect);
      },
      [route, carouselRect],
    );

    useEffect(
      () {
        void listener() => updateCarouselRect();
        scrollController.addListener(listener);
        WidgetsBinding.instance.addPostFrameCallback((_) => updateCarouselRect());
        return () => scrollController.removeListener(listener);
      },
      [scrollController],
    );

    useEffect(
      () {
        return carouselRect.dispose;
      },
      const [],
    );

    useOnInit(
      () {
        if (searchFocused.value) {
          if (scrollController.hasClients) {
            final currentOffset = scrollController.offset;
            final targetOffset = maxScroll;

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

    final tokensIdentifier = featuredTokens.map((t) => t.addresses.ionConnect).join(',');

    final initialToken = featuredTokens.isNotEmpty ? featuredTokens.first : null;
    final selectedToken = useState<CommunityToken?>(initialToken);

    useOnInit(
      () {
        if (featuredTokens.isNotEmpty) {
          if (selectedToken.value == null ||
              !featuredTokens.any(
                (t) => t.addresses.ionConnect == selectedToken.value!.addresses.ionConnect,
              )) {
            selectedToken.value = featuredTokens.first;
          }
        } else {
          selectedToken.value = null;
        }
      },
      [tokensIdentifier],
    );

    final avatarUrl = selectedToken.value?.creator.avatar ?? '';
    final avatarColors = useImageColors(avatarUrl);

    final backgroundColor = context.theme.appColors.secondaryBackground;

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
      color: context.theme.appColors.onPrimaryAccent,
    );

    final hasButtonNavBar = useHasAndroidButtonNavBar();

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: hasButtonNavBar,
        child: KeyboardDismissOnTap(
          child: ScrollToTopWrapper(
            scrollController: scrollController,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                NestedScrollView(
                  restorationId: 'user_creator_tokens_scroll',
                  controller: scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      CreatorTokensHeader(
                        expandedHeight: _expandedHeaderHeight - MediaQuery.paddingOf(context).top,
                        opacity: opacity,
                        featuredTokensAsync: featuredTokensAsync,
                        selectedToken: selectedToken,
                        avatarColors: avatarColors,
                        backButtonIcon: backButtonIcon,
                        scrollController: scrollController,
                        tabController: tabController,
                        onPop: context.pop,
                        onSearchToggle: () {
                          final nextVisible = !isGlobalSearchVisible.value;
                          isGlobalSearchVisible.value = nextVisible;
                          if (!nextVisible) {
                            resetGlobalSearch();
                          }
                        },
                        carouselKey: carouselKey,
                      ),
                      SliverToBoxAdapter(
                        child: CreatorTokensFilterBar(
                          scrollController: scrollController,
                        ),
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
                    tabController: tabController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
