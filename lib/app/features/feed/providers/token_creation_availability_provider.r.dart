// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/bool.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/extensions/user_metadata.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_creation_availability_provider.r.g.dart';

@riverpod
bool tokenCreationAvailability(
  Ref ref, {
  required IonConnectEntity entity,
}) {
  final eventReference = entity.toEventReference();
  final userMetadata = ref.watch(userMetadataProvider(eventReference.masterPubkey));
  final ownerHasBscWallet = (userMetadata.valueOrNull?.hasBscWallet).falseOrValue;

  // TODO: Get tokenized communities release timestamp from Remote Config and compare with entity.publishedTimestamp.
  const isPublishedAfterTcRelease = true;

  return ownerHasBscWallet && isPublishedAfterTcRelease;
}
