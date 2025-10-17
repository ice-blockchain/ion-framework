// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/badges_user_list_item.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/ion_connect_avatar/ion_connect_avatar.dart';
import 'package:ion/app/features/feed/views/components/time_ago/time_ago.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/utils/profile_navigation_utils.dart';
import 'package:ion/app/utils/username.dart';

class UserInfo extends HookConsumerWidget {
  const UserInfo({
    required this.pubkey,
    this.trailing,
    this.textStyle,
    this.createdAt,
    this.accentTheme = false,
    this.timeFormat = TimestampFormat.short,
    this.shadow,
    this.padding,
    // Should the user data be fetched from network if it's not in cache
    this.network = false,
    super.key,
  });

  final String pubkey;
  final bool accentTheme;
  final Widget? trailing;
  final TextStyle? textStyle;
  final int? createdAt;
  final TimestampFormat timeFormat;
  final BoxShadow? shadow;
  final EdgeInsetsDirectional? padding;
  final bool network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(pubkey, network: network).select(userPreviewDisplayNameSelector),
    );

    final username = ref.watch(
      userPreviewDataProvider(pubkey, network: network).select(userPreviewNameSelector),
    );

    void openProfile() => ProfileNavigationUtils.navigateToProfile(context, pubkey);

    final tStyle = textStyle ??
        context.theme.appTextThemes.caption.copyWith(
          color: accentTheme ? context.theme.appColors.onPrimaryAccent : null,
        );

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: BadgesUserListItem(
        title: GestureDetector(
          onTap: openProfile,
          child: Text(
            displayName,
            style: tStyle,
            strutStyle: const StrutStyle(forceStrutHeight: true),
          ),
        ),
        subtitle: GestureDetector(
          onTap: openProfile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                prefixUsername(username: username, context: context),
                style: tStyle,
              ),
              if (createdAt != null) ...[
                SizedBox(width: 4.0.s),
                Text('•', style: tStyle),
                SizedBox(width: 4.0.s),
                TimeAgo(
                  time: createdAt!.toDateTime,
                  timeFormat: timeFormat,
                  style: tStyle,
                ),
              ],
            ],
          ),
        ),
        masterPubkey: pubkey,
        leading: GestureDetector(
          onTap: openProfile,
          child: IonConnectAvatar(
            size: ListItem.defaultAvatarSize,
            masterPubkey: pubkey,
            shadow: shadow,
          ),
        ),
        trailing: trailing,
        trailingPadding: EdgeInsetsDirectional.only(start: 34.0.s),
      ),
    );
  }
}
