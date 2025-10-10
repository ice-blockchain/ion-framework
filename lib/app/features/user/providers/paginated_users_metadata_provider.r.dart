// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:collection';

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paginated_users_metadata_provider.r.g.dart';

typedef UserRelaysInfoFetcher = Future<List<UserRelaysInfo>> Function(
  int limit,
  int offset,
  List<UserMetadataEntity> current,
  IONIdentityClient ionIdentityClient,
);

class PaginatedUsersMetadataData {
  const PaginatedUsersMetadataData({
    this.items = const [],
    this.hasMore = true,
  });

  final List<UserMetadataEntity> items;
  final bool hasMore;
}

@Riverpod(keepAlive: true)
class PaginatedUsersMetadata extends _$PaginatedUsersMetadata {
  static const int _limit = 20;
  late UserRelaysInfoFetcher _fetcher;
  bool _initialized = false;
  int _offset = 0;

  @override
  Future<PaginatedUsersMetadataData> build(
    UserRelaysInfoFetcher fetcher, {
    Duration? expirationDuration,
    DatabaseCacheStrategy? cacheStrategy,
  }) async {
    _fetcher = fetcher;
    if (!_initialized) {
      await _init();
      return state.value ?? const PaginatedUsersMetadataData();
    }
    return const PaginatedUsersMetadataData();
  }

  Future<void> loadMore() async {
    final hasMore = state.valueOrNull?.hasMore ?? true;
    if (state.isLoading || !hasMore) {
      return;
    }
    return _fetch();
  }

  Future<void> _init() async {
    _initialized = true;
    return _fetch();
  }

  Future<void> _fetch() async {
    state = const AsyncValue.loading();
    final currentData = state.valueOrNull?.items ?? <UserMetadataEntity>[];
    state = await AsyncValue.guard(() async {
      final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);
      final userRelaysInfo = await _fetcher(_limit, _offset, currentData, ionIdentityClient);

      // Remove duplicates while preserving order using LinkedHashSet
      final masterPubkeys = LinkedHashSet<String>.from(
        userRelaysInfo.map((e) => e.masterPubKey),
      ).toList();

      final usersMetadataWithDependencies =
          await ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
                cacheStrategy: cacheStrategy,
                expirationDuration: expirationDuration,
                eventReferences: masterPubkeys
                    .map(
                      (masterPubkey) => ReplaceableEventReference(
                        masterPubkey: masterPubkey,
                        kind: UserMetadataEntity.kind,
                      ),
                    )
                    .toList(),
                search: ProfileBadgesSearchExtension(forKind: UserMetadataEntity.kind).toString(),
              );

      // Preserve the original order from userRelaysInfo
      final entitiesById = <String, UserMetadataEntity>{};
      for (final entity in usersMetadataWithDependencies.whereType<UserMetadataEntity>()) {
        entitiesById[entity.masterPubkey] = entity;
      }

      // Create ordered list based on original masterPubkeys order
      final orderedEntities = masterPubkeys
          .map((pubkey) => entitiesById[pubkey])
          .where((entity) => entity != null)
          .cast<UserMetadataEntity>()
          .toList();

      final merged = [
        ...currentData,
        ...orderedEntities,
      ];
      return PaginatedUsersMetadataData(items: merged, hasMore: userRelaysInfo.length == _limit);
    });
    _offset += _limit;
  }
}

Future<List<UserRelaysInfo>> contentCreatorsPaginatedFetcher(
  int limit,
  _,
  List<UserMetadataEntity> current,
  IONIdentityClient ionIdentityClient,
) {
  return ionIdentityClient.users.getContentCreators(
    limit: limit,
    excludeMasterPubKeys: current.map((u) => u.masterPubkey).toList(),
  );
}
