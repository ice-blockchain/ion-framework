// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class LatestTradesEmpty extends StatelessWidget {
  const LatestTradesEmpty({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: 16.s),
        child: Column(
          children: [
            Assets.svg.walletIconWalletEmptyhistory.icon(size: 60.s),
            SizedBox(height: 8.s),
            Text(
              context.i18n.latest_trades_empty,
              style: context.theme.appTextThemes.body2.copyWith(
                color: context.theme.appColors.tertiaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
