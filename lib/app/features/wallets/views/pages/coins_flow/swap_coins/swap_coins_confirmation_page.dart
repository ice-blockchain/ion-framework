// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/models/message_notification_state.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/send_coins_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_swap_client/models/swap_quote_info.m.dart';

class SwapCoinsConfirmationPage extends HookConsumerWidget {
  const SwapCoinsConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMoreDetails = useState(false);
    final sellCoins = ref.watch(swapCoinsControllerProvider).sellCoin;
    final sellNetwork = ref.watch(swapCoinsControllerProvider).sellNetwork;
    final buyCoins = ref.watch(swapCoinsControllerProvider).buyCoin;
    final buyNetwork = ref.watch(swapCoinsControllerProvider).buyNetwork;
    final amount = ref.watch(swapCoinsControllerProvider).amount;
    final sellAmount = amount.formatMax6;
    final swapQuoteInfo = ref.watch(swapCoinsControllerProvider).swapQuoteInfo;

    if (sellCoins == null ||
        buyCoins == null ||
        sellNetwork == null ||
        buyNetwork == null ||
        sellAmount == null ||
        swapQuoteInfo == null) {
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
              SizedBox(height: 16.0.s),
              Text(
                context.i18n.wallet_swap_confirmation_missing_coin_or_network_data,
              ),
            ],
          ),
        ),
      );
    }

    final quoteValue = (swapQuoteInfo.priceForSellTokenInBuyToken * amount).toString();

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
              sellAmount: sellAmount,
              buyAmount: quoteValue,
            ),
            SizedBox(height: 16.0.s),
            _SwapDetailsSection(
              showMoreDetails: showMoreDetails.value,
              onToggleDetails: () {
                showMoreDetails.value = !showMoreDetails.value;
              },
            ),
            SizedBox(height: 32.0.s),
            const _SwapButton(),
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
    required this.sellAmount,
    required this.buyAmount,
  });

  final CoinsGroup sellCoins;
  final NetworkData sellNetwork;
  final CoinsGroup buyCoins;
  final NetworkData buyNetwork;
  final String sellAmount;
  final String buyAmount;

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
          Column(
            children: [
              _TokenRow(
                coinsGroup: sellCoins,
                network: sellNetwork,
                amount: sellAmount,
              ),
              SizedBox(height: 40.0.s),
              _TokenRow(
                coinsGroup: buyCoins,
                network: buyNetwork,
                amount: buyAmount,
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
  });

  final CoinsGroup coinsGroup;
  final NetworkData network;
  final String amount;

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
            ],
          ),
        ),
      ],
    );
  }
}

class _SwapDetailsSection extends ConsumerWidget {
  const _SwapDetailsSection({
    required this.showMoreDetails,
    required this.onToggleDetails,
  });

