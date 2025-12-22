// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/components/checkbox/labeled_checkbox.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_trade_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_dialog_hooks.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_state.f.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/continue_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/slippage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/swap_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/token_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class TradeCommunityTokenDialog extends HookConsumerWidget {
  const TradeCommunityTokenDialog({
    this.eventReference,
    this.externalAddress,
    this.initialMode,
    super.key,
  }) : assert(
          (eventReference == null) != (externalAddress == null),
          'Either eventReference or externalAddress must be provided',
        );

  final EventReference? eventReference;
  final String? externalAddress;
  final CommunityTokenTradeMode? initialMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedExternalAddress = externalAddress ?? eventReference!.toString();
    final resolvedExternalAddressType = externalAddress != null
        ? const ExternalAddressType.x()
        : ref
            .watch(ionConnectEntityProvider(eventReference: eventReference!))
            .valueOrNull
            ?.externalAddressType;
    if (resolvedExternalAddressType == null) {
      return const SheetContent(body: SizedBox.shrink());
    }

    final params = (
      externalAddress: resolvedExternalAddress,
      externalAddressType: resolvedExternalAddressType,
      eventReference: eventReference,
    );
    final state = ref.watch(tradeCommunityTokenControllerProvider(params));
    final controller = ref.read(tradeCommunityTokenControllerProvider(params).notifier);

    final initialMode = this.initialMode;
    useOnInit(
      () {
        if (initialMode != null) {
          controller.setMode(initialMode);
        }
      },
      [controller, initialMode],
    );

    final pubkey = eventReference?.masterPubkey ??
        CreatorTokenUtils.tryExtractPubkeyFromExternalAddress(resolvedExternalAddress);
    final supportedTokensAsync = ref.watch(supportedSwapTokensProvider);

    ref
      ..displayErrors(
        communityTokenTradeNotifierProvider(params),
        excludedExceptions: excludedPasskeyExceptions,
      )
      ..listenSuccess<String?>(communityTokenTradeNotifierProvider(params), (String? txHash) {
        if (context.mounted) {
          Navigator.of(context).pop();
          final rootNavigator = Navigator.of(context, rootNavigator: true);
          final message = state.mode == CommunityTokenTradeMode.buy
              ? 'Buy transaction submitted${txHash != null ? ': $txHash' : ''}'
              : 'Sell transaction submitted${txHash != null ? ': $txHash' : ''}';
          ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });

    final communityAvatarWidget = pubkey != null
        ? StoryColoredProfileAvatar(
            pubkey: pubkey,
            size: 40.0.s,
            borderRadius: BorderRadius.circular(8.0.s),
          )
        : null;

    final communityGroup = state.communityTokenCoinsGroup;

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppBar(),
            if (communityGroup != null)
              _TokenCards(
                state: state,
                controller: controller,
                communityTokenGroup: communityGroup,
                supportedTokensAsync: supportedTokensAsync,
                communityAvatarWidget: communityAvatarWidget,
                onTokenTap: () => _showTokenSelectionSheet(
                  context,
                  controller,
                  supportedTokensAsync,
                ),
              ),
            SizedBox(height: 29.0.s),
            _SharePostCheckbox(
              value: state.shouldSendEvents,
              onChanged: (value) => controller.setShouldSendEvents(send: value),
            ),
            SizedBox(height: 16.0.s),
            ContinueButton(
              isEnabled: state.mode == CommunityTokenTradeMode.buy
                  ? _isBuyContinueButtonEnabled(state)
                  : _isSellContinueButtonEnabled(state),
              onPressed: () => _handleButtonPress(
                context,
                ref,
                params,
                state.mode,
              ),
            ),
            SizedBox(height: 16.0.s),
          ],
        ),
      ),
    );
  }

  bool _isBuyContinueButtonEnabled(TradeCommunityTokenState state) {
    return state.amount > 0 &&
        state.targetWallet != null &&
        !state.isQuoting &&
        state.quotePricing != null &&
        state.selectedPaymentToken != null;
  }

  bool _isSellContinueButtonEnabled(TradeCommunityTokenState state) {
    return state.amount > 0 &&
        state.amount <= state.communityTokenBalance &&
        state.targetWallet != null &&
        !state.isQuoting &&
        state.quotePricing != null &&
        state.selectedPaymentToken != null &&
        state.communityTokenCoinsGroup != null;
  }

  Future<void> _showTokenSelectionSheet(
    BuildContext context,
    TradeCommunityTokenController controller,
    AsyncValue<List<CoinData>> supportedTokensAsync,
  ) async {
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

    final selectedCoin = await SelectTradePaymentTokenProfileRoute(
      title: context.i18n.wallet_swap_coins_select_coin,
    ).push<CoinData>(context);

    if (selectedCoin != null && context.mounted) {
      controller.selectPaymentToken(selectedCoin);
    }
  }

  Future<void> _handleButtonPress(
    BuildContext context,
    WidgetRef ref,
    TradeCommunityTokenControllerParams params,
    CommunityTokenTradeMode mode,
  ) async {
    final state = ref.read(tradeCommunityTokenControllerProvider(params));

    if (state.targetWallet == null || state.selectedPaymentToken == null || state.amount <= 0) {
      return;
    }

    await guardPasskeyDialog(
      context,
      (child) => RiverpodUserActionSignerRequestBuilder(
        provider: communityTokenTradeNotifierProvider(params),
        request: (signer) async {
          final notifier = ref.read(
            communityTokenTradeNotifierProvider(params).notifier,
          );
          if (mode == CommunityTokenTradeMode.buy) {
            await notifier.buy(signer);
          } else {
            await notifier.sell(signer);
          }
        },
        child: child,
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: NavigationAppBar.screen(
        title: Text(context.i18n.wallet_swap),
        actions: const [
          SlippageAction(),
        ],
      ),
    );
  }
}

