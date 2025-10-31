// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/pages/creator_tokens/models/creator_tokens_tab_type.dart';
import 'package:ion/generated/assets.gen.dart';

class CreatorTokensTabHeader extends StatelessWidget {
  const CreatorTokensTabHeader({
    required this.tabType,
    super.key,
  });

  final CreatorTokensTabType tabType;

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0.s),
        child: Row(
          children: [
            SvgPicture.asset(
              tabType.iconAsset,
              width: 16.0.s,
              height: 16.0.s,
              colorFilter: ColorFilter.mode(
                context.theme.appColors.onTertiaryBackground,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 6.0.s),
            Text(
              tabType.getContentPageTitle(context),
              style: context.theme.appTextThemes.subtitle3.copyWith(
                color: context.theme.appColors.onTertiaryBackground,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                // TODO: Implement search functionality
              },
              icon: Assets.svg.iconFieldSearch.icon(
                size: 16.0.s,
                color: context.theme.appColors.onTertiaryBackground,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
