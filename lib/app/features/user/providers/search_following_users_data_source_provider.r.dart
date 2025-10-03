// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/follow_list_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_following_users_data_source_provider.r.g.dart';

@riverpod
List<EntitiesDataSource>? searchFollowingUsersDataSource(
  Ref ref,
  String pubkey, {
  required String query,
}) {
  if (query.isEmpty) return null;

  final followingList = ref.watch(followListProvider(pubkey)).valueOrNull;
  if (followingList == null) {
    return null;
  }
  return [
    EntitiesDataSource(
      actionSource: const ActionSourceCurrentUser(),
      entityFilter: (entity) => entity is UserMetadataEntity,
      requestFilter: RequestFilter(
        kinds: const [UserMetadataEntity.kind],
        authors: followingList.masterPubkeys,
        search: SearchExtensions(
          [
            QuerySearchExtension(searchQuery: query),
          ],
        ).toString(),
        limit: 20,
      ),
    ),
  ];
}
