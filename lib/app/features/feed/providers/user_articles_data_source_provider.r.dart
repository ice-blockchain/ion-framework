// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/ion_connect/providers/entities_paged_data_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_articles_data_source_provider.r.g.dart';

@riverpod
List<EntitiesDataSource>? userArticlesDataSource(Ref ref, String pubkey) {
  final currentPubkey = ref.watch(currentPubkeySelectorProvider);

  if (currentPubkey == null) {
    return null;
  }

  final search = SearchExtensions([
    ...SearchExtensions.withCounters(
      currentPubkey: currentPubkey,
      forKind: ArticleEntity.kind,
    ).extensions,
    ...SearchExtensions.withTokens(forKind: ArticleEntity.kind).extensions,
  ]).toString();

  return [
    EntitiesDataSource(
      actionSource: ActionSourceUser(pubkey),
      entityFilter: (entity) =>
          entity.masterPubkey == pubkey &&
          (entity is ArticleEntity || entity is GenericRepostEntity),
      requestFilter: RequestFilter(
        kinds: const [ArticleEntity.kind, GenericRepostEntity.articleRepostKind],
        authors: [pubkey],
        search: search,
        limit: 10,
      ),
    ),
  ];
}