class _TokenCards extends HookConsumerWidget {
  const _TokenCards({
    required this.state,
    required this.controller,
    required this.communityTokenGroup,
    required this.supportedTokensAsync,
    required this.communityAvatarWidget,
    required this.onTokenTap,
  });

  final TradeCommunityTokenState state;
  final TradeCommunityTokenController controller;
  final CoinsGroup communityTokenGroup;
  final AsyncValue<List<CoinData>> supportedTokensAsync;
  final Widget? communityAvatarWidget;
  final VoidCallback onTokenTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = state.mode;
    const creatorTokenDecimals = TokenizedCommunitiesConstants.creatorTokenDecimals;
    final amountController = useTextEditingController();
    final quoteController = useTextEditingController();

    useAmountListener(amountController, controller, state.amount);
    useQuoteDisplay(
      quoteController,
      state.quoteAmount,
      isQuoting: state.isQuoting,
      decimals: mode == CommunityTokenTradeMode.sell
          ? state.selectedPaymentToken?.decimals ?? creatorTokenDecimals
          : creatorTokenDecimals,
    );
    return Stack(
      children: [
        Column(
          children: mode == CommunityTokenTradeMode.buy
              ? [
                  // Buy mode: payment token on top, community token on bottom
                  TokenCard(
                    type: CoinSwapType.sell,
                    controller: amountController,
                    coinsGroup: state.paymentCoinsGroup,
                    network: state.targetNetwork,
                    onTap: onTokenTap,
                    onPercentageChanged: controller.setAmountByPercentage,
                    skipAmountFormatting: true,
                  ),
                  SizedBox(height: 10.0.s),
                  TokenCard(
                    type: CoinSwapType.buy,
                    coinsGroup: communityTokenGroup,
                    controller: quoteController,
                    network: state.targetNetwork,
                    avatarWidget: communityAvatarWidget,
                    showSelectButton: false,
                    showArrow: false,
                    skipValidation: true,
                    enabled: false,
                    onTap: () {},
                  ),
                ]
              : [
                  // Sell mode: community token on top, payment token on bottom
                  TokenCard(
                    type: CoinSwapType.sell,
                    controller: amountController,
                    coinsGroup: state.communityTokenCoinsGroup,
                    network: state.targetNetwork,
                    avatarWidget: communityAvatarWidget,
                    showSelectButton: false,
                    showArrow: false,
                    onPercentageChanged: controller.setAmountByPercentage,
                    skipAmountFormatting: true,
                    onTap: () {},
                  ),
                  SizedBox(height: 10.0.s),
                  TokenCard(
                    type: CoinSwapType.buy,
                    controller: quoteController,
                    coinsGroup: state.paymentCoinsGroup,
                    network: state.targetNetwork,
                    skipValidation: true,
                    enabled: false,
                    onTap: onTokenTap,
                  ),
                ],
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          bottom: 0,
          child: SwapButton(
            onTap: controller.toggleMode,
          ),
        ),
      ],
    );
  }
}

class _SharePostCheckbox extends StatelessWidget {
  const _SharePostCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return LabeledCheckbox(
      isChecked: value,
      label: context.i18n.wallet_swap_confirmation_automatically_share_post_about_trade,
      onChanged: onChanged,
    );
  }
}
