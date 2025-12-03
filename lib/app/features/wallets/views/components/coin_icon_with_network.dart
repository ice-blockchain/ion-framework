// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';

class CoinIconWithNetwork extends StatelessWidget {
  const CoinIconWithNetwork._({
    required this.network,
    required this.coinIconType,
    required this.networkIconType,
    required this.containerSize,
    this.iconUrl,
  });

  factory CoinIconWithNetwork.small(
    String? iconUrl, {
    required NetworkData network,
  }) =>
      CoinIconWithNetwork._(
        iconUrl: iconUrl,
        network: network,
        networkIconType: WalletItemIconType.small(),
        containerSize: 40.0.s,
        coinIconType: WalletItemIconType.big(),
      );

  factory CoinIconWithNetwork.medium(
    String? iconUrl, {
    required NetworkData network,
  }) =>
      CoinIconWithNetwork._(
        iconUrl: iconUrl,
        network: network,
        networkIconType: const WalletItemIconType.custom(size: 20),
        containerSize: 51.0.s,
        coinIconType: WalletItemIconType.huge(),
      );

  final String? iconUrl;
  final NetworkData network;
  final double containerSize;
  final WalletItemIconType coinIconType;
  final WalletItemIconType networkIconType;

  @override
  Widget build(BuildContext context) {
    // Get the network icon size based on type and add 2 to handle the border
    final networkSize = networkIconType.size;
    final networkContainerSize = networkSize + 2.0.s;

    return SizedBox.square(
      dimension: containerSize,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            child: CoinIconWidget(imageUrl: iconUrl, type: coinIconType),
          ),
          PositionedDirectional(
            bottom: 0,
            end: 0,
            child: Container(
              height: networkContainerSize,
              width: networkContainerSize,
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1.0.s,
                  color: context.theme.appColors.onPrimaryAccent,
                ),
                borderRadius: BorderRadius.circular(6.0.s),
              ),
              child: NetworkIconWidget(
                type: networkIconType,
                imageUrl: network.image,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
