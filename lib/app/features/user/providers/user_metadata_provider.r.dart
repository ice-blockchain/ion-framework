// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user_profile/database/dao/user_delegation_dao.m.dart';
import 'package:ion/app/features/user_profile/database/dao/user_metadata_dao.m.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_metadata_provider.r.g.dart';

@riverpod
class UserMetadata extends _$UserMetadata {
  @override
  Future<UserMetadataEntity?> build(
    String masterPubkey, {
    bool cache = true,
    ActionType? actionType,
    Duration? expirationDuration,
  }) async {
    final userMetadata = await ref.watch(
      ionConnectEntityProvider(
        actionType: actionType,
        cache: cache,
        expirationDuration: expirationDuration,
        eventReference: ReplaceableEventReference(
          masterPubkey: masterPubkey,
          kind: UserMetadataEntity.kind,
        ),
        cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
        // Always include ProfileBadgesSearchExtension to avoid provider rebuilds
        // when badge data changes from null to cached
        search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
      ).future,
    ) as UserMetadataEntity?;

    if (userMetadata != null) {
      return userMetadata;
    }

    unawaited(ref.read(toggleFollowNotifierProvider.notifier).unfollow(masterPubkey));

    return null;
  }
}

@riverpod
UserMetadataEntity? userMetadataSync(Ref ref, String masterPubkey, {bool network = true}) {
  return ref.watch(
    ionConnectSyncEntityProvider(
      network: network,
      eventReference:
          ReplaceableEventReference(masterPubkey: masterPubkey, kind: UserMetadataEntity.kind),
      search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
    ),
  ) as UserMetadataEntity?;
}

@riverpod
Future<UserMetadataEntity?> currentUserMetadata(Ref ref) async {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentPubkey == null) {
    return null;
  }

  try {
    return await ref.watch(userMetadataProvider(currentPubkey).future);
  } on UserRelaysNotFoundException catch (_) {
    return null;
  }
}

@riverpod
Future<bool> isUserDeleted(Ref ref, String masterPubkey) async {
  try {
    final env = ref.watch(envProvider.notifier);
    final expirationDuration = Duration(
      minutes: env.get<int>(EnvVariable.CHAT_PRIVACY_CACHE_MINUTES),
    );

    final userMetadata = await ref
        .watch(userMetadataProvider(masterPubkey, expirationDuration: expirationDuration).future);

    if (userMetadata == null) {
      // If user metadata is null, information can be not available yet on read
      // relays, so we check write relays
      final userMetadataFromWriteRelay = await ref.watch(
        userMetadataProvider(masterPubkey, actionType: ActionType.write, cache: false).future,
      );

      final isDeleted = userMetadataFromWriteRelay == null;

      if (isDeleted) {
        // If user metadata is deleted, we delete it from the database
        unawaited(ref.watch(userMetadataDaoProvider).deleteMetadata([masterPubkey]));
        unawaited(ref.watch(userDelegationDaoProvider).deleteDelegation([masterPubkey]));
      }

      return isDeleted;
    } else {
      return false;
    }
  } on UserRelaysNotFoundException catch (e, st) {
    Logger.error(e, stackTrace: st, message: 'Error checking if user is deleted $masterPubkey');
    return true;
  } catch (e, st) {
    Logger.error(e, stackTrace: st, message: 'Error checking if user is deleted $masterPubkey');
    return false;
  }
}

@riverpod
class UserMetadataFromDb extends _$UserMetadataFromDb {
  @override
  UserMetadataEntity? build(String masterPubkey) {
    keepAliveWhenAuthenticated(ref);
    final subscription = ref.watch(userMetadataDaoProvider).watch(masterPubkey).listen((metadata) {
      state = metadata;
    });

    ref.onDispose(subscription.cancel);

    return null;
  }
}

Future<void> invalidateCurrentUserMetadataProviders(
  WidgetRef ref, {
  ActionType? actionType,
}) async {
  final masterPubkey = ref.read(currentPubkeySelectorProvider);
  if (masterPubkey == null) {
    return;
  }

  final _ = await ref.refresh(
    ionConnectNetworkEntityProvider(
      search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
      actionType: actionType,
      eventReference: ReplaceableEventReference(
        masterPubkey: masterPubkey,
        kind: UserMetadataEntity.kind,
      ),
    ).future,
  );
}
