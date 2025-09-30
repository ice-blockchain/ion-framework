// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/paginated_users_metadata_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_users_provider.r.g.dart';

@riverpod
class SearchUsers extends _$SearchUsers {
  @override
  FutureOr<({List<UserMetadataEntity>? users, bool hasMore})?> build({
    required String query,
    Duration? expirationDuration,
    String? followedByPubkey,
    String? followerOfPubkey,
  }) async {
    final masterPubkey = ref.watch(currentPubkeySelectorProvider);
    final paginatedUsersMetadataData = await ref.watch(
      paginatedUsersMetadataProvider(_fetcher, expirationDuration: expirationDuration).future,
    );
    final blockedUsersMasterPubkeys = ref
            .watch(currentUserBlockListNotifierProvider)
            .valueOrNull
            ?.map((blockUser) => blockUser.data.blockedMasterPubkeys)
            .expand((pubkey) => pubkey)
            .toList() ??
        [];

    final filteredUsers = paginatedUsersMetadataData.items
        .where(
          (user) =>
              user.masterPubkey != masterPubkey &&
              !blockedUsersMasterPubkeys.contains(user.masterPubkey),
        )
        .toList();

    return (
      users: filteredUsers,
      hasMore: paginatedUsersMetadataData.hasMore,
    );
  }

  Future<void> loadMore() async {
    return ref
        .read(
          paginatedUsersMetadataProvider(_fetcher, expirationDuration: expirationDuration).notifier,
        )
        .loadMore();
  }

  Future<void> refresh() async {
    return ref.invalidate(
      paginatedUsersMetadataProvider(_fetcher, expirationDuration: expirationDuration),
    );
  }

  Future<List<UserRelaysInfo>> _fetcher(
    int limit,
    int offset,
    List<UserMetadataEntity> current,
    IONIdentityClient ionIdentityClient,
  ) {
    if (query.trim().isEmpty) {
      return Future.value([]);
    }
    return ionIdentityClient.users.searchForUsersByKeyword(
      limit: limit,
      offset: offset,
      keyword: query.trim(),
      searchType: SearchUsersSocialProfileType.contains,
      followedBy: followedByPubkey,
      followerOf: followerOfPubkey,
    );
  }
}

@riverpod
class SearchUsersQuery extends _$SearchUsersQuery {
  @override
  String build() {
    return '';
  }

  set text(String value) {
    state = value;
  }
}
