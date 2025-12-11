// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_first_buy_provider.r.g.dart';

@riverpod
Future<CommunityTokenActionEntity?> tokenFirstBuy(
  Ref ref,
  CommunityTokenDefinitionEntity tokenDefinitionEntity,
) async {
  final firstBuyCacheKey = CommunityTokenActionEntity.cacheKeyBuilder(
    definitionReference: tokenDefinitionEntity.toEventReference().toString(),
  );

  final existingEntity = ref.watch(
    ionConnectCacheProvider.select(
      cacheSelector<CommunityTokenActionEntity>(firstBuyCacheKey),
    ),
  );

  return existingEntity;
}
