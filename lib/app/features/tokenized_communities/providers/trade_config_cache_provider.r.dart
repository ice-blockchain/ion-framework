// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/tokenized_communities/providers/trade_config_cache_data.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trade_config_cache_provider.r.g.dart';

@Riverpod(keepAlive: true)
class TradeConfigCache extends _$TradeConfigCache {
  @override
  Map<String, TradeConfigCacheData> build() => {};

  void save(String externalAddress, TradeConfigCacheData data) {
    state = {...state, externalAddress: data};
  }

  TradeConfigCacheData? get(String externalAddress) => state[externalAddress];
}
