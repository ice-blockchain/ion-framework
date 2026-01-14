// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_tokenized_community_data_source_provider.r.g.dart';

const _requestKinds = [
  GenericRepostEntity.communityTokenDefinitionRepostKind,
  GenericRepostEntity.communityTokenActionRepostKind,
  CommunityTokenActionEntity.kind,
];

const _withCountersKinds = [
  CommunityTokenActionEntity.kind,
  CommunityTokenDefinitionEntity.kind,
];

@riverpod
List<EntitiesDataSource>? userTokenizedCommunityDataSource(Ref ref, String pubkey) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    return null;
  }

  final search = SearchExtensions([
    ...[
      for (final kind in _withCountersKinds)
        ...SearchExtensions.withCounters(forKind: kind, currentPubkey: currentPubkey).extensions,
    ],
    ...SearchExtensions.withAuthors(forKind: CommunityTokenActionEntity.kind).extensions,
    ...SearchExtensions.withAuthors(forKind: CommunityTokenDefinitionEntity.kind).extensions,
    FollowingListSearchExtension(forKind: CommunityTokenDefinitionEntity.kind),
    FollowersCountSearchExtension(forKind: CommunityTokenDefinitionEntity.kind),
    GenericIncludeSearchExtension(
      forKind: CommunityTokenActionEntity.kind,
      includeKind: CommunityTokenDefinitionEntity.kind,
    ),
  ]).toString();

  return [
    EntitiesDataSource(
      actionSource: ActionSourceUser(pubkey),
      entityFilter: (entity) =>
          entity.masterPubkey == pubkey &&
          (entity is CommunityTokenDefinitionEntity || entity is CommunityTokenActionEntity),
      requestFilter: RequestFilter(
        kinds: _requestKinds,
        authors: [pubkey],
        search: search,
        limit: 10,
      ),
    ),
  ];
}
