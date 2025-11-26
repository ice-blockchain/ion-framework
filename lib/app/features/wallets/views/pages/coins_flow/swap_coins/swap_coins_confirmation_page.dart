// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/wallets/hooks/use_check_wallet_address_available.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/send_coins_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

// TODO(ice-erebus): add actual data
class SwapCoinsConfirmationPage extends HookConsumerWidget {
  const SwapCoinsConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMoreDetails = useState(false);
    final sellCoins = ref.watch(swapCoinsControllerProvider).sellCoin;
    final sellNetwork = ref.watch(swapCoinsControllerProvider).sellNetwork;
    final buyCoins = ref.watch(swapCoinsControllerProvider).buyCoin;
    final buyNetwork = ref.watch(swapCoinsControllerProvider).buyNetwork;

    final sellAddress = useState<String?>(null);
    final buyAddress = useState<String?>(null);

    if (sellCoins == null || buyCoins == null || sellNetwork == null || buyNetwork == null) {
      return const Scaffold(
        body: Center(
          child: Text('Missing coin or network data'),
        ),
      );
    }

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.s),
              child: NavigationAppBar.screen(
                title: Text(context.i18n.wallet_swap_confirmation_title),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Assets.svg.iconBackArrow.icon(
                    color: context.theme.appColors.primaryText,
                    size: 24.0.s,
                  ),
                ),
              ),
            ),
            _SwapTokensSection(
              sellCoins: sellCoins,
              sellNetwork: sellNetwork,
              buyCoins: buyCoins,
              buyNetwork: buyNetwork,
            ),
            SizedBox(height: 16.0.s),
            _SwapDetailsSection(
              showMoreDetails: showMoreDetails.value,
              onToggleDetails: () {
                showMoreDetails.value = !showMoreDetails.value;
              },
            ),
            SizedBox(height: 32.0.s),
            _SwapButton(
              userSellAddress: sellAddress.value,
              userBuyAddress: buyAddress.value,
            ),
            SizedBox(height: 16.0.s),
          ],
        ),
      ),
    );
  }
}

class _SwapTokensSection extends StatelessWidget {
  const _SwapTokensSection({
    required this.sellCoins,
    required this.sellNetwork,
    required this.buyCoins,
    required this.buyNetwork,
  });

