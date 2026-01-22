// SPDX-License-Identifier: ice License 1.0

import 'dart:collection';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/model/paged.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/providers/relevant_followers_data_source_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'relevant_followers_provider.r.g.dart';

typedef RelevantFollowersResult = ({bool hasMore, List<String>? masterPubkeys, bool ready});

@riverpod
RelevantFollowersResult? relevantFollowers(
  Ref ref, {
  required String pubkey,
  int limit = 20,
}) {
  final dataSources = ref.watch(relevantFollowersDataSourceProvider(pubkey, limit: limit));
  final entitiesPagedData = ref.watch(
    entitiesPagedDataProvider(
      dataSources,
      awaitMissingEvents: true,
    ),
  );

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
  final uniqueMasterPubkeys = LinkedHashSet<String>.of(masterPubkeys ?? const <String>{}).toList();

  final result = (
    hasMore: entitiesPagedData?.hasMore ?? false,
    masterPubkeys: uniqueMasterPubkeys,
    // Approximate number of items that is enough to cover the viewport.
    ready: uniqueMasterPubkeys.length >= 12 || entitiesPagedData?.data is! PagedLoading,
  );

  return result;
}
