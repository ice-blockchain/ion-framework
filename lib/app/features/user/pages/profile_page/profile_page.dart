// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/layouts/collapsing_header_tabs_layout.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/model/feature_flags.dart';
import 'package:ion/app/features/core/providers/feature_flags_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
import 'package:ion/app/features/user/model/user_content_type.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/app/features/user/pages/profile_page/cant_find_profile_page.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/header.dart';
import 'package:ion/app/features/user/pages/profile_page/components/header/profile_context_menu.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_actions/profile_actions.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_details/profile_details.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/app/features/user/pages/profile_page/components/tabs/tab_entities_list.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_skeleton.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_icon_button.dart';
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

    if (userMetadata.isLoading && !userMetadata.hasValue) {
      return ProfileSkeleton(showBackButton: showBackButton);
    }

    final tokenizedCommunitiesEnabled = ref
        .watch(featureFlagsProvider.notifier)
        .get(TokenizedCommunitiesFeatureFlag.tokenizedCommunitiesEnabled);

    final profileMode = tokenizedCommunitiesEnabled ? ProfileMode.dark : ProfileMode.light;

    final statusBarHeight = MediaQuery.paddingOf(context).top;

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

    final avatarUrl = userMetadata.valueOrNull?.data.avatarUrl;
    final eventReferenceString = userMetadata.valueOrNull?.toEventReference().toString();

    final isTokenizedProfile = profileMode == ProfileMode.dark && eventReferenceString != null;
    final tokenInfo =
        isTokenizedProfile ? ref.watch(tokenMarketInfoProvider(eventReferenceString!)) : null;
    final hasToken = tokenInfo?.valueOrNull != null;

    final showTokenButton = isCurrentUserProfile && isTokenizedProfile && hasToken;
    final eventRefForButton = showTokenButton ? eventReferenceString : null;

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

    final isMultiAccountsEnabled =
        ref.watch(featureFlagsProvider.notifier).get(MultiAccountsFeatureFlag.multiAccountsEnabled);

    return Scaffold(
      backgroundColor: context.theme.appColors.secondaryBackground,
      body: CollapsingHeaderTabsLayout(
        backgroundColor: context.theme.appColors.secondaryBackground,
        showBackButton: showBackButton,
        newUiMode: profileMode == ProfileMode.dark,
        imageUrl: avatarUrl,
        tabs: UserContentType.values,
        collapsedHeaderBuilder: (opacity) {
          final leadingPadding = showTokenButton ? 40.0.s : (!isCurrentUserProfile ? 0.0 : 16.0.s);
          return Header(
            opacity: opacity,
            pubkey: masterPubkey,
            showBackButton: !isCurrentUserProfile,
            leadingPadding: leadingPadding,
            textColor: profileMode == ProfileMode.dark
                ? context.theme.appColors.secondaryBackground
                : null,
          );
        },
        leadingActionsBuilder: eventRefForButton != null
            ? () => NavigationIconButton(
                  onPress: () => TokenizedCommunityRoute(
                    externalAddress: eventRefForButton!,
                  ).push<void>(context),
                  icon: Assets.svg.iconProfileTokenpage.icon(
                    size: NavigationIconButton.iconSize,
                    color: context.theme.appColors.secondaryBackground,
                  ),
                )
            : null,
        tabBarViews: TabEntityType.values
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
        expandedHeader: Column(
          children: [
            SizedBox(
              height: (profileMode == ProfileMode.dark ? statusBarHeight : 0) + 27.0.s,
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                ProfileAvatar(
                  profileMode: profileMode,
                  pubkey: masterPubkey,
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
            SizedBox(
              height: profileMode == ProfileMode.dark ? 9.0.s : 12.0.s,
            ),
            ProfileDetails(
              pubkey: masterPubkey,
              profileMode: profileMode,
            ),
            SizedBox(
              height: profileMode == ProfileMode.dark ? 5.0.s : 12.0.s,
            ),
            if (profileMode != ProfileMode.dark) const HorizontalSeparator(),
            SizedBox(
              height: profileMode == ProfileMode.dark ? 9.0.s : 12.0.s,
            ),
          ],
        ),
        headerActionsBuilder: (menuCloseSignal) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.0.s,
          children: [
            if (profileMode == ProfileMode.dark) ...[
              ProfileActions(
                pubkey: masterPubkey,
                profileMode: profileMode,
              ),
            ],
            if (isMultiAccountsEnabled) ...[
              GestureDetector(
                onTap: () => SwitchAccountRoute().push<void>(context),
                child: Assets.svg.iconSwitchProfile.icon(
                  size: profileMode == ProfileMode.dark ? 21.0.s : 24.0.s,
                  color: profileMode == ProfileMode.dark
                      ? context.theme.appColors.secondaryBackground
                      : null,
                ),
              ),
            ],
            ProfileContextMenu(
              pubkey: masterPubkey,
              closeSignal: menuCloseSignal,
              profileMode: profileMode,
            ),
          ],
        ),
      ),
    );
  }
}
