// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_action_first_buy_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_action_first_buy_provider.r.g.dart';

@riverpod
Future<CommunityTokenActionEntity?> cachedTokenFirstBuyAction(
  Ref ref, {
  required String masterPubkey,
  required EventReference tokenDefinitionReference,
}) async {
  final firstBuyReference = TokenActionFirstBuyReference.buildEventReference(
    masterPubkey: masterPubkey,
    tokenDefinitionReference: tokenDefinitionReference,
  );

  final firstBuyReferenceEntity = await ref
      .watch(ionConnectEntityProvider(eventReference: firstBuyReference, network: false).future);

  if (firstBuyReferenceEntity is! TokenActionFirstBuyReferenceEntity) {
    return null;
  }

  final firstBuyEntity = await ref.watch(
    ionConnectEntityProvider(
      eventReference: firstBuyReferenceEntity.data.tokenActionReference,
      network: false,
    ).future,
  );

  if (firstBuyEntity is! CommunityTokenActionEntity) {
    return null;
  }

  return firstBuyEntity;
}

/// Checks whether the ion connect entity identified by [eventReference]
/// has a token (was bought by someone) by querying for the first-buy definition.
@riverpod
Future<bool> ionConnectEntityHasToken(
  Ref ref, {
  required EventReference eventReference,
}) async {
  final firstBuyAction = await ref.watch(
    cachedTokenDefinitionProvider(
      externalAddress: eventReference.toString(),
      type: CommunityTokenDefinitionIonType.firstBuyAction,
    ).future,
  );

  return firstBuyAction != null;
}

@riverpod
Future<bool?> currentUserHasToken(Ref ref) async {
  final currentUserMetadata = ref.watch(currentUserMetadataProvider).valueOrNull;
  if (currentUserMetadata == null) return null;

  return ref
      .watch(
        ionConnectEntityHasTokenProvider(eventReference: currentUserMetadata.toEventReference()),
      )
      .value;
}
