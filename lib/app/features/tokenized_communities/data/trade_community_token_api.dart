// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/tokenized_communities/data/models/supported_swap_token_config_dto.f.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';

class TradeCommunityTokenApi {
  TradeCommunityTokenApi({
    required ConfigRepository configRepository,
    required IonTokenAnalyticsClient analyticsClient,
  })  : _configRepository = configRepository,
        _analyticsClient = analyticsClient;

  final ConfigRepository _configRepository;
  final IonTokenAnalyticsClient _analyticsClient;

  static const String _bondingCurveAbiConfigName =
      'tokenized_communities_bonding_curve_smart_contract_abi';
  static const String _bondingCurveAddressConfigName =
      'tokenized_communities_bonding_curve_smart_contract_address';
  static const String _supportedSwapTokensConfigName = 'supported_swap_tokens';

  Future<String> fetchBondingCurveAbi() async {
    final abi = await _configRepository.getConfig<String>(
      _bondingCurveAbiConfigName,
      cacheStrategy: AppConfigCacheStrategy.localStorage,
      parser: (data) => data.trim(),
      checkVersion: true,
    );
    if (abi.isEmpty) {
      throw StateError(
        'Config value for $_bondingCurveAbiConfigName is missing or invalid.',
      );
    }
    return abi;
  }

  Future<String> fetchBondingCurveAddress() async {
    final address = await _configRepository.getConfig<String>(
      _bondingCurveAddressConfigName,
      cacheStrategy: AppConfigCacheStrategy.localStorage,
      parser: (data) => data.trim(),
      checkVersion: true,
    );
    if (address.isEmpty) {
      throw StateError(
        'Config value for $_bondingCurveAddressConfigName is missing or invalid.',
      );
    }
    return address;
  }

  Future<List<SupportedSwapTokenConfigDto>> fetchSupportedSwapTokens() async {
    return _configRepository.getConfig<List<SupportedSwapTokenConfigDto>>(
      _supportedSwapTokensConfigName,
      cacheStrategy: AppConfigCacheStrategy.localStorage,
      parser: (data) => (jsonDecode(data) as List)
          .map((e) => SupportedSwapTokenConfigDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkVersion: true,
    );
  }

  Future<CommunityToken?> fetchTokenInfo(String externalAddress) async {
    try {
      return await _analyticsClient.communityTokens.getTokenInfo(externalAddress);
    } catch (e) {
      return null;
    }
  }

  /// Fetches pricing information for buy or sell operations
  ///
  /// [externalAddress] - external address for the asset
  /// [type] - 'buy' or 'sell'
  /// [amount] - amount in smallest units (wei)
  ///
  /// Uses endpoint GET /v1/community-tokens/{externalAddress}/pricing?type={type}&amount={amount}
  /// Returns PricingResponse if found, otherwise null
  Future<PricingResponse?> fetchPricing(String externalAddress, String type, String amount) async {
    try {
      return await _analyticsClient.communityTokens.getPricing(externalAddress, type, amount);
    } catch (e) {
      return null;
    }
  }
}
