// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/features/user/model/user_delegation.f.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_identification_proofs.r.g.dart';

@riverpod
Future<List<EventMessage>> deviceIdentificationProofs(
  Ref ref, {
  required EventMessage delegationEvent,
}) async {
  // 1) device signer (device keypair)
  final eventSigner = await ref.read(currentUserIonConnectEventSignerProvider.future);
  if (eventSigner == null) {
    throw EventSignerNotFoundException();
  }

  // 2) master pubkey (for the 'b' tag)
  final masterPubkey = ref.read(currentPubkeySelectorProvider);
  if (masterPubkey == null) {
    throw UserMasterPubkeyNotFoundException();
  }

  // 3) wrap 10100 => 21750 with correct references
  final wrapperData = EventsMetadataData(
    // This becomes the 'a' tag(s): '10100:<masterPubkey>:'
    eventReferences: [
      ReplaceableEventReference(
        masterPubkey: masterPubkey,
        kind: UserDelegationEntity.kind,
      ),
    ],
    // This becomes the inner JSON placed into `content`
    metadata: delegationEvent,
  );

  final wrapping21750 = await wrapperData.toEventMessage(
    eventSigner,
    tags: [
      MasterPubkeyTag(value: masterPubkey).toTag(),
    ],
  );

  final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);
  final proofs = await ionIdentityClient.users
      .getDeviceIdentificationProofs(eventJsonPayload: wrapping21750.jsonPayload);

  return proofs.map(EventMessage.fromPayloadJson).toList();
}
