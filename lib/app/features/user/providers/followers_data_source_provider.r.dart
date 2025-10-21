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
      entityFilter: (entity) => entity is FollowListEntity,
      // State and pagination are build upon EventsMetadataEntity->FollowListEntity.
      // We don't receive original FollowListEntity because they are too big.
      // But since EventsMetadataEntity is different each time we fetch it (even if it points to the same user),
      // we unwrap it here to make sure pagination and state work as expected.
      entityProcessor: (entity) {
        if (entity is EventsMetadataEntity && entity.data.metadata.kind == FollowListEntity.kind) {
          final metadata = entity.data.metadata;
          return FollowListEntity(
            createdAt: metadata.createdAt,
            id: metadata.id,
            pubkey: metadata.pubkey,
            masterPubkey: metadata.masterPubkey,
            signature: '',
            data: const FollowListData(list: []),
          );
        }
        return entity;
      },
      // We don't need to fetch missing FollowListEntity events. They are used only for pagination + to take authors' master pubkeys.
      missingEventsFilter: (entity) => entity.data.metadata.kind != FollowListEntity.kind,
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
