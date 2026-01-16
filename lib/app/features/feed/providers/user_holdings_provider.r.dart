// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/providers/user_tokenized_community_data_source_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_holdings_provider.r.g.dart';

@riverpod
class UserHoldings extends _$UserHoldings with DelegatedPagedNotifier {
  @override
  ({Iterable<IonConnectEntity>? items, bool hasMore}) build(String pubkey) {
    final dataSources = ref.watch(userTokenizedCommunityDataSourceProvider(pubkey));
    if (dataSources == null) {
      return (items: null, hasMore: false);
    }

    final data = ref.watch(entitiesPagedDataProvider(dataSources));
    if (data == null) {
      return (items: null, hasMore: false);
    }

    return (items: data.data.items, hasMore: data.hasMore);
  }

  @override
  PagedNotifier getDelegate() {
    final dataSources = ref.read(userTokenizedCommunityDataSourceProvider(pubkey));
    if (dataSources == null) {
      throw StateError('Data sources not available for user holdings');
    }
    return ref.read(entitiesPagedDataProvider(dataSources).notifier);
  }
}
