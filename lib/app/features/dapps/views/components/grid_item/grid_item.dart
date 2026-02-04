// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/text/inline_badge_text.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/dapps/model/dapp_data.f.dart';
import 'package:ion/app/features/dapps/views/components/favourite_icon/favorite_icon.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

class GridItem extends HookWidget {
  const GridItem({
    required this.dAppData,
    super.key,
    this.showIsFavourite = false,
    this.showTips = true,
  });

  final DAppData dAppData;
  final bool showIsFavourite;
  final bool showTips;

  @override
  Widget build(BuildContext context) {
    final isFavourite = useState(dAppData.isFavourite);
    return InkWell(
      onTap: () => DAppDetailsRoute(dappId: dAppData.identifier).push<void>(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48.0.s,
            height: 48.0.s,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0.s),
            ),
            child: dAppData.iconImage.icon(size: 48.0.s),
          ),
          SizedBox(width: 10.0.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InlineBadgeText(
                  titleSpan: TextSpan(text: dAppData.title),
                  badges: dAppData.isVerified
                      ? [
                          IconTheme(
                            data: IconThemeData(
                              size: 16.0.s,
                              color: context.theme.appColors.onTertiaryBackground,
                            ),
                            child: Assets.svg.iconBadgeVerify.icon(size: 16.0.s),
                          ),
                        ]
                      : const <Widget>[],
                  gap: 4.0.s,
                  style: context.theme.appTextThemes.body.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
                Text(
                  dAppData.description ?? '',
                  style: context.theme.appTextThemes.caption3.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
                if (showTips)
                  Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          size: 12.0.s,
                          color: context.theme.appColors.onTertiaryBackground,
                        ),
                        child: Assets.svg.iconButtonIceStroke.icon(size: 12.0.s),
                      ),
                      if (dAppData.value != null)
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 3.0.s),
                          child: Text(
                            formatDouble(dAppData.value!),
                            style: context.theme.appTextThemes.caption3.copyWith(
                              color: context.theme.appColors.tertiaryText,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (showIsFavourite)
            FavouriteIcon(
              isFavourite: isFavourite.value,
              onTap: () {
                isFavourite.value = !isFavourite.value;
              },
            ),
        ],
      ),
    );
  }
}
