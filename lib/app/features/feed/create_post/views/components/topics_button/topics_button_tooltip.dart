// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class TopicsButtonTooltip extends StatelessWidget {
  const TopicsButtonTooltip({
    required this.arrow,
    super.key,
  });

  final Widget arrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.s),
          child: arrow,
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.s, vertical: 12.s),
          decoration: BoxDecoration(
            color: context.theme.appColors.primaryBackground,
            borderRadius: BorderRadius.circular(16.s),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Assets.svg.walletChannelPrivate.icon(
                    color: context.theme.appColors.primaryText,
                    size: 20.s,
                  ),
                  SizedBox(width: 2.s),
                  Text(
                    context.i18n.create_post_add_topic_tooltip_title,
                    style: context.theme.appTextThemes.subtitle3,
                  ),
                ],
              ),
              SizedBox(height: 8.s),
              Text(
                context.i18n.create_post_add_topic_tooltip_description,
                style: context.theme.appTextThemes.caption2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
