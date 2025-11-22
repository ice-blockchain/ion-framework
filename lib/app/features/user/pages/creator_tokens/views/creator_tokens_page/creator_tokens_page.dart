// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/tabs_header/tabs_header.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/carousel/creator_tokens_carousel.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/components/tabs/creator_tokens_tab_content.dart';
import 'package:ion/app/features/user/pages/profile_page/cant_find_profile_page.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/header.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_skeleton.dart';
import 'package:ion/app/features/communities/providers/featured_tokens_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_avatar_colors.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokensPage extends HookConsumerWidget {
  const CreatorTokensPage({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  double get paddingTop => 60.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(masterPubkey));

    final statusBarHeight = MediaQuery.paddingOf(context).top;

    if (userMetadata.isLoading && !userMetadata.hasValue) {
      return const ProfileSkeleton(showBackButton: true);
    }

    final metadata = userMetadata.valueOrNull;

    final isBlockedOrBlockedBy = ref.watch(
      isBlockedOrBlockedByNotifierProvider(masterPubkey)
          .select((value) => value.valueOrNull.falseOrValue),
    );

    if (metadata.isDeleted || isBlockedOrBlockedBy) {
      return const CantFindProfilePage();
    }

    final scrollController = useScrollController();

    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: paddingTop);

    // Get featured tokens
    final featuredTokensAsync = ref.watch(featuredTokensProvider);

    // Get list of featured tokens
    final featuredTokens = featuredTokensAsync.when<List<CommunityToken>>(
      data: (List<CommunityToken> tokens) => tokens,
      loading: () => <CommunityToken>[],
      error: (_, __) => <CommunityToken>[],
    );

    // Create stable identifier for the list (to avoid unnecessary useEffect triggers)
    final tokensIdentifier = featuredTokens.map((t) => t.addresses.ionConnect).join(',');

    // Initialize with first carousel item if available
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
    final avatarColors = useAvatarColors(avatarUrl);

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
                      SliverToBoxAdapter(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ProfileBackground(
                                colors: avatarColors,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.only(top: 70.0.s, bottom: 44.0.s),
                              child: featuredTokens.isEmpty
                                  ? const SizedBox.shrink()
                                  : CreatorTokensCarousel(
                                      tokens: featuredTokens,
                                      onItemChanged: (token) {
                                        selectedToken.value = token;
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      PinnedHeaderSliver(
                        child: ColoredBox(
                          color: context.theme.appColors.primaryText,
                          child: const TabsHeader(
                            tabs: CreatorTokensTabType.values,
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SectionSeparator(),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: CreatorTokensTabType.values.map(
                      (tabType) {
                        return CreatorTokensTabContent(
                          pubkey: masterPubkey,
                          tabType: tabType,
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: opacity <= 0.5,
              child: Opacity(
                opacity: opacity,
                child: NavigationAppBar(
                  useScreenTopOffset: true,
                  extendBehindStatusBar: true,
                  backButtonIcon: backButtonIcon,
                  scrollController: scrollController,
                  horizontalPadding: 0,
                  backgroundBuilder: () => ProfileBackground(
                    colors: avatarColors,
                    disableDarkGradient: true,
                  ),
                  title: Header(
                    opacity: opacity,
                    pubkey: selectedToken.value?.creator.ionConnect ?? masterPubkey,
                    showBackButton: true,
                    textColor: context.theme.appColors.secondaryBackground,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: statusBarHeight,
              start: 0,
              child: NavigationBackButton(
                context.pop,
                icon: backButtonIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
