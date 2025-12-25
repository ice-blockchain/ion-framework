// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/user/providers/paginated_master_pubkeys_provider.r.dart';
import 'package:ion/app/features/user_block/providers/block_list_notifier.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_users_provider.r.g.dart';

@riverpod
class SearchUsers extends _$SearchUsers {
  @override
  FutureOr<({List<String>? masterPubkeys, bool hasMore})?> build({
    required String query,
    String? followedByPubkey,
    String? followerOfPubkey,
    bool includeCurrentUser = false,
  }) async {
    final currentUserMasterPubkey = ref.watch(currentPubkeySelectorProvider);
    final paginatedMasterPubkeys = await ref.watch(paginatedMasterPubkeysProvider(_fetcher).future);
    final blockedUsersMasterPubkeys = ref.watch(blockedUsersPubkeysSelectorProvider);

    final filteredMasterPubkeys = paginatedMasterPubkeys.items
        .where(
          (masterPubkey) =>
              (includeCurrentUser || masterPubkey != currentUserMasterPubkey) &&
              !blockedUsersMasterPubkeys.contains(masterPubkey),
        )
        .toList();

    return (
      masterPubkeys: filteredMasterPubkeys,
      hasMore: paginatedMasterPubkeys.hasMore,
    );
  }

  Future<void> loadMore() async {
    return ref.read(paginatedMasterPubkeysProvider(_fetcher).notifier).loadMore();
  }

  Future<void> refresh() async {
    return ref.invalidate(paginatedMasterPubkeysProvider(_fetcher));
  }

  Future<List<IdentityUserInfo>> _fetcher(
    int limit,
    int offset,
    List<String> current,
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
