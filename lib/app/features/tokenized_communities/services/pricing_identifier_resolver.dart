// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion/app/services/logger/logger.dart';

typedef TokenExistsResolver = Future<bool> Function();
typedef FatAddressDataResolver = Future<FatAddressV2Data> Function();

class PricingIdentifierResolution {
  const PricingIdentifierResolution({
    required this.pricingIdentifier,
    required this.fatAddressData,
  });

  final String pricingIdentifier;
  final FatAddressV2Data? fatAddressData;
}

class CommunityTokenPricingIdentifierResolver {
  CommunityTokenPricingIdentifierResolver({
    required this.externalAddress,
    required this.externalAddressType,
    required this.tokenExistsResolver,
    required this.fatAddressDataResolver,
  });

  final String externalAddress;
  final ExternalAddressType externalAddressType;
  final TokenExistsResolver tokenExistsResolver;
  final FatAddressDataResolver fatAddressDataResolver;

  PricingIdentifierResolution? _cachedBuyResolution;
  Future<PricingIdentifierResolution>? _buyResolutionInFlight;

  Future<PricingIdentifierResolution> resolve(CommunityTokenTradeMode mode) async {
    if (mode == CommunityTokenTradeMode.sell) {
      return PricingIdentifierResolution(
        pricingIdentifier: externalAddress,
        fatAddressData: null,
      );
    }

    final tokenExists = await tokenExistsResolver();
    if (tokenExists) {
      return PricingIdentifierResolution(
        pricingIdentifier: externalAddress,
        fatAddressData: null,
      );
    }

    final cached = _cachedBuyResolution;
    if (cached != null && cached.pricingIdentifier.isNotEmpty) {
      return cached;
    }

    return _loadAndCacheBuyResolution();
  }

  Future<PricingIdentifierResolution> _loadAndCacheBuyResolution() async {
    final inFlight = _buyResolutionInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    _buyResolutionInFlight = _computeAndCacheBuyResolution();
    return _buyResolutionInFlight!;
  }

  Future<PricingIdentifierResolution> _computeAndCacheBuyResolution() async {
    try {
      final fatAddressData = await fatAddressDataResolver();
      final hex = fatAddressData.toHex();
      if (hex.isNotEmpty) {
        final resolution = PricingIdentifierResolution(
          pricingIdentifier: hex,
          fatAddressData: fatAddressData,
        );
        _cachedBuyResolution = resolution;
        return resolution;
      }
      return const PricingIdentifierResolution(
        pricingIdentifier: '',
        fatAddressData: null,
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to resolve pricing identifier (fat-address hex)',
      );
      return const PricingIdentifierResolution(
        pricingIdentifier: '',
        fatAddressData: null,
      );
    } finally {
      _buyResolutionInFlight = null;
    }
  }
}
