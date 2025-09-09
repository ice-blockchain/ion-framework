// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/status_bar/status_bar_color_wrapper.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/views/components/story_viewer/components/header/story_viewer_header.dart';
import 'package:ion/generated/assets.gen.dart';

class StoryUnavailable extends StatelessWidget {
  const StoryUnavailable({
    required this.post,
    super.key,
  });

  final ModifiablePostEntity post;

  @override
  Widget build(BuildContext context) {
    final fixedTop = MediaQuery.paddingOf(context).top;

    final footerHeight = 82.0.s;
    return StatusBarColorWrapper.light(
      child: ColoredBox(
        color: context.theme.appColors.primaryText,
        child: Padding(
          padding: EdgeInsetsDirectional.only(top: fixedTop, bottom: footerHeight),
          child: SizedBox(
            child: ColoredBox(
              color: context.theme.appColors.postContent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.svg.iconFeedUnavailable.icon(
                          size: 32.s,
                          color: context.theme.appColors.onTertiaryFill,
                        ),
                        SizedBox(height: 6.s),
                        Text(
                          context.i18n.story_reply_not_available_sender,
                          style: context.theme.appTextThemes.body2.copyWith(
                            color: context.theme.appColors.onTertiaryFill,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StoryViewerHeader(currentPost: post),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
