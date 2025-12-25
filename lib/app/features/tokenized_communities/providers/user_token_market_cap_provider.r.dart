// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_token_market_cap_provider.r.g.dart';

@riverpod
Stream<double?> userTokenMarketCap(Ref ref, String pubkey) async* {
  final userMetadata = await ref.read(
    userMetadataProvider(pubkey, network: false).future,
  );
  if (userMetadata == null) {
    yield null;
    return;
  }

  final eventReference = userMetadata.toEventReference();
  final eventReferenceString = eventReference.toString();

  final controller = StreamController<double?>();

  final initialAsync = ref.read(
    tokenMarketInfoProvider(eventReferenceString, eventReference: eventReference),
  );
  controller.add(initialAsync.valueOrNull?.marketData.marketCap);

  final subscription = ref.listen(
    tokenMarketInfoProvider(eventReferenceString, eventReference: eventReference),
    (_, next) {
      final tokenInfo = next.valueOrNull;
      final marketCap = tokenInfo?.marketData.marketCap;
      if (!controller.isClosed) {
        controller.add(marketCap);
      }
    },
  );

  ref.onDispose(() {
    subscription.close();
    controller.close();
  });

  // Yield all values from controller (initial + updates)
  await for (final marketCap in controller.stream) {
    yield marketCap;
  }
}
