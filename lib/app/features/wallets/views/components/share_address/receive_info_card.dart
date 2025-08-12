// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/copy/copy_builder.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveInfoCard extends StatelessWidget {
  const ReceiveInfoCard({
    required this.network,
    this.coinsGroup,
    this.walletAddress,
    super.key,
  });

  final NetworkData network;
  final String? walletAddress;
  final CoinsGroup? coinsGroup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.theme.appColors.tertiaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20.0.s),
                if (coinsGroup != null) ...[
                  CoinIconWithNetwork.medium(
                    coinsGroup!.iconUrl,
                    network: network,
                  ),
                  SizedBox(height: 10.0.s),
                  Text(
                    coinsGroup!.abbreviation,
                    style: context.theme.appTextThemes.body.copyWith(
                      color: context.theme.appColors.primaryText,
                    ),
                  ),
                  Text('(${network.displayName})'),
                ] else ...[
                  NetworkIconWidget(
                    type: WalletItemIconType.huge(),
                    imageUrl: network.image,
                  ),
                  SizedBox(height: 10.0.s),
                  Text(
                    network.displayName,
                    style: context.theme.appTextThemes.body.copyWith(
                      color: context.theme.appColors.primaryText,
                    ),
                  ),
                ],
                SizedBox(height: 8.0.s),
                if (walletAddress.isNotEmpty)
                  _AddressDescription(walletAddress!)
                else
                  const _AddressLoader(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressLoader extends StatelessWidget {
  const _AddressLoader();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: _AddressDescription(''),
    );
  }
}

class _AddressDescription extends StatelessWidget {
  const _AddressDescription(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150.0.s,
          height: 150.0.s,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0.s),
            child: QrImageView(
              backgroundColor: context.theme.appColors.secondaryBackground,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: context.theme.appColors.primaryText,
              ),
              embeddedImageStyle: QrEmbeddedImageStyle(size: Size(40.0.s, 40.0.s)),
              embeddedImage: AssetImage(Assets.images.qrCode.qrCodeLogo.path),
              data: address,
              size: 150.0.s,
            ),
          ),
        ),
        SizedBox(height: 8.0.s),
        Text(
          shortenAddress(address),
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.primaryText,
          ),
        ),
        SizedBox(height: 22.0.s),
        CopyBuilder(
          defaultIcon: Assets.svg.iconBlockCopyBlue.icon(),
          defaultText: context.i18n.button_copy,
          defaultBorderColor: context.theme.appColors.strokeElements,
          builder: (context, onCopy, content) => Button(
            minimumSize: Size(148.0.s, 48.0.s),
            leadingIcon: content.icon,
            borderColor: content.borderColor,
            onPressed: () => onCopy(address),
            label: Text(
              content.text,
              style: context.theme.appTextThemes.body.copyWith(
                color: context.theme.appColors.primaryText,
              ),
            ),
            type: ButtonType.secondary,
          ),
        ),
        SizedBox(height: 16.0.s),
      ],
    );
  }
}
