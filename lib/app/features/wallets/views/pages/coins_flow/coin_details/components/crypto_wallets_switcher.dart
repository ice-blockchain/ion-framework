import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/utils/address.dart';
import 'package:ion_identity_client/ion_identity.dart';

class CryptoWalletSwitcher extends HookWidget {
  const CryptoWalletSwitcher({
    required this.wallets,
    required this.selectedWallet,
    required this.onWalletChanged,
    super.key,
  });

  final List<Wallet> wallets;
  final Wallet? selectedWallet;
  final ValueChanged<Wallet> onWalletChanged;

  @override
  Widget build(BuildContext context) {
    final itemSize = 26.s;

    final radius = 8.s;
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      height: itemSize,
      alignment: Alignment.topCenter,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: ScreenSideOffset.defaultSmallMargin),
        separatorBuilder: (BuildContext context, int index) => SizedBox(width: 8.0.s),
        itemBuilder: (BuildContext context, int index) {
          final wallet = wallets[index];
          return Material(
            borderRadius: borderRadius,
            child: InkWell(
              onTap: () => onWalletChanged(wallet),
              borderRadius: borderRadius,
              child: Ink(
                height: itemSize,
                decoration: BoxDecoration(
                  color: context.theme.appColors.tertiaryBackground,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: _getBorderColor(context, wallet == selectedWallet),
                    width: 1.s,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 8.s,
                  vertical: 4.s,
                ),
                child: Text(
                  shortenAddress(wallet.address!),
                  style: context.theme.appTextThemes.body2
                      .copyWith(color: _getTextColor(context, wallet == selectedWallet)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBorderColor(BuildContext context, bool isSelected) {
    return isSelected
        ? context.theme.appColors.primaryAccent
        : context.theme.appColors.onTertiaryFill;
  }

  Color _getTextColor(BuildContext context, bool isSelected) {
    return isSelected
        ? context.theme.appColors.primaryText
        : context.theme.appColors.onTertiaryBackground;
  }
}
