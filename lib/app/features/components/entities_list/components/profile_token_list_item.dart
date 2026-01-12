// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/bottom_sheet_menu/bottom_sheet_menu_button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/bookmarks/bookmark_button.dart';
import 'package:ion/app/features/feed/views/components/community_token_live/components/feed_profile_token.dart';
import 'package:ion/app/features/feed/views/components/user_info/user_info.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ProfileTokenListItem extends StatelessWidget {
  const ProfileTokenListItem({
    required this.eventReference,
    this.network = false,
    super.key,
  });

  final EventReference eventReference;
  final bool network;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TokenizedCommunityRoute(
        externalAddress: eventReference.toString(),
      ).push<void>(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12.s),
          UserInfo(
            pubkey: eventReference.masterPubkey,
            network: network,
            trailing: BottomSheetMenuButton(
              menuBuilder: (context) => BookmarkButton(
                eventReference: eventReference,
                mode: BookmarkButtonMode.menuContent,
              ),
              padding: EdgeInsetsGeometry.symmetric(
                horizontal: ScreenSideOffset.defaultSmallMargin,
                vertical: 5.s,
              ),
            ),
            padding: EdgeInsetsDirectional.only(
              start: ScreenSideOffset.defaultSmallMargin,
            ),
          ),
          SizedBox(height: 10.s),
          FeedProfileToken(
            externalAddress: eventReference.toString(),
          ),
          SizedBox(height: 12.s),
        ],
      ),
    );
  }
}
