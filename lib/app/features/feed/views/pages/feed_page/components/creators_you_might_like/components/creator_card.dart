// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/model/user_category.f.dart';
import 'package:ion/app/features/user/pages/profile_page/components/profile_main_action.dart';
import 'package:ion/app/features/user/providers/followers_count_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorCard extends ConsumerWidget {
  const CreatorCard({
    required this.masterPubkey,
    super.key,
  });

  final String masterPubkey;

  static double get cardWidth => 280.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(masterPubkey).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(masterPubkey).select(userPreviewNameSelector),
    );

    final followersCount = ref.watch(followersCountProvider(masterPubkey)).valueOrNull;

    final categoryKey = ref.watch(
      userMetadataProvider(masterPubkey).select((s) => s.valueOrNull?.data.category),
    );
    final userCategory = categoryKey != null ? UserCategory.fromKey(categoryKey) : null;

    return GestureDetector(
      onTap: () => ProfileRoute(pubkey: masterPubkey).push<void>(context),
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.all(10.0.s),
        decoration: BoxDecoration(
          color: context.theme.appColors.tertiaryBackground,
          borderRadius: BorderRadius.circular(16.0.s),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 12.0.s,
          children: [
            _CreatorInfo(
              masterPubkey: masterPubkey,
              displayName: displayName,
              username: username,
              followersCount: followersCount,
            ),
            if (userCategory != null) _CategoryChip(category: userCategory),
          ],
        ),
      ),
    );
  }
}

class _CreatorInfo extends StatelessWidget {
  const _CreatorInfo({
    required this.masterPubkey,
    required this.displayName,
    required this.username,
    required this.followersCount,
  });

  final String masterPubkey;
  final String displayName;
  final String username;
  final int? followersCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8.0.s,
      children: [
        IonConnectAvatar(
          size: 59.0.s,
          masterPubkey: masterPubkey,
          borderRadius: BorderRadius.circular(15.0.s),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2.0.s,
                      children: [
                        Text(
                          displayName,
                          style: context.theme.appTextThemes.subtitle3.copyWith(
                            color: context.theme.appColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Opacity(
                          opacity: 0.7,
                          child: Text(
                            withPrefix(
                              input: username,
                              textDirection: Directionality.of(context),
                            ),
                            style: context.theme.appTextThemes.caption2.copyWith(
                              color: context.theme.appColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProfileMainAction(
                    pubkey: masterPubkey,
                    profileMode: ProfileMode.dark,
                  ),
                ],
              ),
              if (followersCount != null)
                Padding(
                  padding: EdgeInsets.only(top: 4.0.s),
                  child: _FollowersCountRow(count: followersCount!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FollowersCountRow extends StatelessWidget {
  const _FollowersCountRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4.0.s,
      children: [
        Row(
          spacing: 2.0.s,
          children: [
            Assets.svg.iconSearchGroups.icon(
              size: 16.0.s,
              color: context.theme.appColors.primaryAccent,
            ),
            Text(
              formatCount(count),
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.secondaryText,
              ),
            ),
          ],
        ),
        Opacity(
          opacity: 0.7,
          child: Text(
            context.i18n.feed_creators_followers,
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.tertiaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final UserCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0.s, vertical: 4.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.secondaryBackground,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4.0.s,
        children: [
          Assets.svg.iconBlockchain.icon(
            size: 14.0.s,
            color: context.theme.appColors.secondaryText,
          ),
          Flexible(
            child: Text(
              category.getName(context),
              style: context.theme.appTextThemes.caption2.copyWith(
                color: context.theme.appColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
