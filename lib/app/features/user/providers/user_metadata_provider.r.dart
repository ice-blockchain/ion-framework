// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_cache.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_database_cache_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/relays/relay_picker_provider.r.dart';
import 'package:ion/app/features/optimistic_ui/features/follow/follow_provider.r.dart';
import 'package:ion/app/features/user/model/badges/badge_award.f.dart';
import 'package:ion/app/features/user/model/badges/badge_definition.f.dart';
import 'package:ion/app/features/user/model/badges/profile_badges.f.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/model/user_metadata_lite.f.dart';
import 'package:ion/app/features/user/model/user_preview_data.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_metadata_provider.r.g.dart';

@riverpod
class UserMetadata extends _$UserMetadata {
  @override
  Future<UserMetadataEntity?> build(
    String masterPubkey, {
    bool cache = true,
    bool network = true,
  }) async {
    final expirationDuration = ref.watch(userMetadataCacheDurationProvider);
    final userMetadata = await ref.watch(
      ionConnectEntityProvider(
        cache: cache,
        network: network,
        expirationDuration: expirationDuration,
        eventReference: ReplaceableEventReference(
          masterPubkey: masterPubkey,
          kind: UserMetadataEntity.kind,
        ),
        cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
        search: _buildSearchForDependencies(),
      ).future,
    ) as UserMetadataEntity?;

    if (userMetadata != null) {
      return userMetadata;
    }

    if (network) {
      // If user metadata is null, information can be not available yet on read
      // relays, so we check write relays
      final userMetadataFromWriteRelay = await ref.watch(
        ionConnectEntityProvider(
          actionType: ActionType.write,
          cache: cache,
          expirationDuration: expirationDuration,
          eventReference: ReplaceableEventReference(
            masterPubkey: masterPubkey,
            kind: UserMetadataEntity.kind,
          ),
          cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
          search: _buildSearchForDependencies(),
        ).future,
      ) as UserMetadataEntity?;

      if (userMetadataFromWriteRelay != null) {
        return userMetadataFromWriteRelay;
      }

      if (userMetadata == null) {
        ref
            .read(ionConnectCacheProvider.notifier)
            .remove(ReplaceableEventReference(masterPubkey: masterPubkey, kind: 0).toString());
        final cacheService = await ref.read(ionConnectPersistentCacheServiceProvider.future);
        // If user metadata is null, we unfollow the user and delete it from the database
        unawaited(ref.read(toggleFollowNotifierProvider.notifier).unfollow(masterPubkey));
        unawaited(
          cacheService.removeAll(
            masterPubkeys: [masterPubkey],
            kinds: [
              UserMetadataEntity.kind,
              UserDelegationEntity.kind,
              BadgeAwardEntity.kind,
              ProfileBadgesEntity.kind,
              BadgeDefinitionEntity.kind,
            ],
          ),
        );
      }
    }

    return null;
  }
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
class UserMetadataInvalidatorNotifier extends _$UserMetadataInvalidatorNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> invalidateCurrentUserMetadataProviders() async {
    final masterPubkey = ref.read(currentPubkeySelectorProvider);
    if (masterPubkey == null) {
      return;
    }

    final _ = await ref.refresh(
      ionConnectEntityProvider(
        cache: false,
        eventReference: ReplaceableEventReference(
          masterPubkey: masterPubkey,
          kind: UserMetadataEntity.kind,
        ),
        cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
        search: _buildSearchForDependencies(),
      ).future,
    );
  }
}

String _buildSearchForDependencies() {
  return SearchExtensions([
    ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind),
    ...SearchExtensions.withTokens(forKind: UserMetadataEntity.kind).extensions,
  ]).toString();
}

@riverpod
Future<UserMetadataLiteEntity?> userMetadataLite(Ref ref, String masterPubkey) async {
  final expirationDuration = ref.watch(userMetadataCacheDurationProvider);
  final userMetadataLite = await ref.watch(
    ionConnectEntityProvider(
      network: false,
      eventReference: ReplaceableEventReference(
        masterPubkey: masterPubkey,
        kind: UserMetadataLiteEntity.kind,
      ),
      expirationDuration: expirationDuration,
    ).future,
  ) as UserMetadataLiteEntity?;
  return userMetadataLite;
}

@riverpod
class UserMetadataLiteManager extends _$UserMetadataLiteManager {
  @override
  FutureOr<void> build() async {}

  Future<List<UserMetadataLiteEntity>> cacheFromIdentity(List<IdentityUserInfo> usersInfo) async {
    final cachedEntities = [
      for (final userInfo in usersInfo)
        UserMetadataLiteEntity(
          masterPubkey: userInfo.masterPubKey,
          data: UserMetadataLite(
            name: userInfo.username,
            displayName: userInfo.displayName,
            picture: userInfo.picture,
          ),
        ),
    ];
    await Future.wait(cachedEntities.map(ref.read(ionConnectCacheProvider.notifier).cache));
    return cachedEntities;
  }
}

@riverpod
Future<UserPreviewEntity?> userPreviewData(
  Ref ref,
  String masterPubkey, {
  bool cache = true,
  bool network = true,
}) async {
  if (cache) {
    final cachedUserMetadata =
        await ref.watch(userMetadataProvider(masterPubkey, network: false).future);
    if (cachedUserMetadata != null) {
      return cachedUserMetadata;
    }
  }

  Future<UserMetadataEntity?>? networkFuture;
  if (network) {
    networkFuture = ref.watch(userMetadataProvider(masterPubkey, cache: cache).future);
  }

  if (cache) {
    final cachedUserMetadataLite = await ref.watch(userMetadataLiteProvider(masterPubkey).future);

    if (cachedUserMetadataLite != null) {
      return cachedUserMetadataLite;
    }
  }

  if (networkFuture != null) {
    return networkFuture;
  }
  return null;
}

@riverpod
Duration userMetadataCacheDuration(Ref ref) {
  return ref.watch(envProvider.notifier).get<Duration>(EnvVariable.USER_METADATA_CACHE_DURATION);
}

String userPreviewNameSelector(AsyncValue<UserPreviewEntity?> state) =>
    state.valueOrNull?.data.name ?? '';

String userPreviewDisplayNameSelector(AsyncValue<UserPreviewEntity?> state) =>
    state.valueOrNull?.data.trimmedDisplayName ?? '';
