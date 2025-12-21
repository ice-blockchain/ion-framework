// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/missing_events_handler.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_definition_reference.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_definition_dependency_handler.r.g.dart';

/// Handler responsible for processing ephemeral CommunityTokenDefinition events.
/// Wrapped CommunityTokenDefinition events are the original token definitions for a given
/// community token.
///
/// 1. Caches CommunityTokenDefinitionEntity instances
/// 2. Creates and caches TokenDefinitionReferenceEntity instances for easy
/// token externalAddress -> original/first-buy CommunityTokenDefinition lookups.
class TokenDefinitionDependencyHandler implements EventsMetadataHandler {
  TokenDefinitionDependencyHandler({
    required IonConnectCache ionConnectCache,
  }) : _ionConnectCache = ionConnectCache;

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
            final tokenDefinition =
                CommunityTokenDefinitionEntity.fromEventMessage(event.data.metadata);
            final tokenDefinitionReference =
                TokenDefinitionReferenceEntity.forDefinition(tokenDefinition: tokenDefinition);
            return (
              _ionConnectCache.cache(tokenDefinition),
              _ionConnectCache.cache(tokenDefinitionReference),
            ).wait;
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
  final ionConnectCache = ref.watch(ionConnectCacheProvider.notifier);
  return TokenDefinitionDependencyHandler(
    ionConnectCache: ionConnectCache,
  );
}
