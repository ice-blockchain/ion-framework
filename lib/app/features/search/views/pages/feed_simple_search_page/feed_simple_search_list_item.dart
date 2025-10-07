// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/providers/feed_search_history_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/username.dart';

class FeedSimpleSearchListItem extends ConsumerWidget {
  const FeedSimpleSearchListItem({required this.user, super.key});

  final UserMetadataEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ref.read(feedSearchHistoryProvider.notifier).addUserIdToTheHistory(user.masterPubkey);
        ProfileRoute(pubkey: user.masterPubkey).push<void>(context);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0.s),
        child: ScreenSideOffset.small(
          child: BadgesUserListItem(
            title: Text(user.data.trimmedDisplayName),
            subtitle: Text(
              prefixUsername(username: user.data.name, context: context),
            ),
            masterPubkey: user.masterPubkey,
          ),
        ),
      ),
    );
  }
}
