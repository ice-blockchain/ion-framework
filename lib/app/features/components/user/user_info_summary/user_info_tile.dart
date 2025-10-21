// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/services/browser/browser.dart';
import 'package:ion/app/utils/url.dart';

class UserInfoTile extends StatelessWidget {
  const UserInfoTile({
    required this.title,
    required this.assetName,
    this.isLink = false,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String title;
  final String assetName;
  final bool isLink;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context) {
    final color = profileMode == ProfileMode.dark
        ? (isLink ? context.theme.appColors.lightBlue : context.theme.appColors.strokeElements)
        : (isLink ? context.theme.appColors.darkBlue : context.theme.appColors.quaternaryText);

    return GestureDetector(
      onTap: isLink ? () => openUrlInAppBrowser(title) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          assetName.icon(
            size: 14.0.s,
            color: color,
          ),
          SizedBox(width: 4.0.s),
          Text(
            isLink ? extractDomain(title)! : title,
            style: context.theme.appTextThemes.body2.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToLastDescent: false,
              applyHeightToFirstAscent: false,
            ),
          ),
        ],
      ),
    );
  }
}
