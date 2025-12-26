// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/search/model/chat_search_result_item.f.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_local_user_search_provider.r.dart';
import 'package:ion/app/features/search/providers/chat_search/chat_messages_search_provider.r.dart';
import 'package:ion/app/features/user/providers/search_users_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_advanced_search_all_results_provider.r.g.dart';

@riverpod
Future<List<ChatSearchResultItem>> chatAdvancedSearchAllResults(
  Ref ref,
  String query,
) async {
  final remoteUserSearch = await ref.watch(searchUsersProvider(query: query).future);
  final localUserSearch = await ref.watch(chatLocalUserSearchProvider(query).future);
  final localMessageSearch = await ref.watch(chatMessagesSearchProvider(query).future);

  return [
    ...?localMessageSearch,
    ...?localUserSearch,
    if (remoteUserSearch?.masterPubkeys != null)
      ...remoteUserSearch!.masterPubkeys!.map(
        (masterPubkey) => ChatSearchResultItem(masterPubkey: masterPubkey),
      ),
  ].distinctBy((item) => item.masterPubkey).toList();
}
