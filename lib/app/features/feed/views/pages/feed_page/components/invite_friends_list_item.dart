// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/components/custom_feed_list_item.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

class InviteFriendsListItem extends StatelessWidget {
  const InviteFriendsListItem({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: CustomFeedListItem(
        header: ListItem.dapp(
          leading: Button.icon(
            backgroundColor: context.theme.appColors.tertiaryBackground,
            borderColor: context.theme.appColors.onTertiaryFill,
            borderRadius: BorderRadius.all(
              Radius.circular(10.0.s),
            ),
            borderWidth: 0.83.s,
            size: 36.0.s,
            onPressed: () => onTap(context),
            icon: Assets.svg.iconButtonInvite.icon(
              size: 20.0.s,
              color: context.theme.appColors.primaryText,
            ),
          ),
          title: Text(
            context.i18n.feed_invite_friends_title,
            style: context.theme.appTextThemes.subtitle3.copyWith(
              color: context.theme.appColors.primaryText,
            ),
          ),
          subtitle: Text(
            context.i18n.feed_invite_friends_subtitle,
          ),
          trailing: Button.compact(
            minimumSize: Size(77.0.s, 30.0.s),
            label: Text(
              textAlign: TextAlign.center,
              context.i18n.feed_invite_friends_button,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
              ),
              style: context.theme.appTextThemes.body.copyWith(
                color: context.theme.appColors.onPrimaryAccent,
              ),
            ),
            onPressed: () => onTap(context),
          ),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12.0.s),
          child: AspectRatio(
            aspectRatio: 1.715,
            child: Assets.images.inviteFriends.inviteImage.icon(fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  void onTap(BuildContext context) {
    print('___ onTap InviteFriendsListItem, ${Random().nextInt(1000)}');
    InviteFriendsRoute().push<void>(context);
  }
}
