// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/sum_percentage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/text_input_formatters.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenCard extends HookConsumerWidget {
  const TokenCard({
    required this.type,
    required this.onTap,
    this.coinsGroup,
    this.network,
    this.controller,
    this.onPercentageChanged,
    this.isReadOnly,
    this.avatarWidget,
    this.showSelectButton = true,
    this.showArrow = true,
    this.skipValidation = false,
    this.isInsufficientFundsError = false,
    this.enabled = true,
    this.skipAmountFormatting = false,
    super.key,
  });

  final CoinSwapType type;
  final CoinsGroup? coinsGroup;
  final NetworkData? network;
  final VoidCallback onTap;
  final TextEditingController? controller;
  final ValueChanged<int>? onPercentageChanged;
  final bool? isReadOnly;
  final Widget? avatarWidget;
  final bool showSelectButton;
  final bool showArrow;
  final bool skipValidation;
  final bool isInsufficientFundsError;
  final bool enabled;
  final bool skipAmountFormatting;

  void _onPercentageChanged(int percentage, WidgetRef ref) {
    final coin = coinsGroup?.coins.firstWhereOrNull(
      (c) => c.coin.network.id == network?.id,
    );
    final amount = coin?.amount;
    if (amount == null) return;

    final newAmount = amount * (percentage / 100);
    ref.read(swapCoinsControllerProvider.notifier).setAmount(newAmount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final iconUrl = coinsGroup?.iconUrl;
    final focusNode = useFocusNode();
    final coinForNetwork = coinsGroup?.coins.firstWhereOrNull(
      (CoinInWalletData c) => c.coin.network.id == network?.id,
    );

    final enteredAmountUSD = useMemoized<String>(
      () {
        final text = controller?.text.trim() ?? '';
        final amount = parseAmount(text) ?? 0;
        final priceUSD = coinForNetwork?.coin.priceUSD ?? 0.0;
        final usdValue = amount * priceUSD;

        return formatToCurrency(usdValue);
      },
      [controller?.text, coinForNetwork?.coin.priceUSD],
    );

    useEffect(
      () {
        void formatAmount() {
          if (skipAmountFormatting) return;

          if (!focusNode.hasFocus && !(isReadOnly ?? false)) {
            // Format to 2 decimal places when focus is lost
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Check controller != null inside callback to handle async cases
              if (controller == null) return;

              final currentText = controller!.text.trim();
              if (currentText.isEmpty) return;

              final parsed = parseAmount(currentText);
              if (parsed == null || parsed <= 0) return;

              final formatted = formatDouble(parsed);
              if (controller!.text == formatted) return;

              controller!.text = formatted;
            });
          }
        }

        focusNode.addListener(formatAmount);
        return () => focusNode.removeListener(formatAmount);
      },
      [focusNode, controller, isReadOnly, skipAmountFormatting],
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.0.s,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 12.0.s,
        vertical: 16.0.s,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0.s),
        color: type == CoinSwapType.buy ? colors.tertiaryBackground : Colors.transparent,
        border: type == CoinSwapType.sell
            ? Border.all(
                color: colors.onTertiaryFill,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type == CoinSwapType.sell
                    ? context.i18n.wallet_swap_coins_sell
                    : context.i18n.wallet_swap_coins_buy,
                style: textStyles.subtitle3.copyWith(
                  color: colors.onTertiaryBackground,
                ),
              ),
              if (type == CoinSwapType.sell)
                Row(
                  spacing: 5.0.s,
                  children: [
                    SumPercentageAction(
                      percentage: 25,
                      onPercentageChanged: (percentage) {
                        if (onPercentageChanged != null) {
                          onPercentageChanged!.call(percentage);
                        }

                        _onPercentageChanged(
                          percentage,
                          ref,
                        );
                      },
                    ),
                    SumPercentageAction(
                      percentage: 50,
                      onPercentageChanged: (percentage) {
                        if (onPercentageChanged != null) {
                          onPercentageChanged!.call(percentage);
                        }

                        _onPercentageChanged(
                          percentage,
                          ref,
                        );
                      },
                    ),
                    SumPercentageAction(
                      percentage: 75,
                      onPercentageChanged: (percentage) {
                        if (onPercentageChanged != null) {
                          onPercentageChanged!.call(percentage);
                        }

                        _onPercentageChanged(
                          percentage,
                          ref,
                        );
                      },
                    ),
                    SumPercentageAction(
                      percentage: 100,
                      onPercentageChanged: (percentage) {
                        if (onPercentageChanged != null) {
                          onPercentageChanged!.call(percentage);
                        }

                        _onPercentageChanged(
                          percentage,
                          ref,
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(
            height: 16.0.s,
          ),
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (iconUrl != null && coinsGroup != null)
                  Row(
                    spacing: 10.0.s,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (network != null)
                        CoinIconWithNetwork.small(
                          iconUrl,
                          network: network!,
                        )
                      else
                        SizedBox.square(
                          dimension: 40.0.s,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0.s),
                            child: Image.network(
                              iconUrl,
                              width: 40.0.s,
                              height: 40.0.s,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  avatarWidget != null ? (_, __, ___) => avatarWidget! : null,
                            ),
                          ),
                        ),
                      Column(
                        spacing: 2.0.s,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                coinsGroup!.abbreviation,
                                style: textStyles.body.copyWith(
                                  color: colors.primaryText,
                                ),
                              ),
                              if (showArrow) ...[
                                SizedBox(width: 4.0.s),
                                Assets.svg.iconArrowDown.icon(
                                  color: colors.primaryText,
                                  size: 6.0.s,
                                ),
                              ],
                            ],
                          ),
                          if (network != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
                              decoration: BoxDecoration(
                                color: colors.attentionBlock,
                                borderRadius: BorderRadius.circular(16.0.s),
                              ),
                              child: Text(
                                network?.displayName ?? '',
                                style: textStyles.caption3.copyWith(
                                  color: colors.quaternaryText,
                                  fontSize: 11.0.s,
                                  height: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                else if (avatarWidget != null && coinsGroup != null)
                  Row(
                    spacing: 10.0.s,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatarWidget!,
                      Column(
                        spacing: 2.0.s,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coinsGroup!.abbreviation,
                            style: textStyles.body.copyWith(
                              color: colors.primaryText,
                            ),
                          ),
                          if (network != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 2.0.s),
                              decoration: BoxDecoration(
                                color: colors.attentionBlock,
                                borderRadius: BorderRadius.circular(16.0.s),
                              ),
                              child: Text(
                                "${network?.displayName ?? ''} ${context.i18n.wallet_network}",
                                style: textStyles.caption3.copyWith(
                                  color: colors.quaternaryText,
                                  fontSize: 11.0.s,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                else if (showSelectButton)
                  Button(
                    onPressed: onTap,
                    type: ButtonType.outlined,
                    leadingIconOffset: 4.0.s,
                    label: Text(
                      context.i18n.wallet_swap_coins_select_coin,
                      style: textStyles.body.copyWith(
                        color: colors.secondaryBackground,
                      ),
                    ),
                    tintColor: colors.primaryAccent,
                    backgroundColor: colors.primaryAccent,
                    borderRadius: BorderRadius.circular(12.0.s),
                    leadingIcon: Assets.svg.iconCreatecoinNewcoin.icon(
                      color: colors.secondaryBackground,
                      size: 20.0.s,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(128.0.s, 36.0.s),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.0.s,
                        vertical: 6.0.s,
                      ),
                    ),
                  ),
                Expanded(
                  child: SizedBox(
                    width: 150.0.s,
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      readOnly: isReadOnly ?? coinsGroup == null,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autovalidateMode: AutovalidateMode.always,
                      style: textStyles.headline2.copyWith(
                        color: isInsufficientFundsError ? colors.attentionRed : colors.primaryText,
                      ),
                      cursorHeight: 24.0.s,
                      cursorWidth: 3.0.s,
                      cursorRadius: Radius.circular(0.s),
                      enabled: enabled,
                      inputFormatters: [
                        CoinInputFormatter(
                          maxDecimals: 2,
                        ),
                      ],
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: textStyles.headline2.copyWith(
                          color: colors.tertiaryText,
                        ),
                        isDense: true,
                        errorStyle: textStyles.caption2.copyWith(
                          color: colors.attentionRed,
                        ),
                      ),
                      validator: (value) {
                        if (skipValidation) return null;

                        final trimmedValue = value?.trim() ?? '';
                        if (trimmedValue.isEmpty) return null;

                        final parsed = parseAmount(trimmedValue);
                        if (parsed == null) return '';

                        final maxValue = coinForNetwork?.amount;
                        if (maxValue != null && (parsed > maxValue || parsed < 0)) {
                          return context.i18n.wallet_coin_amount_insufficient_funds;
                        } else if (parsed < 0) {
                          return context.i18n.wallet_coin_amount_must_be_positive;
                        }

                        // If we know decimals for the selected network, enforce min amount check

                        final decimals = coinForNetwork?.coin.decimals;
                        if (decimals != null) {
                          final amount = toBlockchainUnits(parsed, decimals);
                          if (amount == BigInt.zero && parsed > 0) {
                            return context.i18n.wallet_coin_amount_too_low_for_sending;
                          }
                        }

                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 8.0.s,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Assets.svg.iconWallet.icon(
                      color: isInsufficientFundsError ? colors.attentionRed : colors.tertiaryText,
                      size: 12.0.s,
                    ),
                    SizedBox(
                      width: 4.0.s,
                    ),
                    Flexible(
                      child: Builder(
                        builder: (context) {
                          final maxValue = coinForNetwork?.amount;

                          return Text(
                            maxValue != null
                                ? '${maxValue.toStringAsFixed(2)} ${coinsGroup!.abbreviation}'
                                : '0.00',
                            style: textStyles.caption2.copyWith(
                              color: isInsufficientFundsError
                                  ? colors.attentionRed
                                  : colors.tertiaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                enteredAmountUSD,
                style: textStyles.caption2.copyWith(
                  color: colors.tertiaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
