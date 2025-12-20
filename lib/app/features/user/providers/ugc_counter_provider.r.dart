// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/user/providers/count_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ugc_counter_provider.r.g.dart';

@riverpod
class UgcCounter extends _$UgcCounter {
  @override
  FutureOr<int?> build({
    bool cache = true,
    bool network = true,
  }) async {
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);
    if (currentPubkey == null) {
      return null;
    }

    final filters = [
      RequestFilter(
        kinds: const [
          PostEntity.kind,
          ModifiablePostEntity.kind,
          ArticleEntity.kind,
        ],
        authors: [currentPubkey],
        search: 'expiration:false !amarker:reply !emarker:reply',
      ),
    ];

    final count = await ref.watch(
      countProvider(
        key: 'ugc_counter_$currentPubkey',
        type: EventCountResultType.ugc,
        requestData: EventCountRequestData(filters: filters),
        actionSource: ActionSourceUser(currentPubkey),
        cacheExpirationDuration: const Duration(minutes: 5),
        cache: cache,
        network: network,
      ).future,
    );

    return count is int ? count : null;
  }
}
