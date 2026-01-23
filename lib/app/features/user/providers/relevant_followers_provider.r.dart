// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/providers/relevant_followers_data_source_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relevant_followers_provider.r.g.dart';

typedef RelevantFollowersResult = ({bool hasMore, List<String>? masterPubkeys, bool ready});

@riverpod
class RelevantFollowers extends _$RelevantFollowers {
  // Keep the exact dataSources instance used to key the family provider.
  List<EntitiesDataSource>? _dataSourcesKey;

  @override
  RelevantFollowersResult? build({
    required String pubkey,
    int limit = 20,
  }) {
    _dataSourcesKey = ref.watch(relevantFollowersDataSourceProvider(pubkey, limit: limit));
    final entitiesPagedData = ref.watch(entitiesPagedDataProvider(_dataSourcesKey));

    final masterPubkeys = entitiesPagedData?.data.items
        ?.map<String>((item) {
          return switch (item) {
            final EventsMetadataEntity eventsMetadata =>
              eventsMetadata.data.metadataEventReference?.masterPubkey ??
                  eventsMetadata.data.metadata.pubkey,
            _ => item.masterPubkey,
          };
        })
        .where((key) => key.isNotEmpty)
        .toList();
    final uniqueMasterPubkeys = masterPubkeys?.toSet().toList() ?? <String>[];

    final result = (
      hasMore: entitiesPagedData?.hasMore ?? false,
      masterPubkeys: uniqueMasterPubkeys,
      // Approximate number of items that is enough to cover the viewport.
      ready: uniqueMasterPubkeys.length >= 12 || entitiesPagedData?.data is! PagedLoading,
    );

    return result;
  }

  Future<void> loadMore() async {
    if (_dataSourcesKey != null) {
      await ref.read(entitiesPagedDataProvider(_dataSourcesKey).notifier).fetchEntities();
    }
  }
}
