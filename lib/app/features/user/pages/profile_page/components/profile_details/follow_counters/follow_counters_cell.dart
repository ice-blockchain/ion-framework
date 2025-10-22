// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';

class FollowCountersCell extends StatelessWidget {
  const FollowCountersCell({
    required this.pubkey,
    required this.usersNumber,
    required this.followType,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final int usersNumber;
  final FollowType followType;
  final ProfileMode profileMode;

  Color _iconColor(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return context.theme.appColors.secondaryBackground;
    }
    return context.theme.appColors.primaryText;
  }

  Color _numberColor(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return context.theme.appColors.secondaryBackground;
    }
    return context.theme.appColors.primaryText;
  }

  Color _labelColor(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return context.theme.appColors.sheetLine;
    }
    return context.theme.appColors.tertiaryText;
  }

  TextStyle _numberTextStyle(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return context.theme.appTextThemes.body2.copyWith(
        color: _numberColor(context),
        fontWeight: FontWeight.w500,
      );
    }
    return context.theme.appTextThemes.body2.copyWith(
      color: _numberColor(context),
    );
  }

  TextStyle _labelTextStyle(BuildContext context) {
    if (profileMode == ProfileMode.dark) {
      return context.theme.appTextThemes.body2.copyWith(
        color: _labelColor(context),
        fontSize: 12.0.s,
        fontWeight: FontWeight.w400,
      );
    }
    return context.theme.appTextThemes.body2.copyWith(
      color: _labelColor(context),
    );
  }

  double get _iconSize => 16.0.s;

  double get _spacing => 4.0.s;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (usersNumber > 0) {
          FollowListRoute(
            pubkey: pubkey,
            followType: followType,
          ).push<String>(context);
        }
      },
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                followType.iconAsset.icon(
                  color: _iconColor(context),
                  size: _iconSize,
                ),
                SizedBox(width: _spacing),
                Text(
                  formatCount(usersNumber),
                  style: _numberTextStyle(context),
                ),
              ],
            ),
            SizedBox(width: _spacing),
            Text(
              followType.getTitle(context),
              style: _labelTextStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}
