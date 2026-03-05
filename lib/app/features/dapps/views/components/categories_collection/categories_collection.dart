// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/generated/assets.gen.dart';

enum DAppsCategory {
  defi,
  marketplaces,
  nft,
  games,
  social,
  utilities,
  other;

  Widget get icon {
    return switch (this) {
      DAppsCategory.defi => Assets.svg.categoriesDefi,
      DAppsCategory.marketplaces => Assets.svg.categoriesMarketplace,
      DAppsCategory.nft => Assets.svg.categoriesNft,
      DAppsCategory.games => Assets.svg.categoriesGames,
      DAppsCategory.social => Assets.svg.categoriesSocial,
      DAppsCategory.utilities => Assets.svg.categoriesUtilites,
      DAppsCategory.other => Assets.svg.categoriesOther,
    }
        .icon(size: 50.0.s);
  }

  String title(BuildContext context) {
    return switch (this) {
      DAppsCategory.defi => context.i18n.dapps_category_defi,
      DAppsCategory.marketplaces => context.i18n.dapps_category_marketplaces,
      DAppsCategory.nft => context.i18n.core_nfts,
      DAppsCategory.games => context.i18n.dapps_category_games,
      DAppsCategory.social => context.i18n.dapps_category_social,
      DAppsCategory.utilities => context.i18n.dapps_category_utilities,
      DAppsCategory.other => context.i18n.dapps_category_other,
    };
  }
}

class CategoriesCollection extends StatelessWidget {
  const CategoriesCollection({super.key});

  static double get itemWidth => 80.0.s;

  static double get itemHeight => 104.0.s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: 8.0.s, top: 3.0.s),
      child: SizedBox(
        height: itemHeight,
        child: ListView.separated(
          restorationId: 'dapps_categories_scroll',
          scrollDirection: Axis.horizontal,
          separatorBuilder: (BuildContext context, int index) => SizedBox(width: 15.0.s),
          padding: EdgeInsets.symmetric(
            horizontal: ScreenSideOffset.defaultSmallMargin,
          ),
          itemCount: DAppsCategory.values.length,
          itemBuilder: (BuildContext context, int index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Button.icon(
                  onPressed: () {
                    DAppsListRoute(
                      title: DAppsCategory.values[index].title(context),
                    ).push<void>(context);
                  },
                  icon: DAppsCategory.values[index].icon,
                  size: itemWidth,
                  type: ButtonType.outlined,
                  backgroundColor: context.theme.appColors.tertiaryBackground,
                  borderColor: context.theme.appColors.onTertiaryFill,
                  borderRadius: BorderRadius.circular(12.0.s),
                ),
                Text(
                  DAppsCategory.values[index].title(context),
                  style: context.theme.appTextThemes.body.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
