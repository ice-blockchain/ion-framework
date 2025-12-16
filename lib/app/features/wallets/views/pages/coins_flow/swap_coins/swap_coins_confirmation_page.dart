// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/models/message_notification_state.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/wallets/providers/send_coins_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/components/swap_details_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class SwapCoinsConfirmationPage extends ConsumerWidget {
  const SwapCoinsConfirmationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            SwapDetailsCard(
              sellCoins: sellCoins,
              sellNetwork: sellNetwork,
              buyCoins: buyCoins,
              buyNetwork: buyNetwork,
              sellAmount: sellAmount,
              buyAmount: quoteValue,
              swapType: swapQuoteInfo.type,
              priceForSellTokenInBuyToken: swapQuoteInfo.priceForSellTokenInBuyToken,
              sellCoinAbbreviation: sellCoins.abbreviation,
              buyCoinAbbreviation: buyCoins.abbreviation,
              slippage: ref.watch(swapCoinsControllerProvider).slippage,
              priceImpact: swapQuoteInfo.swapImpact,
              networkFee: swapQuoteInfo.networkFee,
              protocolFee: swapQuoteInfo.protocolFee,
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

class _SwapButton extends ConsumerWidget {
  const _SwapButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final messageNotificationNotifier = ref.read(messageNotificationNotifierProvider.notifier);
    final isDisabled = ref.watch(swapCoinsControllerProvider).isSwapLoading;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0.s),
      child: Button(
        disabled: isDisabled,
        onPressed: () async {
          final notifier = ref.read(swapCoinsControllerProvider.notifier);

          final isIonBscSwap = await notifier.getIsIonBscSwap();

          if (isIonBscSwap) {
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
                          onSwapStart: () {},
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
            onSwapStart: () {
              _showStartMessage(messageNotificationNotifier, context);
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

  Future<void> _showStartMessage(
    MessageNotificationNotifier messageNotificationNotifier,
    BuildContext context,
  ) async {
    final colors = context.theme.appColors;

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

    if (context.mounted) {
      await _pop(context);
    }
  }

  Future<void> _pop(BuildContext context) async {
    context.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (context.mounted) {
      context.maybePop();
    }
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
