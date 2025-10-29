// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/copy/copy_builder.dart';
import 'package:ion/app/components/icons/network_icon_widget.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/info_type.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/info/info_modal.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:qr_flutter/qr_flutter.dart';

part 'address_info_container.dart';

part 'wallet_address_qr_code.dart';

class ReceiveInfoCard extends HookWidget {
  const ReceiveInfoCard({
    required this.network,
    this.coinsGroup,
    this.walletAddress,
    super.key,
  });

  final NetworkData network;
  final String? walletAddress;
  final CoinsGroup? coinsGroup;

  /// Since ion provides only personal wallets for use, there is no need
  /// to use the memo/tag field when receiving funds.
  /// However, some services make the memo field mandatory when sending funds.
  /// In these cases, we recommend users use the following text,
  /// as it will be ignored by the blockchain anyway.
  static const String _memoValue = 'Online';

  @override
  Widget build(BuildContext context) {
    final shortAddress = useState<String?>(null);
    useEffect(
      () {
        shortAddress.value = walletAddress != null ? shortenAddress(walletAddress!) : null;
        return null;
      },
      [walletAddress],
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.0.s),
              _ContainerWithBackground(
                padding: EdgeInsets.symmetric(vertical: 20.s),
                child: SizedBox(
                  width: double.infinity,
                  child: _WalletAddressQrCode(
                    network: network,
                    coinsGroup: coinsGroup,
                    walletAddress: walletAddress,
                  ),
                ),
              ),
              SizedBox(height: 12.s),
              if (walletAddress.isNotEmpty && shortAddress.value != null)
                _AddressInfoContainer(
                  title: context.i18n.wallet_address,
                  value: shortAddress.value!,
                  valueToCopy: walletAddress,
                  onTapInfo: () {
                    showSimpleBottomSheet<void>(
                      context: context,
                      child: const InfoModal(
                        infoType: InfoType.walletAddress,
                      ),
                    );
                  },
                )
              else
                Skeleton(
                  child: _AddressInfoContainer(
                    title: context.i18n.wallet_address,
                    value: walletAddress!,
                    onTapInfo: () {},
                  ),
                ),
              if (network.isMemoSupported && walletAddress.isNotEmpty) ...[
                SizedBox(height: 12.s),
                _AddressInfoContainer(
                  title: context.i18n.wallet_memo,
                  value: _memoValue,
                  onTapInfo: () {
                    showSimpleBottomSheet<void>(
                      context: context,
                      child: const InfoModal(
                        infoType: InfoType.memo,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ContainerWithBackground extends StatelessWidget {
  const _ContainerWithBackground({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding ??
            EdgeInsets.symmetric(
              vertical: 12.s,
              horizontal: 16.s,
            ),
        child: child,
      ),
    );
  }
}
