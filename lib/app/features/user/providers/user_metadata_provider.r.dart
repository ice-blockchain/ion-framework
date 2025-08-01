// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user_profile/database/dao/user_metadata_dao.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_metadata_provider.r.g.dart';

@riverpod
class UserMetadata extends _$UserMetadata {
  @override
  Future<UserMetadataEntity?> build(
    String pubkey, {
    bool cache = true,
  }) async {
    return await ref.watch(
      ionConnectEntityProvider(
        eventReference: ReplaceableEventReference(
          masterPubkey: pubkey,
          kind: UserMetadataEntity.kind,
        ),
        // Always include ProfileBadgesSearchExtension to avoid provider rebuilds
        // when badge data changes from null to cached
        search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
        cache: cache,
      ).future,
    ) as UserMetadataEntity?;
  }

  Future<void> preloadCache(Ref ref, List<String> masterPubkeys) async {
    await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
          eventReferences: masterPubkeys
              .map(
                (pubkey) =>
                    ReplaceableEventReference(masterPubkey: pubkey, kind: UserMetadataEntity.kind),
              )
              .toList(),
          search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
        );
  }
}

@riverpod
UserMetadataEntity? cachedUserMetadata(
  Ref ref,
  String pubkey,
) {
  return ref.watch(
    ionConnectSyncEntityProvider(
      eventReference:
          ReplaceableEventReference(masterPubkey: pubkey, kind: UserMetadataEntity.kind),
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
Future<bool> isUserDeleted(Ref ref, String pubkey) async {
  final userMetadata = await ref.watch(userMetadataProvider(pubkey).future);
  return userMetadata == null;
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

// One-time read provider for push notifications and other one-off operations
@riverpod
Future<UserMetadataEntity?> userMetadataFromDbOnce(
  Ref ref,
  String masterPubkey,
) async {
  final userMetadataDao = ref.read(userMetadataDaoProvider);
  return userMetadataDao.get(masterPubkey);
}
