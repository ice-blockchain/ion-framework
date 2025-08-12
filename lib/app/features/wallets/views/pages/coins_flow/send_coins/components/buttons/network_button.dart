// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/generated/assets.gen.dart';

class NetworkButton extends StatelessWidget {
  const NetworkButton({
    required this.onTap,
    required this.network,
    super.key,
  });

  final VoidCallback onTap;
  final NetworkData network;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.strokeElements),
        borderRadius: BorderRadius.circular(16.0.s),
        color: colors.secondaryBackground,
      ),
      child: ListItem(
        contentPadding: EdgeInsetsDirectional.only(
          start: ScreenSideOffset.defaultSmallMargin,
          end: 8.0.s,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.i18n.wallet_network,
              style: textTheme.caption3.copyWith(
                color: colors.secondaryText,
              ),
            ),
            SizedBox(height: 4.0.s),
            Row(
              children: [
                NetworkIconWidget(
                  type: WalletItemIconType.small(),
                  imageUrl: network.image,
                ),
                SizedBox(width: 10.0.s),
                Expanded(
                  child: Text(
                    network.displayName,
                    style: textTheme.body,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        onTap: onTap,
        trailing: Padding(
          padding: EdgeInsets.all(8.0.s),
          child: Assets.svg.iconArrowDown.icon(),
        ),
      ),
    );
  }
}
