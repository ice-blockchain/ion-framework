// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/missing_events_handler.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_definition_dependency_handler.r.g.dart';

/// Handler responsible for processing ephemeral CommunityTokenDefinition events.
/// Wrapped CommunityTokenDefinition events are the original token definitions for a given
/// community token.
///
/// 1. Caches CommunityTokenDefinitionEntity instances
/// 2. Creates and caches TokenDefinitionReferenceEntity instances for easy
/// token externalAddress -> original CommunityTokenDefinition  lookups.
class TokenDefinitionDependencyHandler implements EventsMetadataHandler {
  TokenDefinitionDependencyHandler({
    required ExternalAddressTokenDefinitionCache externalAddressTokenDefinitionCache,
    required IonConnectCache ionConnectCache,
  })  : _externalAddressTokenDefinitionCache = externalAddressTokenDefinitionCache,
        _ionConnectCache = ionConnectCache;

  final ExternalAddressTokenDefinitionCache _externalAddressTokenDefinitionCache;

  final IonConnectCache _ionConnectCache;

  @override
  Future<Iterable<EventsMetadataEntity>> handle(Iterable<EventsMetadataEntity> events) async {
    final (match: tokenDefinitionEvents, rest: restEvents) = events.toList().partition(
          (event) => event.data.metadata.kind == CommunityTokenDefinitionEntity.kind,
        );

    try {
      await Future.wait(
        tokenDefinitionEvents.map(
          (event) async {
            final entity = CommunityTokenDefinitionEntity.fromEventMessage(event.data.metadata);
            await _externalAddressTokenDefinitionCache.saveReference(
              externalAddress: entity.data.externalAddress,
              eventReference: entity.toEventReference(),
            );
            await _ionConnectCache.cache(entity);
          },
        ),
      );
    } catch (error, stackTrace) {
      Logger.error(
        error,
        stackTrace: stackTrace,
        message: 'Handler TokenDefinitionDependencyHandler failed to process events',
      );
    }

    return restEvents;
  }
}

@riverpod
Future<TokenDefinitionDependencyHandler> tokenDefinitionDependencyHandler(
  Ref ref,
) async {
  final externalAddressTokenDefinitionCache =
      await ref.watch(externalAddressTokenDefinitionCacheProvider.future);
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  return TokenDefinitionDependencyHandler(
    externalAddressTokenDefinitionCache: externalAddressTokenDefinitionCache,
    ionConnectCache: ionConnectCache,
  );
}
