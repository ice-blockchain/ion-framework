// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata_lite.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_metadata_lite_provider.r.g.dart';

@riverpod
Future<UserMetadataLiteEntity?> cachedUserMetadataLite(
  Ref ref, {
  required String masterPubkey,
}) async {
  final userMetadataLite = await ref.watch(
    ionConnectEntityProvider(
      network: false,
      eventReference: ReplaceableEventReference(
        masterPubkey: masterPubkey,
        kind: UserMetadataLiteEntity.kind,
      ),
    ).future,
  ) as UserMetadataLiteEntity?;
  return userMetadataLite;
}
