// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/user/providers/paginated_master_pubkeys_provider.r.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mention_suggestions_provider.r.g.dart';

@immutable
class _SearchUsersByKeyword {
  const _SearchUsersByKeyword(this.keyword);

  final String keyword;

  Future<List<IdentityUserInfo>> call(
    int limit,
    int offset,
    List<String> current,
    IONIdentityClient ionIdentityClient,
  ) {
    return ionIdentityClient.users.searchForUsersByKeyword(
      limit: limit,
      offset: offset,
      keyword: keyword,
      searchType: SearchUsersSocialProfileType.startsWith,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is _SearchUsersByKeyword && other.keyword == keyword;
  }

  @override
  int get hashCode => keyword.hashCode;
}

@riverpod
Future<List<String>> mentionSuggestions(Ref ref, String query) async {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty || !trimmedQuery.startsWith('@')) {
    return [];
  }

  final searchQuery = trimmedQuery.substring(1).toLowerCase();
  final paginatedMasterPubkeys = await ref.watch(
    paginatedMasterPubkeysProvider(
      _SearchUsersByKeyword(searchQuery).call,
    ).future,
  );

  return paginatedMasterPubkeys.items;
}
