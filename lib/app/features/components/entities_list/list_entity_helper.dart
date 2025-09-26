// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/components/entities_list/list_cached_entities.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/ion_connect_entity_with_counters_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/soft_deletable_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/badges_notifier.r.dart';
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
                ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
              }
              return entity;
            }),
          ) ??
          ListCachedObjects.maybeObjectOf<IonConnectEntity>(
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
    BuildContext context,
    WidgetRef ref,
    IonConnectEntity entity,
  ) {
    final blockedUser = ref.watch(
          blockedUserWatchProvider(entity.masterPubkey).select((value) {
            final blockedObject = value.valueOrNull;
            if (blockedObject != null) {
              ListCachedObjects.updateObject<BlockedUser>(context, blockedObject);
            }
            return blockedObject;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<BlockedUser>(context, entity.masterPubkey);

    final isUserBlocked = blockedUser != null && blockedUser.isBlocked;

    final blockedByList = ref.watch(
          currentUserBlockedByListNotifierProvider.select((blockedUsersEntities) {
            final blockedUsers = blockedUsersEntities.valueOrNull;
            if (blockedUsers != null) {
              ListCachedObjects.updateObjects<BlockedUserEntity>(
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

    if (entity is ModifiablePostEntity && entity.data.quotedEvent != null) {
      final quotedEntity = ref.watch(
            ionConnectEntityProvider(
              eventReference: entity.data.quotedEvent!.eventReference,
            ).select((value) {
              final entity = value.valueOrNull;
              if (entity != null) {
                ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
              }
              return entity;
            }),
          ) ??
          ListCachedObjects.maybeObjectOf<IonConnectEntity>(
            context,
            entity.data.quotedEvent!.eventReference,
          );

      if (quotedEntity != null) {
        return isUserBlockedOrBlocking(context, ref, quotedEntity);
      }
    } else if (entity is GenericRepostEntity) {
      final childEntity = ref.watch(
            ionConnectEntityProvider(eventReference: entity.data.eventReference).select((value) {
              final entity = value.valueOrNull;
              if (entity != null) {
                ListCachedObjects.updateObject<IonConnectEntity>(context, entity);
              }
              return entity;
            }),
          ) ??
          ListCachedObjects.maybeObjectOf<IonConnectEntity>(
            context,
            entity.data.eventReference,
          );

      if (childEntity != null) {
        return isUserBlockedOrBlocking(context, ref, childEntity);
      }
    }

    return false;
  }

  static bool isDeviceIdentityWithoutProofs(
    WidgetRef ref,
    IonConnectEntity entity,
  ) {
    final isDeviceIdentityProven = ref.watch(
      isDeviceIdentityProvenProvider(
        masterPubkey: entity.masterPubkey,
        deviceIdentityPubkey: entity.pubkey,
      ),
    );
    return isDeviceIdentityProven == false;
  }

  static bool userHasNoProvenIdentities(
    WidgetRef ref,
    String masterPubkey,
  ) {
    final hasUserProvenIdentities =
        ref.watch(hasUserProvenIdentitiesProvider(masterPubkey)).valueOrNull ?? true;
    return hasUserProvenIdentities == false;
  }

  static bool hasMetadata(BuildContext context, WidgetRef ref, IonConnectEntity entity) {
    final userMetadata = ref.watch(
          // We don't request the events individually - we just wait for them to appear in cache
          // from either search ext OR from fetching missing events if relay returns 21750
          // for the metadata and we fetch those in batches.
          userMetadataProvider(entity.masterPubkey, network: false).select((value) {
            final entity = value.valueOrNull;
            if (entity != null) {
              ListCachedObjects.updateObject<UserMetadataEntity>(context, entity);
            }
            return entity;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<UserMetadataEntity>(
          context,
          entity.masterPubkey,
        );

    return userMetadata != null;
  }
}
