// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'paginated_master_pubkeys_provider.r.g.dart';

typedef UserInfoFetcher = Future<List<IdentityUserInfo>> Function(
  int limit,
  int offset,
  List<String> current,
  IONIdentityClient ionIdentityClient,
);

class PaginatedMasterPubkeysData {
  const PaginatedMasterPubkeysData({
    this.items = const [],
    this.hasMore = true,
  });

  final List<String> items;
  final bool hasMore;
}

@Riverpod(keepAlive: true)
class PaginatedMasterPubkeys extends _$PaginatedMasterPubkeys {
  static const int _limit = 20;
  late UserInfoFetcher _fetcher;
  bool _initialized = false;
  int _offset = 0;

  @override
  Future<PaginatedMasterPubkeysData> build(
    UserInfoFetcher fetcher, {
    Duration? expirationDuration,
    DatabaseCacheStrategy? cacheStrategy,
  }) async {
    _fetcher = fetcher;
    if (!_initialized) {
      await _init();
      return state.value ?? const PaginatedMasterPubkeysData();
    }
    return const PaginatedMasterPubkeysData();
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
    final currentData = state.valueOrNull?.items ?? <String>[];
    state = await AsyncValue.guard(() async {
      final ionIdentityClient = await ref.read(ionIdentityClientProvider.future);
      final usersInfo = await _fetcher(_limit, _offset, currentData, ionIdentityClient);
      await ref.read(userRelaysManagerProvider.notifier).cacheRelaysFromIdentity(usersInfo);

      // TODO: cache light user metadata
      final masterPubkeys = usersInfo.map((info) => info.masterPubKey);

      unawaited(
        ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
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
            ),
      );

      final merged = [
        ...currentData,
        ...masterPubkeys,
      ];
      return PaginatedMasterPubkeysData(items: merged, hasMore: usersInfo.length == _limit);
    });
    _offset += _limit;
  }
}

Future<List<IdentityUserInfo>> contentCreatorsPaginatedFetcher(
  int limit,
  _,
  List<String> current,
  IONIdentityClient ionIdentityClient,
) {
  return ionIdentityClient.users.getContentCreators(
    limit: limit,
    excludeMasterPubKeys: current,
  );
}
