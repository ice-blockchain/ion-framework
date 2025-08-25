// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_request_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/event_count_result_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/search_extension.dart';
import 'package:ion/app/features/user/providers/count_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stories_count_provider.r.g.dart';

@riverpod
FutureOr<int?> storiesCount(
  Ref ref,
  String pubkey,
) async {
  final search = SearchExtensions(
    [
      ExpirationSearchExtension(expiration: true),
    ],
  ).toString();

  final filters = [
    RequestFilter(
      kinds: const [ModifiablePostEntity.kind],
      authors: [pubkey],
      search: search,
    ),
  ];

  return await ref.watch(
    countProvider(
      actionSource: ActionSourceUser(pubkey),
      requestData: EventCountRequestData(
        filters: filters,
      ),
      key: pubkey,
      type: EventCountResultType.stories,
    ).future,
  ) as FutureOr<int?>;
}
