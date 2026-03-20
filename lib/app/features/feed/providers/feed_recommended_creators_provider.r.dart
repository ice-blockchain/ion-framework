// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:ion/app/features/user/providers/muted_users_notifier.r.dart';
import 'package:ion/app/features/user/providers/paginated_master_pubkeys_provider.r.dart';
import 'package:ion/app/features/user/providers/relays/user_relays_manager.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:ion_connect_cache/ion_connect_cache.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_recommended_creators_provider.r.g.dart';

@riverpod
class FeedRecommendedCreators extends _$FeedRecommendedCreators {
  static const int _limit = 20;
  bool _initialized = false;
  int _fetchRequestId = 0;

  @override
  Future<PaginatedMasterPubkeysData> build() async {
    if (!_initialized) {
      _initialized = true;
      await _fetch();
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

  Future<void> refresh() async {
    _initialized = true;
    return _fetch(clearCurrent: true);
  }

  List<String> _buildExcludePubkeys(List<String> alreadyFetched) {
    final blockedPubkeys = ref.read(blockedUsersPubkeysSelectorProvider).toList();

    final followList = ref.read(currentUserFollowListProvider).valueOrNull;
    final followedPubkeys = followList?.data.list.map((e) => e.pubkey).toList();

    final mutedPubkeys = ref.read(mutedUsersProvider).valueOrNull;

    final currentPubkey = ref.read(currentPubkeySelectorProvider);

    return [
      ...alreadyFetched,
      ...blockedPubkeys,
      ...?followedPubkeys,
      ...?mutedPubkeys,
      if (currentPubkey != null) currentPubkey,
    ];
  }

  Future<void> _fetch({bool clearCurrent = false}) async {
    final requestId = ++_fetchRequestId;
    final currentData = clearCurrent ? <String>[] : (state.valueOrNull?.items ?? const <String>[]);

    state = const AsyncLoading<PaginatedMasterPubkeysData>().copyWithPrevious(state);

    final result = await AsyncValue.guard(() async {
      final ionIdentityClient = await ref.read(ionIdentityClientProvider.future);
      final excludePubkeys = _buildExcludePubkeys(currentData);

      final usersInfo = await ionIdentityClient.users.getContentCreators(
        limit: _limit,
        excludeMasterPubKeys: excludePubkeys,
      );

      await Future.wait([
        ref.read(userRelaysManagerProvider.notifier).cacheFromIdentity(usersInfo),
        ref.read(userMetadataLiteManagerProvider.notifier).cacheFromIdentity(usersInfo),
      ]);

      final masterPubkeys = usersInfo.map((info) => info.masterPubKey);

      final expirationDuration = ref.read(userMetadataCacheDurationProvider);

      unawaited(
        ref.read(ionConnectEntitiesManagerProvider.notifier).fetch(
              cacheStrategy: DatabaseCacheStrategy.returnIfNotExpired,
              expirationDuration: expirationDuration,
              eventReferences: masterPubkeys
                  .map(
                    (masterPubkey) => ReplaceableEventReference(
                      masterPubkey: masterPubkey,
                      kind: UserMetadataEntity.kind,
                    ),
                  )
                  .toList(),
              search: SearchExtensions.forUserMetadata().toString(),
            ),
      );

      final merged = [...currentData, ...masterPubkeys];
      return PaginatedMasterPubkeysData(
        items: merged,
        hasMore: usersInfo.length == _limit,
      );
    });

    if (requestId != _fetchRequestId) {
      return;
    }

    state = result;
  }
}
