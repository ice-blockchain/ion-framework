// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/image/ion_network_image.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/model/nft_data.f.dart';

class NftItem extends StatelessWidget {
  const NftItem({
    required this.nftData,
    this.backgroundColor,
    this.showNetwork = true,
    super.key,
  });

  final NftData nftData;
  final bool showNetwork;
  final Color? backgroundColor;

  static double get imageWidth => 54.0.s;

  static double get imageHeight => 54.0.s;

  @override
  Widget build(BuildContext context) {
    return ListItem(
      title: Text(nftData.name),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('#${nftData.tokenId}'),
          if (showNetwork)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NetworkIconWidget(
                  imageUrl: nftData.network.image,
                  type: WalletItemIconType.tiny(),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 4.0.s, end: 5.0.s),
                  child: Text(
                    nftData.network.displayName,
                    style: context.theme.appTextThemes.caption2.copyWith(
                      color: context.theme.appColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      backgroundColor: backgroundColor ?? context.theme.appColors.tertiaryBackground,
      leading: IonNetworkImage(
        imageUrl: nftData.imageUrl,
        width: imageWidth,
        height: imageHeight,
        fit: BoxFit.fitWidth,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
    );
  }
}
