// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'followers_data_source_provider.r.g.dart';

@riverpod
List<EntitiesDataSource>? followersDataSource(
  Ref ref,
  String pubkey,
) {
  return [
    EntitiesDataSource(
      actionSource: ActionSourceUser(pubkey),
      // Taking both UserMetadataEntity and EventsMetadataEntity->UserMetadataEntity to show the items right away
      // and then take the data from identity and then relays
      entityFilter: (entity) =>
          entity is UserMetadataEntity ||
          (entity is EventsMetadataEntity && entity.data.metadata.kind == UserMetadataEntity.kind),
      // Pagination works upon the EventsMetadataEntity->FollowListEntity events, because we don't receive the original FollowListEntity events
      pagedFilter: (entity) =>
          entity is EventsMetadataEntity && entity.data.metadata.kind == FollowListEntity.kind,
      // We don't need to fetch missing FollowListEntity events. They are used only for pagination.
      missingEventsFilter: (entity) => entity.data.metadata.kind != FollowListEntity.kind,
      paginationPivotBuilder: (entity) {
        return switch (entity) {
          // Taking the createdAt for the pagination from the FollowListEntity event wrapped with EventsMetadataEntity
          final EventsMetadataEntity eventsMetadata
              when eventsMetadata.data.metadata.kind == FollowListEntity.kind =>
            eventsMetadata.data.metadata.createdAt.toDateTime,
          _ => entity.createdAt.toDateTime,
        };
      },
      requestFilter: RequestFilter(
        kinds: const [FollowListEntity.kind],
        tags: {
          '#p': [pubkey],
        },
        search: SearchExtensions(
          [
            GenericIncludeSearchExtension(
              forKind: FollowListEntity.kind,
              includeKind: UserMetadataEntity.kind,
            ),
            if (ref.watch(cachedProfileBadgesDataProvider(pubkey)) == null)
              ProfileBadgesSearchExtension(forKind: FollowListEntity.kind),
          ],
        ).toString(),
        limit: 20,
      ),
    ),
  ];
}
