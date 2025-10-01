// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/followers_data_source_provider.r.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'followers_provider.r.g.dart';

@riverpod
class Followers extends _$Followers {
  @override
  FutureOr<({bool hasMore, List<UserMetadataEntity>? users, bool ready})?> build({
    required String pubkey,
    required String query,
  }) async {
    if (query.isNotEmpty) {
      final result = ref
          .watch(
            searchUsersProvider(
              query: query,
              followerOfPubkey: pubkey,
              includeCurrentUser: true,
            ),
          )
          .valueOrNull;
      return (
        hasMore: result?.hasMore ?? false,
        users: result?.users,
        ready: true,
      );
    }
    final dataSource = ref.watch(followersDataSourceProvider(pubkey));
    final entitiesPagedData = ref.watch(
      entitiesPagedDataProvider(
        dataSource,
        awaitMissingEvents: true,
      ),
    );
    final users = entitiesPagedData?.data.items?.whereType<UserMetadataEntity>().toList();
    final response = (
      hasMore: entitiesPagedData?.hasMore ?? false,
      users: users,
      ready: (users?.length ?? 0) >= 12 || entitiesPagedData?.data is! PagedLoading,
    );
    return response;
  }

  Future<void> loadMore() async {
    if (query.isNotEmpty) {
      return ref
          .read(
            searchUsersProvider(
              query: query,
              followerOfPubkey: pubkey,
              includeCurrentUser: true,
            ).notifier,
          )
          .loadMore();
    }
    final dataSource = ref.read(followersDataSourceProvider(pubkey));
    await ref.read(entitiesPagedDataProvider(dataSource).notifier).fetchEntities();
  }
}
