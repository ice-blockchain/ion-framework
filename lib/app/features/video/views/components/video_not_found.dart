// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class VideoNotFound extends StatelessWidget {
  const VideoNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.svg.iconFeedUnavailable.icon(
            size: 40.0.s,
            color: context.theme.appColors.sheetLine,
          ),
          SizedBox(height: 6.0.s),
          Text(
            context.i18n.video_not_found,
            style: context.theme.appTextThemes.caption2.copyWith(
              color: context.theme.appColors.sheetLine,
            ),
          ),
        ],
      ),
    );
  }
}
