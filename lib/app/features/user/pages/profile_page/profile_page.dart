// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/section_separator/section_separator.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
import 'package:ion/app/features/user/model/user_content_type.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/cant_find_profile_page.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/header.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/profile_context_menu.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_details.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/tab_entities_list.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/tabs_header/tabs_header.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_skeleton.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/hooks/use_animated_opacity_on_scroll.dart';
import 'package:ion/app/hooks/use_scroll_top_on_tab_press.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';
import 'package:ion/generated/assets.gen.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({
    required this.pubkey,
    this.showBackButton = true,
    super.key,
  });

  final String pubkey;
  final bool showBackButton;

  double get paddingTop => 60.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleted = ref.watch(isUserDeletedProvider(pubkey)).valueOrNull.falseOrValue;
    final isBlockedOrBlockedBy =
        ref.watch(isBlockedOrBlockedByNotifierProvider(pubkey)).valueOrNull.falseOrValue;

    if (isDeleted || isBlockedOrBlockedBy) {
      return const CantFindProfilePage();
    }

    final userMetadata = ref.watch(userMetadataProvider(pubkey));

    if (userMetadata.hasError) {
      return const CantFindProfilePage();
    }

    final isCurrentUserProfile = ref.watch(isCurrentUserSelectorProvider(pubkey));

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

        invalidateCurrentUserMetadataProviders(ref);

        ref.read(ionConnectCacheProvider.notifier).remove(
              EventCountResultEntity.cacheKeyBuilder(
                key: pubkey,
                type: EventCountResultType.followers,
              ),
            );
        ref.read(ionConnectCacheProvider.notifier).remove(
              EventCountResultEntity.cacheKeyBuilder(
                key: pubkey,
                type: EventCountResultType.stories,
              ),
            );
      },
      [userMetadata.value?.cacheKey],
    );

    final backButtonIcon = Assets.svg.iconProfileBack.icon(
      size: NavigationBackButton.iconSize,
      flipForRtl: true,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            DefaultTabController(
              length: UserContentType.values.length,
              child: NestedScrollView(
                controller: scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(height: 12.0.s),
                          ProfileAvatar(pubkey: pubkey),
                          SizedBox(height: 16.0.s),
                          ProfileDetails(pubkey: pubkey),
                          SizedBox(height: 16.0.s),
                          const HorizontalSeparator(),
                          SizedBox(height: 16.0.s),
                        ],
                      ),
                    ),
                    PinnedHeaderSliver(
                      child: ColoredBox(
                        color: backgroundColor,
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
                                pubkey: pubkey,
                                onRefresh: onRefresh,
                              )
                            : TabEntitiesList(
                                pubkey: pubkey,
                                type: type,
                                onRefresh: onRefresh,
                              ),
                      )
                      .toList(),
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
                  backButtonIcon: backButtonIcon,
                  scrollController: scrollController,
                  horizontalPadding: 0,
                  title: Header(
                    opacity: opacity,
                    pubkey: pubkey,
                    showBackButton: !isCurrentUserProfile,
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 16.s),
                child: SizedBox(
                  height: NavigationAppBar.screenHeaderHeight,
                  child: ProfileContextMenu(pubkey: pubkey),
                ),
              ),
            ),
            if (showBackButton)
              Align(
                alignment: AlignmentDirectional.topStart,
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
