// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/tokenized_communities/views/components/cards/components/token_avatar.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TokenCreatorTile extends StatelessWidget {
  const TokenCreatorTile({
    required this.creator,
    this.nameColor,
    this.handleColor,
    super.key,
  });

  final Creator creator;
  final Color? nameColor;
  final Color? handleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TokenAvatar(
                imageUrl: creator.avatar,
                containerSize: Size.square(30.s),
                imageSize: Size.square(30.s),
                innerBorderRadius: 10.s,
                outerBorderRadius: 10.s,
                borderWidth: 0,
              ),
              SizedBox(width: 8.0.s),
              _CreatorDetails(
                name: creator.display,
                handle: creator.name,
                verified: creator.verified,
                nameColor: nameColor,
                handleColor: handleColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatorDetails extends StatelessWidget {
  const _CreatorDetails({
    required this.name,
    required this.handle,
    required this.verified,
    this.nameColor,
    this.handleColor,
  });
  final String name;
  final String handle;
  final bool verified;
  final Color? nameColor;
  final Color? handleColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final texts = context.theme.appTextThemes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              name,
              style: texts.subtitle3.copyWith(
                color: nameColor ?? colors.primaryText,
              ),
              strutStyle: const StrutStyle(forceStrutHeight: true),
            ),
            if (verified) ...[
              SizedBox(width: 4.0.s),
              Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
            ],
          ],
        ),
        Text(
          prefixUsername(username: handle, context: context),
          style: texts.caption.copyWith(color: handleColor ?? colors.quaternaryText),
        ),
      ],
    );
  }
}
