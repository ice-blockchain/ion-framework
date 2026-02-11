// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/config/data/models/app_config_cache_strategy.dart';
import 'package:ion/app/features/config/providers/config_repository.r.dart';
import 'package:ion/app/features/tokenized_communities/data/models/tokenized_communities_trade_config.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tokenized_communities_trade_config_provider.r.g.dart';

@Riverpod(keepAlive: true)
Future<TokenizedCommunitiesTradeConfig> tokenizedCommunitiesTradeConfig(Ref ref) async {
  final repository = await ref.watch(configRepositoryProvider.future);
  final result = await repository.getConfig<TokenizedCommunitiesTradeConfig>(
    'multiswap',
    cacheStrategy: AppConfigCacheStrategy.file,
    parser: (data) =>
        TokenizedCommunitiesTradeConfig.fromJson(jsonDecode(data) as Map<String, dynamic>),
    checkVersion: true,
  );
  return result;
}
