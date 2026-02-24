// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/domain/trade_token_resolver.dart';
import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';

enum TradeTokenRole {
  payment,
  wrappedNative,
  ion,
  creator,
  content,
}

enum TradeRouteStepType {
  pancakeSwap,
  bondingCurve,
}

class TradeRouteStep {
  const TradeRouteStep.pancakeSwap({
    required this.fromRole,
    required this.toRole,
  })  : type = TradeRouteStepType.pancakeSwap,
        mode = null,
        externalAddress = null;

  const TradeRouteStep.bondingCurve({
    required this.mode,
    required this.externalAddress,
    required this.fromRole,
    required this.toRole,
  }) : type = TradeRouteStepType.bondingCurve;

  final TradeRouteStepType type;
  final CommunityTokenTradeMode? mode;
  final String? externalAddress;
  final TradeTokenRole fromRole;
  final TradeTokenRole toRole;
}

class TradeRoutePlan {
  const TradeRoutePlan({
    required this.externalAddress,
    required this.externalAddressType,
    required this.creatorExternalAddress,
    required this.steps,
  });

  final String externalAddress;
  final ExternalAddressType externalAddressType;
  final String? creatorExternalAddress;
  final List<TradeRouteStep> steps;
}

class TradeRouteBuilder {
  TradeRouteBuilder({
    required TradeTokenResolver tokenResolver,
  }) : _tokenResolver = tokenResolver;

  final TradeTokenResolver _tokenResolver;

  TradeRoutePlan build({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required CommunityTokenTradeMode mode,
    required String paymentTokenAddress,
    TradeTokenRole? paymentTokenRoleOverride,
    bool isCreatorTokenMissingForContentFirstBuy = false,
  }) {
    final paymentRole = paymentTokenRoleOverride ?? TradeTokenRole.payment;
    final isPaymentIon =
        paymentRole == TradeTokenRole.ion || _tokenResolver.isIonTokenAddress(paymentTokenAddress);
    final isPaymentNative = _tokenResolver.isNativeTokenAddress(paymentTokenAddress);
    final creatorExternalAddress = externalAddressType.isContentToken
        ? MasterPubkeyResolver.creatorExternalAddressFromExternal(externalAddress)
        : null;
    final steps = mode == CommunityTokenTradeMode.buy
        ? _buildBuySteps(
            externalAddress: externalAddress,
            externalAddressType: externalAddressType,
            creatorExternalAddress: creatorExternalAddress,
            paymentRole: paymentRole,
            isPaymentIon: isPaymentIon,
            isPaymentNative: isPaymentNative,
            isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
          )
        : _buildSellSteps(
            externalAddress: externalAddress,
            externalAddressType: externalAddressType,
            creatorExternalAddress: creatorExternalAddress,
            paymentRole: paymentRole,
            isPaymentIon: isPaymentIon,
            isPaymentNative: isPaymentNative,
          );

    return TradeRoutePlan(
      externalAddress: externalAddress,
      externalAddressType: externalAddressType,
      creatorExternalAddress: creatorExternalAddress,
      steps: steps,
    );
  }

  List<TradeRouteStep> _buildBuySteps({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String? creatorExternalAddress,
    required TradeTokenRole paymentRole,
    required bool isPaymentIon,
    required bool isPaymentNative,
    required bool isCreatorTokenMissingForContentFirstBuy,
  }) {
    if (paymentRole == TradeTokenRole.creator && externalAddressType.isContentToken) {
      return [
        TradeRouteStep.bondingCurve(
          mode: CommunityTokenTradeMode.buy,
          externalAddress: externalAddress,
          fromRole: TradeTokenRole.creator,
          toRole: TradeTokenRole.content,
        ),
      ];
    }

    final steps = <TradeRouteStep>[
      if (!isPaymentIon && isPaymentNative)
        const TradeRouteStep.pancakeSwap(
          fromRole: TradeTokenRole.payment,
          toRole: TradeTokenRole.ion,
        ),
      if (!isPaymentIon && !isPaymentNative)
        const TradeRouteStep.pancakeSwap(
          fromRole: TradeTokenRole.payment,
          toRole: TradeTokenRole.wrappedNative,
        ),
      if (!isPaymentIon && !isPaymentNative)
        const TradeRouteStep.pancakeSwap(
          fromRole: TradeTokenRole.wrappedNative,
          toRole: TradeTokenRole.ion,
        ),
      ..._buildBuyBondingCurveSteps(
        externalAddress: externalAddress,
        externalAddressType: externalAddressType,
        creatorExternalAddress: creatorExternalAddress,
        isCreatorTokenMissingForContentFirstBuy: isCreatorTokenMissingForContentFirstBuy,
      ),
    ];
    return steps;
  }

