// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/token_action_first_buy_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_action_first_buy_provider.r.g.dart';

@riverpod
Future<CommunityTokenActionEntity?> cachedTokenActionFirstBuy(
  Ref ref, {
  /// The master public key of the user who made the first buy.
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

@riverpod
Future<CommunityTokenActionEntity?> ionConnectEntityTokenActionFirstBuy(
  Ref ref, {
  required EventReference eventReference,
}) async {
  final kind = eventReference.kind;

  if (kind == null) {
    throw UnknownEventReferenceKind(eventReference);
  }

  final tokenDefinition = CommunityTokenDefinitionIon.fromEventReference(
    eventReference: eventReference,
    kind: kind,
    type: CommunityTokenDefinitionIonType.original,
  );

  final tokenDefinitionReference =
      tokenDefinition.toReplaceableEventReference(eventReference.masterPubkey);

  return ref.watch(
    cachedTokenActionFirstBuyProvider(
      masterPubkey: '',
      tokenDefinitionReference: tokenDefinitionReference,
    ).future,
  );
}

@riverpod
Future<bool> ionConnectEntityHasToken(
  Ref ref, {
  required EventReference eventReference,
}) async {
  final firstBuyAction = await ref.watch(
    ionConnectEntityTokenActionFirstBuyProvider(eventReference: eventReference).future,
  );

  return firstBuyAction != null;
}
