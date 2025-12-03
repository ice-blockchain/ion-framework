// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
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

  Future<List<Map<String, dynamic>>> fetchSupportedSwapTokens() async {
    return _configRepository.getConfig<List<Map<String, dynamic>>>(
      _supportedSwapTokensConfigName,
      cacheStrategy: AppConfigCacheStrategy.localStorage,
      parser: (data) => (jsonDecode(data) as List).cast<Map<String, dynamic>>(),
      checkVersion: true,
    );
  }

  /// Fetches the contract address for an asset from the backend
  ///
  /// [externalAddress] - external address for the asset (fatAddress without userExternalID)
  ///
  /// Uses endpoint GET /v1/community-tokens?externalAddresses[]=...
  /// Returns the contract address (addresses.blockchain) if token already exists, otherwise null
  Future<String?> fetchContractAddress(String externalAddress) async {
    try {
      final token = await _analyticsClient.communityTokens.getTokenInfo(externalAddress);
      return token?.addresses.blockchain;
    } catch (e) {
      return null;
    }
  }
}