  List<TradeRouteStep> _buildBuyBondingCurveSteps({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String? creatorExternalAddress,
    required bool isCreatorTokenMissingForContentFirstBuy,
  }) {
    if (!externalAddressType.isContentToken) {
      return [
        TradeRouteStep.bondingCurve(
          mode: CommunityTokenTradeMode.buy,
          externalAddress: externalAddress,
          fromRole: TradeTokenRole.ion,
          toRole: TradeTokenRole.creator,
        ),
      ];
    }

    if (isCreatorTokenMissingForContentFirstBuy) {
      return [
        TradeRouteStep.bondingCurve(
          mode: CommunityTokenTradeMode.buy,
          externalAddress: externalAddress,
          fromRole: TradeTokenRole.ion,
          toRole: TradeTokenRole.content,
        ),
      ];
    }

    return [
      TradeRouteStep.bondingCurve(
        mode: CommunityTokenTradeMode.buy,
        externalAddress: creatorExternalAddress,
        fromRole: TradeTokenRole.ion,
        toRole: TradeTokenRole.creator,
      ),
      TradeRouteStep.bondingCurve(
        mode: CommunityTokenTradeMode.buy,
        externalAddress: externalAddress,
        fromRole: TradeTokenRole.creator,
        toRole: TradeTokenRole.content,
      ),
    ];
  }

  List<TradeRouteStep> _buildSellSteps({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String? creatorExternalAddress,
    required TradeTokenRole paymentRole,
    required bool isPaymentIon,
    required bool isPaymentNative,
  }) {
    final steps = <TradeRouteStep>[
      ..._buildSellBondingCurveSteps(
        externalAddress: externalAddress,
        externalAddressType: externalAddressType,
        creatorExternalAddress: creatorExternalAddress,
        paymentRole: paymentRole,
      ),
      if (!isPaymentIon && paymentRole != TradeTokenRole.creator && isPaymentNative)
        const TradeRouteStep.pancakeSwap(
          fromRole: TradeTokenRole.ion,
          toRole: TradeTokenRole.payment,
        ),
      if (!isPaymentIon && paymentRole != TradeTokenRole.creator && !isPaymentNative)
        const TradeRouteStep.pancakeSwap(
          fromRole: TradeTokenRole.ion,
          toRole: TradeTokenRole.wrappedNative,
        ),
      if (!isPaymentIon && paymentRole != TradeTokenRole.creator && !isPaymentNative)
        const TradeRouteStep.pancakeSwap(
          fromRole: TradeTokenRole.wrappedNative,
          toRole: TradeTokenRole.payment,
        ),
    ];
    return steps;
  }

  List<TradeRouteStep> _buildSellBondingCurveSteps({
    required String externalAddress,
    required ExternalAddressType externalAddressType,
    required String? creatorExternalAddress,
    required TradeTokenRole paymentRole,
  }) {
    if (!externalAddressType.isContentToken) {
      return [
        TradeRouteStep.bondingCurve(
          mode: CommunityTokenTradeMode.sell,
          externalAddress: externalAddress,
          fromRole: TradeTokenRole.creator,
          toRole: TradeTokenRole.ion,
        ),
      ];
    }

    final steps = <TradeRouteStep>[
      TradeRouteStep.bondingCurve(
        mode: CommunityTokenTradeMode.sell,
        externalAddress: externalAddress,
        fromRole: TradeTokenRole.content,
        toRole: TradeTokenRole.creator,
      ),
      if (paymentRole != TradeTokenRole.creator)
        TradeRouteStep.bondingCurve(
          mode: CommunityTokenTradeMode.sell,
          externalAddress: creatorExternalAddress,
          fromRole: TradeTokenRole.creator,
          toRole: TradeTokenRole.ion,
        ),
    ];
    return steps;
  }
}