  final CoinsGroup sellCoins;
  final NetworkData sellNetwork;
  final CoinsGroup buyCoins;
  final NetworkData buyNetwork;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    return Container(
      padding: EdgeInsets.all(16.0.s),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 38.0.s,
            start: 0.0.s,
            child: Assets.svg.iconSwapArrows.iconWithDimensions(
              color: colors.sheetLine,
              height: 66.0.s,
              width: 34.0.s,
            ),
          ),
          // TODO(ice-erebus): add actual data
          Column(
            children: [
              _TokenRow(
                coinsGroup: sellCoins,
                network: sellNetwork,
                amount: '150,3',
                usdAmount: r'$150,53',
              ),
              SizedBox(height: 40.0.s),
              _TokenRow(
                coinsGroup: buyCoins,
                network: buyNetwork,
                amount: '23000',
                usdAmount: r'$23,000.00',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.coinsGroup,
    required this.network,
    required this.amount,
    required this.usdAmount,
  });

  final CoinsGroup coinsGroup;
  final NetworkData network;
  final String amount;
  final String usdAmount;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Row(
      children: [
        CoinIconWithNetwork.small(
          coinsGroup.iconUrl,
          network: network,
        ),
        SizedBox(width: 12.0.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$amount ${coinsGroup.name}',
                style: textStyles.headline2.copyWith(
                  color: colors.primaryText,
                ),
              ),
              SizedBox(height: 2.0.s),
              Text(
                usdAmount,
                style: textStyles.caption2.copyWith(
                  color: colors.tertiaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// TODO(ice-erebus): add actual data
class _SwapDetailsSection extends StatelessWidget {
  const _SwapDetailsSection({
    required this.showMoreDetails,
    required this.onToggleDetails,
  });

  final bool showMoreDetails;
  final VoidCallback onToggleDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.0.s),
          padding: EdgeInsets.symmetric(
            horizontal: 12.0.s,
            vertical: 12.0.s,
          ),
          decoration: BoxDecoration(
            color: colors.tertiaryBackground,
            borderRadius: BorderRadius.circular(16.0.s),
            border: Border.all(
              color: colors.onTertiaryFill,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              _DetailRow(
                label: context.i18n.wallet_swap_confirmation_provider,
                value: 'CEX + DEX',
              ),
              _Divider(),
              _DetailRow(
                label: context.i18n.wallet_swap_confirmation_price,
                value: '1 USDT = 158,8 ICE',
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: showMoreDetails
                    ? Column(
                        children: [
                          _Divider(),
                          _DetailRow(
                            isVisible: showMoreDetails,
                            label: context.i18n.wallet_swap_confirmation_price_impact,
                            value: '-8,83%',
                          ),
                          _Divider(),
                          _DetailRow(
                            isVisible: showMoreDetails,
                            label: context.i18n.wallet_swap_confirmation_slippage,
                            value: '1,2%',
                            showInfoIcon: true,
                          ),
                          _Divider(),
                          _DetailRow(
                            isVisible: showMoreDetails,
                            label: context.i18n.wallet_swap_confirmation_network_fee,
                            value: '100.43 ICE',
                          ),
                          _Divider(),
                          _DetailRow(
                            isVisible: showMoreDetails,
                            label: context.i18n.wallet_swap_confirmation_protocol_fee,
                            value: '0.73 USDT',
                            showInfoIcon: true,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        Positioned.fill(
          bottom: -10.0.s,
          child: Container(
            width: double.infinity,
            alignment: Alignment.bottomCenter,
            height: 21.0.s,
            child: GestureDetector(
              onTap: onToggleDetails,
              child: Container(
                width: 75.0.s,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0.s,
                  vertical: 4.0.s,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiaryBackground,
                  borderRadius: BorderRadius.circular(9.0.s),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      showMoreDetails
                          ? context.i18n.wallet_swap_confirmation_less
                          : context.i18n.wallet_swap_confirmation_more,
                      style: textStyles.caption2.copyWith(
                        color: colors.primaryText,
                      ),
                    ),
                    SizedBox(width: 4.0.s),
                    AnimatedRotation(
                      turns: showMoreDetails ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Assets.svg.iconArrowDown.icon(
                        color: colors.primaryText,
                        size: 16.0.s,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isVisible = true,
    this.showInfoIcon = false,
  });

  final String label;
  final String value;
  final bool showInfoIcon;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.0.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: textStyles.body2.copyWith(
                    color: colors.quaternaryText,
                  ),
                ),
                if (showInfoIcon) ...[
                  SizedBox(width: 4.0.s),
                  Assets.svg.iconBlockInformation.icon(
                    color: colors.tertiaryText,
                    size: 16.0.s,
                  ),
                ],
              ],
            ),
            Text(
              value,
              style: textStyles.body2.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Container(
      height: 0.5,
      color: colors.onTertiaryFill,
    );
  }
}

class _SwapButton extends ConsumerWidget {
  const _SwapButton({
    this.userSellAddress,
    this.userBuyAddress,
  });

  final String? userSellAddress;
  final String? userBuyAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Button(
        onPressed: () {
          final sellAddress = userSellAddress;
          final buyAddress = userBuyAddress;

          // TODO(ice-erebus): add actual error handling
          if (sellAddress == null || buyAddress == null) {
            return;
          }

          ref.read(swapCoinsControllerProvider.notifier).swapCoins(
                userBuyAddress: buyAddress,
                userSellAddress: sellAddress,
                onVerifyIdentitySwapCallback: (sendAssetFormData) async {
                  await guardPasskeyDialog(
                    ref.context,
                    (child) {
                      return RiverpodVerifyIdentityRequestBuilder(
                        provider: sendCoinsNotifierProvider,
                        requestWithVerifyIdentity: (
                          OnVerifyIdentity<Map<String, dynamic>> onVerifyIdentity,
                        ) async {
                          await ref.read(sendCoinsNotifierProvider.notifier).send(
                                onVerifyIdentity,
                                sendAssetFormData,
                              );
                        },
                        child: child,
                      );
                    },
                  );
                },
              );

          if (context.mounted) {
            context.pop(true);
          }
        },
        label: Text(
          context.i18n.wallet_swap_confirmation_swap_button,
          style: textStyles.body.copyWith(
            color: colors.secondaryBackground,
          ),
        ),
        backgroundColor: colors.primaryAccent,
        borderRadius: BorderRadius.circular(16.0.s),
        trailingIcon: Assets.svg.iconSwap.icon(
          color: colors.secondaryBackground,
          size: 24.0.s,
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 56.0.s),
          padding: EdgeInsets.symmetric(
            horizontal: 109.0.s,
            vertical: 16.0.s,
          ),
        ),
      ),
    );
  }
}
