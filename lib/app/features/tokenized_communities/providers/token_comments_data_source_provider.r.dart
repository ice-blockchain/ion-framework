// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event.f.dart';
import 'package:ion/app/features/ion_connect/model/related_event_marker.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_comments_data_source_provider.r.g.dart';

@riverpod
List<EntitiesDataSource>? tokenCommentsDataSource(
  Ref ref, {
  required EventReference tokenDefinitionEventReference,
}) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  final entity = ref
      .watch(ionConnectEntityProvider(eventReference: tokenDefinitionEventReference))
      .valueOrNull;

  if (currentPubkey == null || entity == null) {
    return null;
  }

  final relatedTags = RelatedEvent.fromEventReference(
          tokenDefinitionEventReference,
          marker: RelatedEventMarker.reply,
        )
      .toFilterEntry();

  final dataSources = [
    EntitiesDataSource(
      actionSource: ActionSourceUser(tokenDefinitionEventReference.masterPubkey),
      entityFilter: (entity) =>
          (entity is ModifiablePostEntity &&
              entity.data.parentEvent?.eventReference == tokenDefinitionEventReference) ||
          (entity is PostEntity &&
              entity.data.parentEvent?.eventReference == tokenDefinitionEventReference),
      requestFilter: RequestFilter(
        kinds: const [ModifiablePostEntity.kind, PostEntity.kind],
        tags: Map.fromEntries([relatedTags]),
        search: SearchExtensions(
          [
            ...SearchExtensions.withCounters(currentPubkey: currentPubkey).extensions,
            ...SearchExtensions.withAuthors().extensions,
            ...SearchExtensions.withCounters(
              currentPubkey: currentPubkey,
              forKind: PostEntity.kind,
            ).extensions,
            ...SearchExtensions.withAuthors(forKind: PostEntity.kind).extensions,
            ExpirationSearchExtension(expiration: false),
          ],
        ).toString(),
        limit: 10,
      ),
    ),
  ];

  return dataSources;
}
