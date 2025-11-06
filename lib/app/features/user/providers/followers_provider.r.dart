// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/follow_list.f.dart';
import 'package:ion/app/features/user/providers/followers_data_source_provider.r.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'followers_provider.r.g.dart';

@riverpod
class Followers extends _$Followers {
  // Keep the exact dataSources instance used to key the family provider.
  List<EntitiesDataSource>? _dataSourcesKey;

  @override
  FutureOr<({bool hasMore, List<String>? masterPubkeys, bool ready})?> build({
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
        masterPubkeys: result?.masterPubkeys,
        ready: true,
      );
    }
    // Capture the instance to preserve provider identity across loadMore().
    _dataSourcesKey = ref.watch(followersDataSourceProvider(pubkey));
    final entitiesPagedData = ref.watch(
      entitiesPagedDataProvider(_dataSourcesKey),
    );

    // Collecting master pubkeys of the wrapped FollowListEntity events.
    final masterPubkeys = entitiesPagedData?.data.items
        ?.map((item) {
          return switch (item) {
            final EventsMetadataEntity eventMetadata
                when eventMetadata.data.metadata.kind == FollowListEntity.kind =>
              eventMetadata.data.metadataEventReference?.masterPubkey ??
                  eventMetadata.data.eventReferences.firstOrNull?.masterPubkey,
            _ => null
          };
        })
        .nonNulls
        .toList();

    final response = (
      hasMore: entitiesPagedData?.hasMore ?? false,
      masterPubkeys: masterPubkeys,
      // Approximate number of items that is enough to cover the viewport.
      ready: (masterPubkeys?.length ?? 0) >= 12 || entitiesPagedData?.data is! PagedLoading,
    );
    return response;
  }

  Future<void> loadMore() async {
    await future;

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
    if (_dataSourcesKey != null) {
      await ref.read(entitiesPagedDataProvider(_dataSourcesKey).notifier).fetchEntities();
    }
  }
}
