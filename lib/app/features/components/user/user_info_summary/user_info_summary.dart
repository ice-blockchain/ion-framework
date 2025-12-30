// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/user/user_info_summary/user_info_tile.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/user_categories_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart' hide UserMetadata;
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class UserInfoSummary extends HookConsumerWidget {
  const UserInfoSummary({
    required this.pubkey,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMetadataValue = ref.watch(userMetadataProvider(pubkey)).valueOrNull;
    final isCurrentUserFollowed = ref.watch(isCurrentUserFollowedProvider(pubkey));

    if (userMetadataValue == null) {
      return const SizedBox.shrink();
    }

    final UserMetadata(:website, :registeredAt, :location, :category) = userMetadataValue.data;

    final tiles = <Widget>[];

    if (category != null) {
      tiles.add(_CategoryTile(category: category, profileMode: profileMode));
    }

    if (website != null && website.isNotEmpty) {
      tiles.add(
        UserInfoTile(
          title: website,
          assetName: Assets.svg.iconArticleLink,
          isLink: true,
          profileMode: profileMode,
        ),
      );
    }

    if (registeredAt != null) {
      tiles.add(
        UserInfoTile(
          title: formatDateToMonthYear(registeredAt.toDateTime),
          assetName: Assets.svg.iconFieldCalendar,
          profileMode: profileMode,
        ),
      );
    }

    if (location != null && location.isNotEmpty) {
      tiles.add(
        UserInfoTile(
          title: location,
          assetName: Assets.svg.iconProfileLocation,
          profileMode: profileMode,
        ),
      );
    }

    if (isCurrentUserFollowed) {
      tiles.add(
        UserInfoTile(
          title: context.i18n.profile_follows_you,
          assetName: Assets.svg.iconSearchFollow,
          profileMode: profileMode,
        ),
      );
    }

    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.0.s,
        runSpacing: 4.0.s,
        children: tiles,
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category, required this.profileMode});

  final String category;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(userCategoriesProvider);
    final label = categories[category]?.getName(context);

    if (label == null) return const SizedBox.shrink();

    return UserInfoTile(
      title: label,
      assetName: Assets.svg.iconBlockchain,
      profileMode: profileMode,
    );
  }
}
