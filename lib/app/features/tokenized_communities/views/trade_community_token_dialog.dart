// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/avatar/story_colored_profile_avatar.dart';
import 'package:ion/app/components/checkbox/labeled_checkbox.dart';
import 'package:ion/app/components/message_notification/models/message_notification.f.dart';
import 'package:ion/app/components/message_notification/models/message_notification_state.dart';
import 'package:ion/app/components/message_notification/providers/message_notification_notifier_provider.r.dart';
import 'package:ion/app/components/restricted_region_unavailable_sheet.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_holdings_tab_provider.r.dart';
import 'package:ion/app/features/feed/providers/user_tokenized_community_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_trade_notifier_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/external_address_type_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_community_token_controller_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/constants.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/tokenized_communities/views/components/suggested_community_avatar.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_dialog_hooks.dart';
import 'package:ion/app/features/tokenized_communities/views/trade_community_token_state.f.dart';
import 'package:ion/app/features/user/providers/user_holdings_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/coin_in_wallet_data.f.dart';
import 'package:ion/app/features/wallets/providers/wallet_data_sync_coordinator_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/continue_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/slippage_action.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/swap_button.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/swap_coins_message_info.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/components/token_card.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/enums/coin_swap_type.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/utils/crypto.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

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
    final externalAddressTypeAsync = eventReference != null
        ? ref
            .watch(ionConnectEntityProvider(eventReference: eventReference!))
            .whenData((entity) => entity?.externalAddressType)
        : ref.watch(externalAddressTypeProvider(externalAddress: externalAddress!));

    if (externalAddressTypeAsync.isLoading || externalAddressTypeAsync.hasError) {
      return const SheetContent(
        body: Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      );
    }

    final resolvedExternalAddressType = externalAddressTypeAsync.valueOrNull;
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
    final showExtendedSwapErrorMessage =
        ref.watch(envProvider.notifier).get<bool>(EnvVariable.SHOW_DEBUG_INFO);

    useOnInit(
      () => ref.read(walletDataSyncCoordinatorProvider).syncWalletData(),
    );

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
    final messageNotificationNotifier = ref.read(messageNotificationNotifierProvider.notifier);

    ref
      ..listenError<String?>(
        communityTokenTradeNotifierProvider(params),
        (error) {
          if (error == null ||
              excludedPasskeyExceptions.contains(error.runtimeType) ||
              error is StateError) {
            return;
          }
          if (!context.mounted) {
            return;
          }

          if (error is RestrictedRegionException) {
            _showRestrictedRegionDialog(context, error);
            return;
          }

          Logger.error(
            error,
            message: '[TradeCommunityTokenDialog] Swap failed | '
                'externalAddress=$resolvedExternalAddress | '
                'eventReference=$eventReference | '
                'mode=${state.mode} | '
                'errorType=${error.runtimeType} | '
                'errorMessage=$error',
          );
          final tokenInfo = ref.read(tokenMarketInfoProvider(resolvedExternalAddress)).valueOrNull;
          final communityTokenName =
              tokenInfo?.marketData.ticker ?? state.communityTokenCoinsGroup?.abbreviation;
          final paymentTokenName = state.selectedPaymentToken?.abbreviation;

          _showErrorMessage(
            messageNotificationNotifier,
            context,
            state.mode,
            paymentTokenName,
            communityTokenName,
            error,
            showExtendedSwapErrorMessage,
          );
        },
      )
      ..listenSuccess<String?>(
        communityTokenTradeNotifierProvider(params),
        (_) {
          if (context.mounted) {
            final tokenInfo =
                ref.read(tokenMarketInfoProvider(resolvedExternalAddress)).valueOrNull;
            final communityTokenName =
                tokenInfo?.marketData.ticker ?? state.communityTokenCoinsGroup?.abbreviation;
            final paymentTokenName = state.selectedPaymentToken?.abbreviation;

            _showSuccessMessage(
              messageNotificationNotifier,
              context,
              state.mode,
              paymentTokenName,
              communityTokenName,
            );
            ref.invalidate(walletViewsDataNotifierProvider);
            _invalidateUserHoldings(ref);
            // Refetch market data (including position) for the token we just bought or sold.
            ref.invalidate(tokenMarketInfoProvider(resolvedExternalAddress));
            // When the payment token was the creator token, refetch its market data too so
            // balance updates (e.g. in the next TC swap) reflect the trade. Skip when the
            // user paid with another token (e.g. BNB, ION).
            if (params.externalAddressType.isContentToken) {
              final creatorTokenExternalAddress =
                  MasterPubkeyResolver.creatorExternalAddressFromExternal(
                resolvedExternalAddress,
              );
              if (state.selectedPaymentToken?.id == creatorTokenExternalAddress) {
                ref.invalidate(tokenMarketInfoProvider(creatorTokenExternalAddress));
              }
            }
            Navigator.of(context).pop();
          }
        },
      );

    final communityAvatarWidget = pubkey != null
        ? StoryColoredProfileAvatar(
            pubkey: pubkey,
            size: 40.0.s,
            borderRadius: BorderRadius.circular(8.0.s),
          )
        : null;

    final communityGroup = state.communityTokenCoinsGroup;
    final validationError = _getTradeValidationError(context, state);

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AppBar(
                state: state,
                controller: controller,
              ),
              if (communityGroup != null)
                _TokenCards(
                  isError: validationError != null,
                  state: state,
                  controller: controller,
                  communityAvatarWidget: communityAvatarWidget,
                  onTokenTap: () => _showTokenSelectionSheet(
                    context,
                    ref,
                    controller,
                    mode: state.mode,
                    externalAddress: resolvedExternalAddress,
                  ),
                ),
              SizedBox(height: 29.0.s),
              if (validationError != null)
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 16.0.s),
                  child: Row(
                    children: [
                      Assets.svg.iconBlockInformation.icon(
                        color: context.theme.appColors.tertiaryText,
                        size: 16.0.s,
                      ),
                      SizedBox(width: 5.0.s),
                      Expanded(
                        child: Text(
                          validationError,
                          style: context.theme.appTextThemes.body2,
                        ),
                      ),
                    ],
                  ),
                )
              else
                _SharePostCheckbox(
                  value: state.shouldSendEvents,
                  onChanged: (value) => controller.setShouldSendEvents(send: value),
                ),
              SizedBox(height: 16.0.s),
              ContinueButton(
                isEnabled: _isContinueButtonEnabled(state) && validationError == null,
                onPressed: () => _handleButtonPress(
                  context,
                  ref,
                  params,
                  state.mode,
                ),
              ),
              const ScreenBottomOffset(),
            ],
          ),
        ),
      ),
    );
  }

  bool _isContinueButtonEnabled(TradeCommunityTokenState state) {
    return (!state.shouldWaitSuggestedDetails ||
            ((state.suggestedDetails?.name.isNotEmpty ?? false) &&
                (state.suggestedDetails?.ticker.isNotEmpty ?? false))) &&
        (state.mode == CommunityTokenTradeMode.buy
            ? _isBuyContinueButtonEnabled(state)
            : _isSellContinueButtonEnabled(state));
  }

  bool _isBuyContinueButtonEnabled(TradeCommunityTokenState state) {
    final selectedPaymentTokenAmount = _selectedPaymentTokenAmount(state);

    return state.amount > 0 &&
        state.targetWallet != null &&
        !state.isQuoting &&
        state.quotePricing != null &&
        state.selectedPaymentToken != null &&
        selectedPaymentTokenAmount != null &&
        selectedPaymentTokenAmount >= state.amount;
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

  String? _getTradeValidationError(BuildContext context, TradeCommunityTokenState state) {
    if (state.amount <= 0) return null;

    if (state.mode == CommunityTokenTradeMode.buy) {
      final maxAmount = _selectedPaymentTokenAmount(state);
      if (maxAmount == null) return null;

      return _insufficientFundsError(
        context: context,
        amount: state.amount,
        maxAmount: maxAmount,
        decimals: state.selectedPaymentToken?.decimals ?? 0,
        abbreviation:
            state.selectedPaymentToken?.abbreviation ?? state.paymentCoinsGroup?.abbreviation ?? '',
      );
    }

    return _insufficientFundsError(
      context: context,
      amount: state.amount,
      maxAmount: state.communityTokenBalance,
      decimals: TokenizedCommunitiesConstants.communityTokenDecimals,
      abbreviation: state.communityTokenCoinsGroup?.abbreviation ?? '',
    );
  }

  double? _selectedPaymentTokenAmount(TradeCommunityTokenState state) {
    return state.paymentCoinsGroup?.coins
        .firstWhereOrNull(
          (CoinInWalletData c) => c.coin.network.id == state.selectedPaymentToken?.network.id,
        )
        ?.amount;
  }

  String? _insufficientFundsError({
    required BuildContext context,
    required double amount,
    required double maxAmount,
    required int decimals,
    required String abbreviation,
  }) {
    final amountRaw = toBlockchainUnits(amount, decimals);
    final maxAmountRaw = toBlockchainUnits(maxAmount, decimals);
    if (amountRaw <= maxAmountRaw) return null;
    return '${context.i18n.wallet_coin_amount_insufficient} $abbreviation'.trimRight();
  }

  Future<void> _showTokenSelectionSheet(
    BuildContext context,
    WidgetRef ref,
    TradeCommunityTokenController controller, {
    required CommunityTokenTradeMode mode,
    required String externalAddress,
  }) async {
    if (!context.mounted) return;
    final selectedCoin = await SelectTradePaymentTokenProfileRoute(
      contentTokenExternalAddress: mode == CommunityTokenTradeMode.buy ? externalAddress : null,
    ).push<CoinData>(context);

    if (!context.mounted) return;
    if (selectedCoin != null) {
      controller.selectPaymentToken(selectedCoin);
    }
  }

  Future<void> _handleButtonPress(
    BuildContext context,
    WidgetRef ref,
    TradeCommunityTokenControllerParams params,
    CommunityTokenTradeMode mode,
  ) async {
    Logger.info(
      '[TradeCommunityTokenDialog] Button pressed | mode=$mode | externalAddress=${params.externalAddress}',
    );

    final state = ref.read(tradeCommunityTokenControllerProvider(params));

    if (state.targetWallet == null || state.selectedPaymentToken == null) {
      Logger.warning(
        '[TradeCommunityTokenDialog] Missing wallet or token | wallet=${state.targetWallet?.id} | token=${state.selectedPaymentToken?.abbreviation}',
      );
      return;
    }

    if (state.shouldWaitSuggestedDetails &&
        ((state.suggestedDetails?.ticker.isEmpty ?? true) ||
            (state.suggestedDetails?.name.isEmpty ?? true))) {
      Logger.warning(
        '[TradeCommunityTokenDialog] Missing suggested details | ticker=${state.suggestedDetails?.ticker} | name=${state.suggestedDetails?.name}',
      );
      return;
    }

    final isBuy = mode == CommunityTokenTradeMode.buy;

    if (isBuy && !_isBuyContinueButtonEnabled(state)) {
      Logger.warning(
        '[TradeCommunityTokenDialog] Buy button not enabled | amount=${state.amount} | quoteReady=${state.quotePricing != null} | isQuoting=${state.isQuoting}',
      );
      return;
    }

    if (!isBuy && !_isSellContinueButtonEnabled(state)) {
      Logger.warning(
        '[TradeCommunityTokenDialog] Sell button not enabled | amount=${state.amount} | balance=${state.communityTokenBalance} | quoteReady=${state.quotePricing != null}',
      );
      return;
    }

    Logger.info(
      '[TradeCommunityTokenDialog] Starting trade operation | mode=$mode | amount=${state.amount} | token=${state.selectedPaymentToken?.abbreviation} | wallet=${state.targetWallet?.id}',
    );

    await guardPasskeyDialog(
      context,
      (child) => RiverpodUserActionSignerRequestBuilder(
        provider: communityTokenTradeNotifierProvider(params),
        request: (signer) async {
          Logger.info(
            '[TradeCommunityTokenDialog] Passkey authenticated, calling trade notifier | mode=$mode',
          );
          final notifier = ref.read(
            communityTokenTradeNotifierProvider(params).notifier,
          );
          if (mode == CommunityTokenTradeMode.buy) {
            Logger.info('[TradeCommunityTokenDialog] Calling buy()');
            await notifier.buy(signer);
            Logger.info('[TradeCommunityTokenDialog] buy() completed');
          } else {
            Logger.info('[TradeCommunityTokenDialog] Calling sell()');
            await notifier.sell(signer);
            Logger.info('[TradeCommunityTokenDialog] sell() completed');
          }
        },
        child: child,
      ),
    );
  }

  void _showSuccessMessage(
    MessageNotificationNotifier messageNotificationNotifier,
    BuildContext context,
    CommunityTokenTradeMode mode,
    String? paymentTokenName,
    String? communityTokenName,
  ) {
    final colors = context.theme.appColors;

    // For buy: selling payment token, buying community token
    // For sell: selling community token, buying payment token
    final sellCoinAbbreviation =
        mode == CommunityTokenTradeMode.buy ? paymentTokenName : communityTokenName;
    final buyCoinAbbreviation =
        mode == CommunityTokenTradeMode.buy ? communityTokenName : paymentTokenName;

    _showMessage(
      messageNotificationNotifier,
      message: context.i18n.wallet_swapped_coins,
      icon: Assets.svg.iconCheckSuccess.icon(
        color: colors.success,
        size: 24.0.s,
      ),
      state: MessageNotificationState.success,
      sellCoinAbbreviation: sellCoinAbbreviation,
      buyCoinAbbreviation: buyCoinAbbreviation,
    );
  }

  void _showErrorMessage(
    MessageNotificationNotifier messageNotificationNotifier,
    BuildContext context,
    CommunityTokenTradeMode mode,
    String? paymentTokenName,
    String? communityTokenName,
    Object error,
    bool showExtendedSwapErrorMessage,
  ) {
    final colors = context.theme.appColors;

    // For buy: selling payment token, buying community token
    // For sell: selling community token, buying payment token
    final sellCoinAbbreviation =
        mode == CommunityTokenTradeMode.buy ? paymentTokenName : communityTokenName;
    final buyCoinAbbreviation =
        mode == CommunityTokenTradeMode.buy ? communityTokenName : paymentTokenName;

    _showMessage(
      messageNotificationNotifier,
      message: showExtendedSwapErrorMessage
          ? _buildTradeErrorMessage(context, error)
          : context.i18n.wallet_swap_failed,
      icon: Assets.svg.iconBlockKeywarning.icon(
        color: colors.attentionRed,
        size: 24.0.s,
      ),
      sellCoinAbbreviation: sellCoinAbbreviation,
      buyCoinAbbreviation: buyCoinAbbreviation,
      state: MessageNotificationState.error,
    );
  }

  String _buildTradeErrorMessage(
    BuildContext context,
    Object error,
  ) {
    final base = context.i18n.wallet_swap_failed;
    final reason = _extractTradeErrorReason(error);
    if (reason.isEmpty) return base;
    return '$base\nReason: $reason';
  }

  String _extractTradeErrorReason(Object error) {
    final raw = error is IONException ? error.message : error.toString();

    final normalized = raw
        .replaceFirst('Community token trade transaction error: ', '')
        .replaceFirst(RegExp(r'^(?:[A-Za-z0-9_]+)?Exception:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^IONException\(code:\s*\d+,\s*message:\s*'), '')
        .replaceFirst(RegExp(r'^(?:error|reason):\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\)$'), '')
        .trim();

    if (normalized.isEmpty) return '';
    const maxLen = 220;
    return normalized.length <= maxLen
        ? normalized
        : '${normalized.substring(0, maxLen).trimRight()}...';
  }

  void _showMessage(
    MessageNotificationNotifier notifier, {
    required String message,
    required Widget icon,
    required String? sellCoinAbbreviation,
    required String? buyCoinAbbreviation,
    MessageNotificationState state = MessageNotificationState.info,
  }) {
    notifier.show(
      MessageNotification(
        message: message,
        icon: icon,
        state: state,
        bottomPadding: 108.0.s,
        suffixWidget: SwapCoinsMessageInfo(
          sellCoinAbbreviation: sellCoinAbbreviation,
          buyCoinAbbreviation: buyCoinAbbreviation,
        ),
      ),
    );
  }

  void _showRestrictedRegionDialog(
    BuildContext context,
    RestrictedRegionException _,
  ) {
    showSimpleBottomSheet<void>(
      context: context,
      isDismissible: false,
      child: RestrictedRegionUnavailableSheet(
        onClose: () {
          Navigator.of(context, rootNavigator: true)
            ..pop()
            ..pop();
        },
      ),
    );
  }

  void _invalidateUserHoldings(WidgetRef ref) {
    final currentPubkey = ref.read(currentPubkeySelectorProvider);
    if (currentPubkey != null) {
      ref
        ..invalidate(userHoldingsTabProvider(currentPubkey))
        ..invalidate(userTokenizedCommunityDataSourceProvider(currentPubkey));
      final userMetadata = ref.read(userMetadataProvider(currentPubkey)).valueOrNull;
      final holderAddress = userMetadata?.toEventReference().toString();
      if (holderAddress != null) {
        ref.invalidate(userHoldingsProvider(holderAddress));
      }
    }
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.state, required this.controller});
  final TradeCommunityTokenState state;
  final TradeCommunityTokenController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0.s),
      child: NavigationAppBar.screen(
        title: Text(context.i18n.wallet_swap),
        actions: [
          SlippageAction(
            slippage: state.slippage,
            defaultSlippage: TokenizedCommunitiesConstants.defaultSlippagePercent,
            onSlippageChanged: controller.setSlippage,
          ),
          SizedBox(
            width: 8.s,
          ),
        ],
      ),
    );
  }
}

