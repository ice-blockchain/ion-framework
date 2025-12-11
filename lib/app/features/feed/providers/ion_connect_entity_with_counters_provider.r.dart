// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_entity_with_counters_provider.r.g.dart';

@riverpod
IonConnectEntity? ionConnectSyncEntityWithCounters(
  Ref ref, {
  required EventReference eventReference,
  bool network = true,
  bool cache = true,
}) {
  final currentUser = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentUser == null) {
    throw const CurrentUserNotFoundException();
  }

  final kind = eventReference.kind;

  if (kind == null || !_hasCounters(kind)) {
    return ref.watch(ionConnectSyncEntityProvider(eventReference: eventReference));
  }

  final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    throw const CurrentUserNotFoundException();
  }

  final search = _buildSearchForCounters(currentUserPubkey: currentUserPubkey, kind: kind);

  return ref.watch(
    ionConnectSyncEntityProvider(
      cache: cache,
      search: search,
      network: network,
      eventReference: eventReference,
    ),
  );
}

@riverpod
Future<IonConnectEntity?> ionConnectEntityWithCounters(
  Ref ref, {
  required EventReference eventReference,
  bool network = true,
  bool cache = true,
}) async {
  final currentUser = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentUser == null) {
    throw const CurrentUserNotFoundException();
  }

  final kind = eventReference.kind;

  if (kind == null || !_hasCounters(kind)) {
    return ref.watch(ionConnectEntityProvider(eventReference: eventReference).future);
  }

  final currentUserPubkey = ref.watch(currentPubkeySelectorProvider);
  if (currentUserPubkey == null) {
    throw const CurrentUserNotFoundException();
  }

  final search = _buildSearchForCounters(currentUserPubkey: currentUserPubkey, kind: kind);

  return ref.watch(
    ionConnectEntityProvider(
      cache: cache,
      search: search,
      network: network,
      eventReference: eventReference,
    ).future,
  );
}

// Do not query counters and deps if the entity doesn't need it (e.g. a repost)
bool _hasCounters(int kind) {
  return [
    ModifiablePostEntity.kind,
    PostEntity.kind,
    ArticleEntity.kind,
    CommunityTokenDefinitionEntity.kind,
    CommunityTokenActionEntity.kind,
  ].any((kindWithCounters) => kindWithCounters == kind);
}

String _buildSearchForCounters({
  required String currentUserPubkey,
  required int kind,
}) {
  return SearchExtensions([
    ...SearchExtensions.withCounters(
      currentPubkey: currentUserPubkey,
      forKind: kind,
    ).extensions,
    if (kind == CommunityTokenDefinitionEntity.kind) ...[
      FollowingListSearchExtension(forKind: kind),
      FollowersCountSearchExtension(forKind: kind),
    ],
    if (kind == CommunityTokenActionEntity.kind)
      GenericIncludeSearchExtension(
        forKind: kind,
        includeKind: CommunityTokenDefinitionEntity.kind,
      ),
  ]).toString();
}
