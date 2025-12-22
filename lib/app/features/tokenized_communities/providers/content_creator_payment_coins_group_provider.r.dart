// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/creator_token_utils.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/wallets/model/coins_group.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_creator_payment_coins_group_provider.r.g.dart';

@riverpod
Future<CoinsGroup> contentCreatorPaymentCoinsGroup(
  Ref ref, {
  required String externalAddress,
  required ExternalAddressType externalAddressType,
  EventReference? eventReference,
}) async {
  if (!externalAddressType.isContentToken) {
    throw StateError('contentCreatorPaymentCoinsGroup called for non-content token type.');
  }

  final masterPubkey = MasterPubkeyResolver.resolve(
    externalAddress,
    eventReference: eventReference,
  );

  final creatorTokenReference = ReplaceableEventReference(
    kind: UserMetadataEntity.kind,
    masterPubkey: masterPubkey,
  );
  final creatorTokenExternalAddress = creatorTokenReference.toString();

  final creatorTokenInfo = await ref.watch(
    tokenMarketInfoProvider(creatorTokenExternalAddress).future,
  );
  if (creatorTokenInfo == null) {
    throw TokenInfoNotFoundException(creatorTokenExternalAddress);
  }

  final creatorTokenAddress = creatorTokenInfo.addresses.blockchain;
  if (creatorTokenAddress == null || creatorTokenAddress.isEmpty) {
    throw TokenAddressNotFoundException(creatorTokenExternalAddress);
  }

  final bscNetwork = await ref.watch(bscNetworkDataProvider.future);

  final group = await CreatorTokenUtils.deriveCreatorTokenCoinsGroup(
    token: creatorTokenInfo,
    externalAddress: creatorTokenExternalAddress,
    network: bscNetwork,
  );
  if (group == null) {
    throw StateError('Failed to build creator payment coins group.');
  }

  return group;
}
