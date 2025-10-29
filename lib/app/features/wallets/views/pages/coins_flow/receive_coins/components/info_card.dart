// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/generated/assets.gen.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0.s, horizontal: 18.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
        border: Border.all(
          width: 1.s,
          color: context.theme.appColors.onSecondaryBackground,
        ),
      ),
      child: Row(
        children: [
          Assets.svg.iconBlockInformation.icon(
            size: 20.s,
            color: context.theme.appColors.primaryAccent,
          ),
          SizedBox(width: 10.0.s),
          Expanded(
            child: Text(
              context.i18n.wallet_receive_info,
              style: context.theme.appTextThemes.caption2.copyWith(
                color: context.theme.appColors.primaryAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
