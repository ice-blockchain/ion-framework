// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/components/info/info_modal.dart';
import 'package:ion/app/components/info/info_type.dart';
import 'package:ion/app/components/tooltip/copied_tooltip.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/providers/receive_coins_form_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_button/navigation_button.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:ion/generated/assets.gen.dart';

class CoinAddressTile extends HookConsumerWidget {
  const CoinAddressTile({super.key});

  static double get buttonSize => 36.0.s;

  static double get paddingVertical => 30.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(receiveCoinsFormControllerProvider);
    final coinsGroup = state.selectedCoin!;
    final address = state.address ?? '';

    final isCopied = useState<bool>(false);
    final tooltipLeftPosition = useState<double>(0);

    return Container(
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 16.0.s,
        vertical: paddingVertical,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 6.0.s,
                  children: [
                    CoinIconWidget(imageUrl: coinsGroup.iconUrl, type: WalletItemIconType.small()),
                    Flexible(
                      child: Text(
                        context.i18n.wallet_coin_address(coinsGroup.abbreviation),
                        style: context.theme.appTextThemes.body.copyWith(
                          color: context.theme.appColors.primaryText,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async => showSimpleBottomSheet<void>(
                        context: ref.context,
                        child: const InfoModal(
                          infoType: InfoType.addressConfirmation,
                        ),
                      ),
                      child: Assets.svg.iconBlockInformation.icon(size: 20.0.s),
                    ),
                  ],
                ),
                SizedBox(height: 7.0.s),
                Text(
                  shortenAddress(address),
                  style: context.theme.appTextThemes.caption.copyWith(
                    color: context.theme.appColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              NavigationButton(
                icon: Assets.svg.iconBlockCopyBlue.icon(
                  color: context.theme.appColors.primaryText,
                ),
                size: buttonSize,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: address));

                  isCopied.value = true;

                  await Future<void>.delayed(const Duration(seconds: 3)).then((_) {
                    isCopied.value = false;
                  });
                },
              ),
              PositionedDirectional(
                top: -paddingVertical,
                start: tooltipLeftPosition.value,
                child: Opacity(
                  opacity: isCopied.value ? 1 : 0,
                  child: CopiedTooltip(
                    onLayout: (Size size) {
                      tooltipLeftPosition.value = (buttonSize - size.width) / 2;
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 16.0.s),
          NavigationButton(
            size: buttonSize,
            icon: Assets.svg.iconButtonQrcode.icon(
              color: context.theme.appColors.primaryText,
            ),
            onPressed: () {
              ShareAddressCoinDetailsRoute().push<void>(context);
            },
          ),
        ],
      ),
    );
  }
}
