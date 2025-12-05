// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/checkbox/labeled_checkbox.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/tokenized_communities/providers/buy_community_token_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/utils/crypto_amount_converter.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/continue_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/slippage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/swap_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/token_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/features/wallets/views/utils/amount_parser.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';

class TradeCommunityTokenDialog extends HookConsumerWidget {
  const TradeCommunityTokenDialog({
    required this.externalAddress,
    super.key,
  });

  final String externalAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tradeCommunityTokenControllerProvider(externalAddress));
    final controller = ref.read(tradeCommunityTokenControllerProvider(externalAddress).notifier);

    final communityTokenAsync = ref.watch(tokenMarketInfoProvider(externalAddress));
    final supportedTokensAsync = ref.watch(supportedSwapTokensProvider);
    final userPreviewData = ref.watch(userPreviewDataProvider(externalAddress));

    final amountController = useTextEditingController();
    final quoteController = useTextEditingController();
    final shouldSharePost = useState(true);

    useAmountListener(amountController, controller, state.amount);
    useQuoteDisplay(quoteController, state.quoteAmount, isQuoting: state.isQuoting);

    ref
      ..displayErrors(
        buyCommunityTokenNotifierProvider(externalAddress),
        excludedExceptions: excludedPasskeyExceptions,
      )
      ..listenSuccess<String?>(
        buyCommunityTokenNotifierProvider(externalAddress),
        (String? txHash) {
          if (context.mounted) {
            Navigator.of(context).pop();
            final rootNavigator = Navigator.of(context, rootNavigator: true);
            ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
              SnackBar(
                content: Text('Buy transaction submitted${txHash != null ? ': $txHash' : ''}'),
              ),
            );
          }
        },
      );

    final tokenInfo = communityTokenAsync.valueOrNull;
    final userData = userPreviewData.valueOrNull;

    // Use token info if available, otherwise fallback to user data
    final tokenTitle = tokenInfo?.title ??
        userData?.data.trimmedDisplayName ??
        userData?.data.name ??
        externalAddress;
    final communityAvatar = tokenInfo?.imageUrl ?? userData?.data.avatarUrl;

    final communityCoinsGroup = CoinsGroup(
      name: tokenTitle,
      iconUrl: communityAvatar,
      symbolGroup: tokenTitle,
      abbreviation: tokenTitle,
      coins: [],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0.s),
          child: NavigationAppBar.screen(
            title: Text(context.i18n.wallet_swap),
            actions: const [
              SlippageAction(),
            ],
          ),
        ),
        Stack(
          children: [
            Column(
              children: [
                TokenCard(
                  type: CoinSwapType.sell,
                  controller: amountController,
                  coinsGroup: state.paymentCoinsGroup,
                  network: state.targetNetwork,
                  onTap: () => _showTokenSelectionSheet(
                    context,
                    controller,
                    supportedTokensAsync,
                  ),
                  onPercentageChanged: controller.setAmountByPercentage,
                ),
                SizedBox(height: 10.0.s),
                TokenCard(
                  type: CoinSwapType.buy,
                  coinsGroup: communityCoinsGroup,
                  controller: quoteController,
                  onTap: () {},
                ),
              ],
            ),
            PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              bottom: 0,
              child: SwapButton(
                onTap: () {},
              ),
            ),
          ],
        ),
        SizedBox(height: 29.0.s),
        LabeledCheckbox(
          isChecked: shouldSharePost.value,
          label: context.i18n.wallet_swap_confirmation_automatically_share_post_about_trade,
          onChanged: (value) {
            shouldSharePost.value = value;
          },
        ),
        SizedBox(height: 16.0.s),
        ContinueButton(
          isEnabled: state.amount > 0 &&
              state.targetWallet != null &&
              !state.isQuoting &&
              state.selectedPaymentToken != null,
          onPressed: () => _handleBuyButtonPress(context, ref, externalAddress),
        ),
        SizedBox(
          height: 16.0.s,
        ),
      ],
    );
  }

  void _showTokenSelectionSheet(
    BuildContext context,
    TradeCommunityTokenController controller,
    AsyncValue<List<CoinData>> supportedTokensAsync,
  ) {
    if (supportedTokensAsync.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tokens: ${supportedTokensAsync.error}'),
        ),
      );
      return;
    }

    final tokens = supportedTokensAsync.valueOrNull ?? <CoinData>[];
    if (tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No supported tokens available')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: tokens.length,
        itemBuilder: (context, index) {
          final token = tokens[index];
          return ListTile(
            leading: Image.network(
              token.iconUrl,
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 24,
                height: 24,
              ),
            ),
            title: Text(token.name),
            subtitle: Text(token.symbolGroup),
            onTap: () {
              controller.selectPaymentToken(token);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  Future<void> _handleBuyButtonPress(
    BuildContext context,
    WidgetRef ref,
    String communityPubkey,
  ) async {
    final state = ref.read(tradeCommunityTokenControllerProvider(communityPubkey));
    if (state.targetWallet == null || state.selectedPaymentToken == null) return;

    await guardPasskeyDialog(
      context,
      (child) => RiverpodUserActionSignerRequestBuilder(
        provider: buyCommunityTokenNotifierProvider(communityPubkey),
        request: (signer) async {
          await ref.read(buyCommunityTokenNotifierProvider(communityPubkey).notifier).buy(signer);
        },
        child: child,
      ),
    );
  }

  void useAmountListener(
    TextEditingController amountController,
    TradeCommunityTokenController controller,
    double currentAmount,
  ) {
    final isUpdatingFromState = useRef(false);

    useEffect(
      () {
        void listener() {
          if (isUpdatingFromState.value) return;

          final val = parseAmount(amountController.text) ?? 0;
          controller.setAmount(val);
        }

        amountController.addListener(listener);
        return () => amountController.removeListener(listener);
      },
      [amountController, controller],
    );

    useEffect(
      () {
        final currentText = parseAmount(amountController.text) ?? 0;
        if ((currentText - currentAmount).abs() > 0.0001) {
          isUpdatingFromState.value = true;
          amountController.text = currentAmount.toString();
          isUpdatingFromState.value = false;
        }
        return null;
      },
      [currentAmount, amountController],
    );
  }

  void useQuoteDisplay(
    TextEditingController quoteController,
    BigInt? quoteAmount, {
    required bool isQuoting,
  }) {
    useEffect(
      () {
        if (quoteAmount != null && !isQuoting) {
          final quoteValue = fromBlockchainUnits(quoteAmount.toString(), 18).toString();
          if (quoteController.text != quoteValue) {
            quoteController.text = quoteValue;
          }
        } else if (quoteAmount == null && quoteController.text.isNotEmpty) {
          quoteController.clear();
        }
        return null;
      },
      [quoteAmount, isQuoting, quoteController],
    );
  }
}