  final bool showMoreDetails;
  final VoidCallback onToggleDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final swapCoinsController = ref.watch(swapCoinsControllerProvider);
    final swapQuoteInfo = swapCoinsController.swapQuoteInfo;
    final sellCoin = swapCoinsController.sellCoin;
    final buyCoin = swapCoinsController.buyCoin;
    final priceImpact = swapQuoteInfo?.swapImpact;
    final slippage = swapQuoteInfo?.slippage;
    final networkFee = swapQuoteInfo?.networkFee;
    final protocolFee = swapQuoteInfo?.protocolFee;
    final isVisibleMoreButton = priceImpact != null || slippage != null || networkFee != null || protocolFee != null;

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
                value: swapQuoteInfo?.type == SwapQuoteInfoType.cexOrDex ? 'CEX + DEX' : 'Bridge',
              ),
              _Divider(),
              _DetailRow(
                label: context.i18n.wallet_swap_confirmation_price,
                value:
                    '1 ${sellCoin?.name} = ${swapQuoteInfo?.priceForSellTokenInBuyToken.formatMax6} ${buyCoin?.name}',
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: showMoreDetails
                    ? Column(
                        children: [
                          if (priceImpact != null) ...[
                            _Divider(),
                            _DetailRow(
                              isVisible: showMoreDetails,
                              label: context.i18n.wallet_swap_confirmation_price_impact,
                              value: '$priceImpact%',
                            ),
                          ],
                          if (slippage != null) ...[
                            _Divider(),
                            _DetailRow(
                              isVisible: showMoreDetails,
                              label: context.i18n.wallet_swap_confirmation_slippage,
                              value: slippage,
                            ),
                          ],
                          if (networkFee != null) ...[
                            _Divider(),
                            _DetailRow(
                              isVisible: showMoreDetails,
                              label: context.i18n.wallet_swap_confirmation_network_fee,
                              value: networkFee,
                            ),
                          ],
                          if (protocolFee != null) ...[
                            _Divider(),
                            _DetailRow(
                              isVisible: showMoreDetails,
                              label: context.i18n.wallet_swap_confirmation_protocol_fee,
                              value: protocolFee,
                            ),
                          ],
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        if (isVisibleMoreButton)
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
  });

  final String label;
  final String value;
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
  const _SwapButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final messageNotificationNotifier = ref.read(messageNotificationNotifierProvider.notifier);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Button(
        onPressed: () async {
          unawaited(
            _showMessage(
              messageNotificationNotifier,
              message: context.i18n.wallet_swapping_coins,
              icon: Assets.svg.iconSwap.icon(
                color: colors.secondaryBackground,
                size: 24.0.s,
              ),
            ),
          );

          final notifier = ref.read(swapCoinsControllerProvider.notifier);

          final isIonBscSwap = await notifier.getIsIonBscSwap();
          final isIonBridgeBscToIon = await notifier.getIsIonBridgeBscToIon();

          if (isIonBscSwap || isIonBridgeBscToIon) {
            if (context.mounted) {
              await guardPasskeyDialog(
                context,
                (child) => RiverpodUserActionSignerRequestBuilder(
                  provider: swapCoinsWithIonBscSwapProvider,
                  request: (signer) async {
                    await ref.read(swapCoinsWithIonBscSwapProvider.notifier).run(
                          userActionSigner: signer,
                          onSwapSuccess: () {
                            _showSuccessMessage(messageNotificationNotifier, context);
                          },
                          onSwapError: () {
                            _showErrorMessage(messageNotificationNotifier, context);
                          },
                        );
                  },
                  child: child,
                ),
              );
            }

            return;
          }

          await notifier.swapCoins(
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
                            form: sendAssetFormData,
                          );
                    },
                    child: child,
                  );
                },
              );
            },
            onSwapError: () {
              _showErrorMessage(messageNotificationNotifier, context);
            },
            onSwapSuccess: () {
              _showSuccessMessage(messageNotificationNotifier, context);
            },
          );
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

  Future<void> _showSuccessMessage(
    MessageNotificationNotifier messageNotificationNotifier,
    BuildContext context,
  ) async {
    final colors = context.theme.appColors;
    await _showMessage(
      messageNotificationNotifier,
      message: context.i18n.wallet_swapped_coins,
      icon: Assets.svg.iconCheckSuccess.icon(
        color: colors.success,
        size: 24.0.s,
      ),
      state: MessageNotificationState.success,
    );
  }

  Future<void> _showErrorMessage(
    MessageNotificationNotifier messageNotificationNotifier,
    BuildContext context,
  ) async {
    final colors = context.theme.appColors;
    await _showMessage(
      messageNotificationNotifier,
      message: context.i18n.wallet_swap_failed,
      icon: Assets.svg.iconBlockKeywarning.icon(
        color: colors.attentionRed,
        size: 24.0.s,
      ),
      state: MessageNotificationState.error,
    );
  }

  Future<void> _showMessage(
    MessageNotificationNotifier notifier, {
    required String message,
    required Widget icon,
    MessageNotificationState state = MessageNotificationState.info,
  }) async {
    notifier.show(
      MessageNotification(
        message: message,
        icon: icon,
        state: state,
      ),
    );
  }
}
