// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/entities_list/list_cached_entities.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/soft_deletable_entity.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/model/entities/blocked_user_entity.f.dart';
import 'package:ion/app/features/user_block/optimistic_ui/block_user_provider.r.dart';
import 'package:ion/app/features/user_block/optimistic_ui/model/blocked_user.f.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';

class ListEntityHelper {
  static bool isEntityOrRepostedEntityDeleted(
    BuildContext context,
    WidgetRef ref,
    IonConnectEntity entity,
  ) {
    if (entity is SoftDeletableEntity && entity.isDeleted) {
      return true;
    }
    if (entity is GenericRepostEntity) {
      final repostedEntity = ref.watch(
            ionConnectEntityWithCountersProvider(eventReference: entity.data.eventReference)
                .select((value) {
              final entity = value.valueOrNull;
              if (entity != null) {
                ListCachedObjects.updateObject<IonConnectEntity, EventReference>(context, entity);
              }
              return entity;
            }),
          ) ??
          ListCachedObjects.maybeObjectOf<IonConnectEntity, EventReference>(
            context,
            entity.data.eventReference,
          );
      return repostedEntity == null ||
          (repostedEntity is SoftDeletableEntity && repostedEntity.isDeleted);
    }
    return false;
  }

  static bool isUserMuted(WidgetRef ref, String masterPubkey, {required bool showMuted}) {
    final isMuted = !showMuted && ref.watch(isUserMutedProvider(masterPubkey));

    return isMuted;
  }

  static bool isUserBlockedOrBlocking(
      BuildContext context, WidgetRef ref, IonConnectEntity entity) {
    final blockedUser = ref.watch(
          blockedUserWatchProvider(entity.masterPubkey).select((value) {
            final blockedObject = value.valueOrNull;
            if (blockedObject != null) {
              ListCachedObjects.updateObject<BlockedUser, String>(context, blockedObject);
            }
            return blockedObject;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<BlockedUser, String>(context, entity.masterPubkey);

    final isUserBlocked = blockedUser != null && blockedUser.isBlocked;

    final blockedByList = ref.watch(
          currentUserBlockedByListNotifierProvider.select((blockedUsersEntities) {
            final blockedUsers = blockedUsersEntities.valueOrNull;
            if (blockedUsers != null) {
              ListCachedObjects.updateObjects<IonConnectEntity, EventReference>(
                context,
                blockedUsers,
              );
            }
            return blockedUsers;
          }),
        ) ??
        ListCachedObjects.maybeObjectsOf<BlockedUserEntity>(context);

    if (isUserBlocked ||
        blockedByList.any((blockedEntity) => blockedEntity.masterPubkey == entity.masterPubkey)) {
      return true;
    }

    return false;
    // if (entity is ModifiablePostEntity && entity.data.quotedEvent != null) {
    //   final quotedEntity = ref.watch(
    //     ionConnectInMemoryEntityProvider(
    //       eventReference: entity.data.quotedEvent!.eventReference,
    //     ),
    //   );
    //   if (quotedEntity != null) {
    //     return ref.watch(isEntityBlockedOrBlockedByProvider(quotedEntity));
    //   }
    // } else if (entity is GenericRepostEntity) {
    //   final childEntity = ref.watch(
    //     ionConnectSyncEntityProvider(eventReference: entity.data.eventReference),
    //   );
    //   if (childEntity != null) {
    //     return ref.watch(isEntityBlockedOrBlockedByProvider(childEntity));
    //   }
    // }
//
    // return false;
  }

  static bool hasMetadata(BuildContext context, WidgetRef ref, IonConnectEntity entity) {
    final userMetadata = ref.watch(
          userMetadataProvider(entity.masterPubkey).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<IonConnectEntity, EventReference>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<IonConnectEntity, EventReference>(
          context,
          entity.toEventReference(),
        );

    return userMetadata != null;
  }
}