class _TokenCards extends HookConsumerWidget {
  const _TokenCards({
    required this.state,
    required this.controller,
    required this.communityAvatarWidget,
    required this.onTokenTap,
    required this.isError,
  });

  final TradeCommunityTokenState state;
  final TradeCommunityTokenController controller;
  final Widget? communityAvatarWidget;
  final VoidCallback onTokenTap;
  final bool isError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bscNetwork = ref.watch(bscNetworkDataProvider).valueOrNull;
    final network = state.targetNetwork ?? bscNetwork;
    final mode = state.mode;
    const creatorTokenDecimals = TokenizedCommunitiesConstants.communityTokenDecimals;
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
                    network: network,
                    onTap: onTokenTap,
                    onPercentageChanged: controller.setAmountByPercentage,
                    skipAmountFormatting: true,
                    skipValidation: true,
                    isError: isError,
                    formattedAmount: state.paymentTokenAmountUSDFormatted,
                  ),
                  SizedBox(height: 10.0.s),
                  TokenCard(
                    type: CoinSwapType.buy,
                    coinsGroup: state.communityTokenCoinsGroup,
                    controller: quoteController,
                    network: network,
                    avatarWidget: communityAvatarWidget,
                    showSelectButton: false,
                    skipAmountFormatting: true,
                    skipValidation: true,
                    enabled: false,
                    showArrow: false,
                    onTap: () {},
                    formattedAmount: state.communityTokenAmountUSDFormatted,
                    customIconWidget: state.shouldWaitSuggestedDetails
                        ? SuggestedCommunityAvatar(
                            pictureUrl: state.suggestedDetails?.picture ?? '',
                            network: network,
                          )
                        : null,
                    isCoinNameLoading: state.shouldWaitSuggestedDetails &&
                        (state.suggestedDetails?.name.isEmpty ?? true),
                  ),
                ]
              : [
                  TokenCard(
                    type: CoinSwapType.sell,
                    controller: amountController,
                    coinsGroup: state.communityTokenCoinsGroup,
                    network: network,
                    avatarWidget: communityAvatarWidget,
                    showSelectButton: false,
                    onPercentageChanged: controller.setAmountByPercentage,
                    skipAmountFormatting: true,
                    skipValidation: true,
                    showArrow: false,
                    onTap: () {},
                    isError: isError,
                    formattedAmount: state.communityTokenAmountUSDFormatted,
                    customIconWidget: state.shouldWaitSuggestedDetails
                        ? SuggestedCommunityAvatar(
                            pictureUrl: state.suggestedDetails?.picture ?? '',
                            network: network,
                          )
                        : null,
                    isCoinNameLoading: state.shouldWaitSuggestedDetails &&
                        (state.suggestedDetails?.name.isEmpty ?? true),
                  ),
                  SizedBox(height: 10.0.s),
                  TokenCard(
                    type: CoinSwapType.buy,
                    controller: quoteController,
                    coinsGroup: state.paymentCoinsGroup,
                    network: network,
                    skipValidation: true,
                    enabled: false,
                    skipAmountFormatting: true,
                    onTap: onTokenTap,
                    formattedAmount: state.paymentTokenQuoteAmountUSDFormatted,
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
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.0.s,
      ),
      child: LabeledCheckbox(
        isChecked: value,
        label: context.i18n.wallet_swap_confirmation_automatically_share_post_about_trade,
        onChanged: onChanged,
        mainAxisAlignment: MainAxisAlignment.start,
        textStyle: context.theme.appTextThemes.body2.copyWith(
          color: context.theme.appColors.sharkText,
        ),
      ),
    );
  }
}
