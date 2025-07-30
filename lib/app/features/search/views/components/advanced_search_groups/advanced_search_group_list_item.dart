// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/avatar.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class AdvancedSearchGroupListItem extends ConsumerWidget {
  const AdvancedSearchGroupListItem({
    required this.avatarUrl,
    required this.displayName,
    required this.message,
    required this.joined,
    this.isVerified = false,
    this.isION = false,
    super.key,
  });

  final String avatarUrl;
  final String displayName;
  final String message;
  final bool joined;
  final bool isVerified;
  final bool isION;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenSideOffset.small(
      child: Row(
        children: [
          Avatar(
            imageUrl: avatarUrl,
            size: 40.0.s,
          ),
          SizedBox(width: 12.0.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GroupHeader(displayName: displayName, isVerified: isVerified, isION: isION),
                SizedBox(height: 2.0.s),
                GroupDescription(joined: joined, message: message),
              ],
            ),
          ),
          Assets.svg.iconArrowRight.icon(
            size: 24.0.s,
            color: context.theme.appColors.tertiaryText,
          ),
        ],
      ),
    );
  }
}

class GroupDescription extends StatelessWidget {
  const GroupDescription({
    required this.joined,
    required this.message,
    super.key,
  });

  final bool joined;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (joined)
          Padding(
            padding: EdgeInsetsDirectional.only(end: 4.0.s),
            child: Assets.svg.iconChannelMembers.icon(
              size: 12.0.s,
              color: context.theme.appColors.onTertiaryBackground,
            ),
          ),
        Flexible(
          child: Text(
            message,
            style: context.theme.appTextThemes.body2.copyWith(
              color: context.theme.appColors.onTertiaryBackground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class GroupHeader extends StatelessWidget {
  const GroupHeader({
    required this.displayName,
    required this.isVerified,
    required this.isION,
    super.key,
  });

  final String displayName;
  final bool isVerified;
  final bool isION;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          displayName,
          style: context.theme.appTextThemes.subtitle3,
        ),
        if (isVerified)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 4.0.s),
            child: Assets.svg.iconBadgeIcelogo.icon(size: 16.0.s),
          ),
        if (isION)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 4.0.s),
            child: Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
          ),
      ],
    );
  }
}
