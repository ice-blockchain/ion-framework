// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/scroll_to_top_wrapper/scroll_to_top_wrapper.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
import 'package:ion/app/features/user/model/user_content_type.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/cant_find_profile_page.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/header.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/profile_context_menu.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_background.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/profile_actions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_details.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/tab_entities_list.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/tabs_header/tabs_header.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_skeleton.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({
    required this.masterPubkey,
    this.showBackButton = true,
    super.key,
  });

  final String masterPubkey;
  final bool showBackButton;

  double get paddingTop => 60.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadata = ref.watch(userMetadataProvider(masterPubkey));
    final isVerifiedUser = ref.watch(isUserVerifiedProvider(masterPubkey));
    final tokenizedCommunitiesEnabled = ref
        .watch(featureFlagsProvider.notifier)
        .get(TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled);
    final profileMode =
        isVerifiedUser && tokenizedCommunitiesEnabled ? ProfileMode.dark : ProfileMode.light;
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    if (userMetadata.isLoading && !userMetadata.hasValue) {
      return ProfileSkeleton(showBackButton: showBackButton);
    }

    final metadata = userMetadata.valueOrNull;

    final isBlockedOrBlockedBy = ref.watch(
      isBlockedOrBlockedByNotifierProvider(masterPubkey)
          .select((value) => value.valueOrNull.falseOrValue),
    );

    if (metadata.isDeleted || isBlockedOrBlockedBy) {
      return const CantFindProfilePage();
    }

    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(masterPubkey));

    final didRefresh = useState(false);

    final isInitialLoading = !didRefresh.value && (!userMetadata.hasValue);

    if (isInitialLoading) {
      return ProfileSkeleton(showBackButton: showBackButton);
    }

    final scrollController = useScrollController();
    if (!showBackButton) {
      useScrollTopOnTabPress(context, scrollController: scrollController);
    }
    final (:opacity) = useAnimatedOpacityOnScroll(scrollController, topOffset: paddingTop);

    final backgroundColor = context.theme.appColors.secondaryBackground;

    final onRefresh = useCallback(
      () {
        didRefresh.value = true;
        if (userMetadata.value == null) return;

        ref
            .read(ionConnectDatabaseCacheProvider.notifier)
            .remove(userMetadata.value!.toEventReference().toString());

        ref
            .read(userMetadataInvalidatorNotifierProvider.notifier)
            .invalidateCurrentUserMetadataProviders();

        ref.read(ionConnectCacheProvider.notifier).remove(
              EventCountResultEntity.cacheKeyBuilder(
                key: masterPubkey,
                type: EventCountResultType.followers,
              ),
            );
        ref.read(ionConnectCacheProvider.notifier).remove(
              EventCountResultEntity.cacheKeyBuilder(
                key: masterPubkey,
                type: EventCountResultType.stories,
              ),
            );
      },
      [userMetadata.value?.cacheKey],
    );

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
      color: profileMode == ProfileMode.dark ? context.theme.appColors.onPrimaryAccent : null,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: profileMode == ProfileMode.dark,
      body: ScrollToTopWrapper(
        scrollController: scrollController,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            SafeArea(
              left: profileMode != ProfileMode.dark,
              right: profileMode != ProfileMode.dark,
              top: profileMode != ProfileMode.dark,
              child: DefaultTabController(
                length: UserContentType.values.length,
                child: NestedScrollView(
                  controller: scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Stack(
                          children: [
                            if (profileMode == ProfileMode.dark)
                              const Positioned.fill(child: ProfileBackground()),
                            Column(
                              children: [
                                SizedBox(
                                  height: (profileMode == ProfileMode.dark ? statusBarHeight : 0) +
                                      12.0.s,
                                ),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ProfileAvatar(
                                      pubkey: masterPubkey,
                                      profileMode: profileMode,
                                    ),
                                    PositionedDirectional(
                                      bottom: -6.0.s,
                                      end: -6.0.s,
                                      child: ProfileMainAction(
                                        pubkey: masterPubkey,
                                        profileMode: profileMode,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: profileMode == ProfileMode.dark ? 9.0.s : 16.0.s),
                                ProfileDetails(
                                  pubkey: masterPubkey,
                                  profileMode: profileMode,
                                ),
                                SizedBox(height: profileMode == ProfileMode.dark ? 5.0.s : 16.0.s),
                                if (profileMode != ProfileMode.dark) const HorizontalSeparator(),
                                SizedBox(height: profileMode == ProfileMode.dark ? 9.0.s : 16.0.s),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PinnedHeaderSliver(
                        child: ColoredBox(
                          color: profileMode == ProfileMode.dark
                              ? context.theme.appColors.primaryText
                              : backgroundColor,
                          child: const ProfileTabsHeader(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SectionSeparator()),
                    ];
                  },
                  body: TabBarView(
                    children: TabEntityType.values
                        .map(
                          (type) => type == TabEntityType.replies
                              ? TabEntitiesList.replies(
                                  pubkey: masterPubkey,
                                  onRefresh: onRefresh,
                                )
                              : TabEntitiesList(
                                  pubkey: masterPubkey,
                                  type: type,
                                  onRefresh: onRefresh,
                                ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            _IgnorePointerWrapper(
              shouldWrap: opacity <= 0.5,
              child: Opacity(
                opacity: opacity,
                child: NavigationAppBar(
                  showBackButton: showBackButton,
                  useScreenTopOffset: true,
                  extendBehindStatusBar: profileMode == ProfileMode.dark,
                  backButtonIcon: backButtonIcon,
                  scrollController: scrollController,
                  horizontalPadding: 0,
                  backgroundBuilder:
                      profileMode == ProfileMode.dark ? () => const ProfileBackground() : null,
                  title: Header(
                    opacity: opacity,
                    pubkey: masterPubkey,
                    showBackButton: !isCurrentUserProfile,
                    textColor: profileMode == ProfileMode.dark
                        ? context.theme.appColors.secondaryBackground
                        : null,
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 16.s, top: statusBarHeight),
                child: SizedBox(
                  height: NavigationAppBar.screenHeaderHeight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (profileMode == ProfileMode.dark) ...[
                        ProfileActions(
                          pubkey: masterPubkey,
                          profileMode: profileMode,
                        ),
                        SizedBox(width: 8.0.s),
                      ],
                      ProfileContextMenu(
                        pubkey: masterPubkey,
                        profileMode: profileMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showBackButton)
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

class _IgnorePointerWrapper extends StatelessWidget {
  const _IgnorePointerWrapper({required this.child, required this.shouldWrap});

  final Widget child;
  final bool shouldWrap;

  @override
  Widget build(BuildContext context) {
    return shouldWrap ? IgnorePointer(child: child) : child;
  }
}
