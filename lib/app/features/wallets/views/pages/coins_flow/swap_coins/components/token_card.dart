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
import 'package:ion/app/features/wallets/views/components/coin_icon_with_network.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/sum_percentage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/hooks/use_validate_amount.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/providers/swap_coins_controller_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/utils/swap_constants.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/app/utils/string.dart';
import 'package:ion/app/utils/text_input_formatters.dart';
import 'package:ion/generated/assets.gen.dart';

class TokenCard extends HookConsumerWidget {
  const TokenCard({
    required this.type,
    required this.onTap,
    this.onValidationError,
    this.coinsGroup,
    this.network,
    this.controller,
    this.onPercentageChanged,
    this.isReadOnly,
    this.avatarWidget,
    this.showSelectButton = true,
    this.showArrow = true,
    this.skipValidation = false,
    this.enabled = true,
    this.skipAmountFormatting = false,
    this.isError = false,
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
  final bool isError;
  final bool enabled;
  final bool skipAmountFormatting;
  final ValueChanged<String?>? onValidationError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
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

    useValidateAmount(
      controller: controller,
      focusNode: focusNode,
      coinForNetwork: coinForNetwork,
      coinsGroup: coinsGroup,
      onValidationError: onValidationError,
      context: context,
      skipValidation: skipValidation,
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

              final decimals = coinForNetwork?.coin.decimals ?? SwapConstants.defaultDecimals;
              final formatted = parsed.formatWithDecimals(decimals);
              if (controller!.text == formatted) return;

              controller!.text = formatted;
            });
          }
        }

        focusNode.addListener(formatAmount);
        return () => focusNode.removeListener(formatAmount);
      },
      [focusNode, controller, isReadOnly, skipAmountFormatting, coinForNetwork],
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
          _TokenTypeHeader(
            type: type,
            coinsGroup: coinsGroup,
            network: network,
            onPercentageChanged: onPercentageChanged,
          ),
          SizedBox(
            height: 16.0.s,
          ),
          _TokenCardContent(
            onTap: onTap,
            iconUrl: coinsGroup?.iconUrl,
            coinsGroup: coinsGroup,
            network: network,
            avatarWidget: avatarWidget,
            showArrow: showArrow,
            isReadOnly: isReadOnly,
            controller: controller,
            showSelectButton: showSelectButton,
            isError: isError,
            enabled: enabled,
            focusNode: focusNode,
            coinForNetwork: coinForNetwork,
            skipValidation: skipValidation,
          ),
          SizedBox(
            height: 8.0.s,
          ),
          _TokenCardFooter(
            isError: isError,
            coinForNetwork: coinForNetwork,
            coinsGroup: coinsGroup,
            enteredAmountUSD: enteredAmountUSD,
          ),
        ],
      ),
    );
  }
}

class _TokenTypeHeader extends HookConsumerWidget {
  const _TokenTypeHeader({
    required this.type,
    required this.coinsGroup,
    required this.network,
    required this.onPercentageChanged,
  });
  final CoinsGroup? coinsGroup;
  final NetworkData? network;
  final CoinSwapType type;
  final ValueChanged<int>? onPercentageChanged;

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

    return Row(
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
                text: context.i18n.wallet_max.capitalize(),
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
    );
  }
}

class _TokenCardContent extends StatelessWidget {
  const _TokenCardContent({
    required this.onTap,
    required this.iconUrl,
    required this.coinsGroup,
    required this.network,
    required this.avatarWidget,
    required this.showArrow,
    required this.controller,
    required this.showSelectButton,
    required this.isError,
    required this.enabled,
    required this.focusNode,
    required this.coinForNetwork,
    required this.skipValidation,
    this.isReadOnly,
  });

  final VoidCallback onTap;
  final String? iconUrl;
  final CoinsGroup? coinsGroup;
  final NetworkData? network;
  final Widget? avatarWidget;
  final bool showArrow;
  final bool? isReadOnly;
  final TextEditingController? controller;
  final bool showSelectButton;
  final bool isError;
  final bool enabled;
  final bool skipValidation;
  final FocusNode? focusNode;
  final CoinInWalletData? coinForNetwork;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;
    final iconUrl = coinsGroup?.iconUrl;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (iconUrl != null && coinsGroup != null)
            Flexible(
              child: Row(
                spacing: 10.0.s,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (network != null)
                    CoinIconWithNetwork.small(
                      iconUrl,
                      network: network!,
                      showPlaceholder: true,
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
                          errorBuilder: avatarWidget != null ? (_, __, ___) => avatarWidget! : null,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Column(
                      spacing: 2.0.s,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                coinsGroup!.abbreviation,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: textStyles.body.copyWith(
                                  color: colors.primaryText,
                                ),
                              ),
                            ),
                            if (showArrow) ...[
                              SizedBox(
                                width: 4.0.s,
                              ),
                              Assets.svg.iconArrowDown.icon(
                                color: colors.sharkText,
                                size: 12.0.s,
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
                  ),
                ],
              ),
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
                          network?.displayName ?? '',
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
                style: textStyles.headline2.copyWith(
                  color: isError ? colors.attentionRed : colors.primaryText,
                ),
                cursorHeight: 24.0.s,
                cursorWidth: 3.0.s,
                cursorRadius: Radius.circular(0.s),
                enabled: enabled,
                inputFormatters: [
                  CoinInputFormatter(
                    maxDecimals: coinForNetwork?.coin.decimals ?? 2,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenCardFooter extends StatelessWidget {
  const _TokenCardFooter({
    required this.isError,
    required this.coinForNetwork,
    required this.coinsGroup,
    required this.enteredAmountUSD,
  });

  final bool isError;
  final CoinInWalletData? coinForNetwork;
  final CoinsGroup? coinsGroup;
  final String enteredAmountUSD;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Assets.svg.iconWallet.icon(
                color: isError ? colors.attentionRed : colors.tertiaryText,
                size: 12.0.s,
              ),
              SizedBox(
                width: 4.0.s,
              ),
              Flexible(
                child: Builder(
                  builder: (context) {
                    final maxValue = coinForNetwork?.amount;
                    final decimals = coinForNetwork?.coin.decimals ?? SwapConstants.defaultDecimals;

                    return Text(
                      maxValue != null
                          ? '${maxValue.formatWithDecimals(decimals)} ${coinsGroup!.abbreviation}'
                          : '0.00',
                      style: textStyles.caption2.copyWith(
                        color: isError ? colors.attentionRed : colors.tertiaryText,
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
    );
  }
}
