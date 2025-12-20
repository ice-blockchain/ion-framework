// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/missing_events_handler.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_action_first_buy_reference.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_action_first_buy_dependency_handler.r.g.dart';

/// Handler responsible for processing ephemeral CommunityTokenActionEntity events.
/// Wrapped CommunityTokenAction events are the "first-buy" actions for a given
/// community token + master pubkey.
///
/// 1. Caches CommunityTokenActionEntity
/// 2. Creates and caches TokenActionFirstBuyReferenceEntity for easy lookups
///   of "first-buy" actions made by a specific user.
/// 3. Creates and caches TokenActionFirstBuyReferenceEntity for easy lookups
///   of "first-buy" actions made by any user.
class TokenActionFirstBuyDependencyHandler implements EventsMetadataHandler {
  TokenActionFirstBuyDependencyHandler({
    required IonConnectCache ionConnectCache,
  }) : _ionConnectCache = ionConnectCache;

  final IonConnectCache _ionConnectCache;

  @override
  Future<Iterable<EventsMetadataEntity>> handle(Iterable<EventsMetadataEntity> events) async {
    final (match: tokenActionEvents, rest: restEvents) = events.toList().partition(
          (event) => event.data.metadata.kind == CommunityTokenActionEntity.kind,
        );

    try {
      await Future.wait(
        tokenActionEvents.map(
          (event) async {
            final tokenAction = CommunityTokenActionEntity.fromEventMessage(event.data.metadata);
            final userTokenActionFirstBuyReference =
                TokenActionFirstBuyReferenceEntity.fromCommunityTokenAction(tokenAction);
            final tokenActionFirstBuyReference = userTokenActionFirstBuyReference.copyWith(
              masterPubkey: TokenActionFirstBuyReference.anyUserMasterPubkey,
            );
            return (
              _ionConnectCache.cache(tokenAction),
              _ionConnectCache.cache(userTokenActionFirstBuyReference),
              _ionConnectCache.cache(tokenActionFirstBuyReference),
            ).wait;
          },
        ),
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Handler TokenActionFirstBuyDependencyHandler failed to process events',
      );
    }
    return restEvents;
  }
}

@riverpod
Future<TokenActionFirstBuyDependencyHandler> tokenActionFirstBuyDependencyHandler(
  Ref ref,
) async {
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  return TokenActionFirstBuyDependencyHandler(
    ionConnectCache: ionConnectCache,
  );
}
