// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';

class TokenizedCommunitiesApi {
  TokenizedCommunitiesApi({required ConfigRepository configRepository})
      : _configRepository = configRepository;

  final ConfigRepository _configRepository;

  static const String _bondingCurveAbiConfigName =
      'tokenized_communities_bonding_curve_smart_contract_abi';
  static const String _bondingCurveAddressConfigName =
      'tokenized_communities_bonding_curve_smart_contract_address';

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
}
