// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/tokenized_communities/providers/ion_connect_entity_has_token_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_token_market_cap_provider.r.g.dart';

@riverpod
Future<double?> userTokenMarketCap(Ref ref, String pubkey) async {
  final userMetadata = await ref.read(
    userMetadataProvider(pubkey, network: false).future,
  );
  if (userMetadata == null) return null;

  // Check if entity has token before requesting analytics
  final eventReference = userMetadata.toEventReference();
  final hasToken = await ref.watch(
    ionConnectEntityHasTokenProvider(
      eventReference: eventReference,
    ).future,
  );
  if (!hasToken) return null;

  // TODO: remove this after testing
  // TEMP: return a random market cap when the entity has a token
  final random = Random(eventReference.toString().hashCode);
  return random.nextDouble() * 490000 + 10000;
}
