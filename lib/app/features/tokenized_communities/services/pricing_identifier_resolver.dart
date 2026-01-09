// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/enums/community_token_trade_mode.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/services/logger/logger.dart';

typedef TokenExistsResolver = Future<bool> Function();
typedef FatAddressHexResolver = Future<String> Function();

class CommunityTokenPricingIdentifierResolver {
  CommunityTokenPricingIdentifierResolver({
    required this.externalAddress,
    required this.externalAddressType,
    required this.tokenExistsResolver,
    required this.fatAddressHexResolver,
  });

  final String externalAddress;
  final ExternalAddressType externalAddressType;
  final TokenExistsResolver tokenExistsResolver;
  final FatAddressHexResolver fatAddressHexResolver;

  String? _cachedBuyPricingIdentifierHex;
  Future<String>? _buyPricingIdentifierHexInFlight;

  Future<String> resolve(CommunityTokenTradeMode mode) async {
    if (mode == CommunityTokenTradeMode.sell) {
      return externalAddress;
    }

    final tokenExists = await tokenExistsResolver();
    if (tokenExists) {
      return externalAddress;
    }

    final cached = _cachedBuyPricingIdentifierHex;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    return _loadAndCacheBuyPricingIdentifierHex();
  }

  Future<String> _loadAndCacheBuyPricingIdentifierHex() async {
    final inFlight = _buyPricingIdentifierHexInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    _buyPricingIdentifierHexInFlight = _computeAndCacheBuyPricingIdentifierHex();
    return _buyPricingIdentifierHexInFlight!;
  }

  Future<String> _computeAndCacheBuyPricingIdentifierHex() async {
    try {
      final hex = await fatAddressHexResolver();
      if (hex.isNotEmpty) {
        _cachedBuyPricingIdentifierHex = hex;
      }
      return hex;
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Failed to resolve pricing identifier (fat-address hex)',
      );
      return '';
    } finally {
      _buyPricingIdentifierHexInFlight = null;
    }
  }
}
