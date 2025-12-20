// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';
import 'package:ion/app/features/user/providers/count_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ugc_counter_provider.r.g.dart';

@riverpod
class UgcCounter extends _$UgcCounter {
  @override
  FutureOr<int> build({
    bool cache = true,
    bool network = true,
  }) async {
    final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);

    if (currentIdentityKeyName == null) {
      return 0;
    }

    final filters = [
      RequestFilter(
        kinds: const [
          PostEntity.kind,
          ModifiablePostEntity.kind,
          ArticleEntity.kind,
        ],
        authors: [currentIdentityKeyName],
        search: 'expiration:false !amarker:reply !emarker:reply',
      ),
    ];

    try {
      final count = await ref.watch(
        countProvider(
          key: 'ugc_counter_$currentIdentityKeyName',
          type: EventCountResultType.ugc,
          requestData: EventCountRequestData(filters: filters),
          actionSource: ActionSourceUser(currentIdentityKeyName),
          cacheExpirationDuration: const Duration(minutes: 5),
          cache: cache,
          network: network,
        ).future,
      );

      return count is int ? count : 0;
    } catch (e) {
      // If count fails, return 0 and let the user retry
      return 0;
    }
  }
}

/// Helper to create the next UGC serial label
Future<EntityLabel?> getNextUgcSerialLabel(WidgetRef ref) async {
  final currentCount = await ref.read(ugcCounterProvider().future);
  final nextValue = currentCount + 1;

  return EntityLabel(
    values: [nextValue.toString()],
    namespace: EntityLabelNamespace.ugcSerial,
  );
}
