// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/user/follow_user_button/follow_user_button.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FollowListItem extends ConsumerWidget {
  const FollowListItem({
    required this.pubkey,
    this.network = false,
    this.follower,
    super.key,
  });

  final String pubkey;

  final bool network;

  final bool? follower;

  static double get itemHeight => 35.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(pubkey, network: network).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(pubkey, network: network).select(userPreviewNameSelector),
    );

    final isLoading = displayName.isEmpty && username.isEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: BadgesUserListItem(
        key: ValueKey<String>(pubkey),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 4.0.s),
                  child: SkeletonBox(width: 120.0.s, height: 16.0.s),
                )
              : Text(displayName, strutStyle: const StrutStyle(forceStrutHeight: true)),
        ),
        trailing: FollowUserButton(pubkey: pubkey, follower: follower),
        subtitle: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SkeletonBox(width: 80.0.s, height: 14.0.s)
              : Text(prefixUsername(username: username, context: context)),
        ),
        masterPubkey: pubkey,
        onTap: () => ProfileRoute(pubkey: pubkey).push<void>(context),
      ),
    );
  }
}
