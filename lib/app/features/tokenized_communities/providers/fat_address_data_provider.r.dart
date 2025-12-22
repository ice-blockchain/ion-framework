// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_data.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fat_address_data_provider.r.g.dart';

@riverpod
Future<FatAddressData> fatAddressData(
  Ref ref, {
  required String externalAddress,
  required ExternalAddressType externalAddressType,
  EventReference? eventReference,
}) async {
  final externalTypePrefix = externalAddressType.prefix;

  final isCreatorType = externalTypePrefix == const ExternalAddressType.ionConnectUser().prefix;
  if (isCreatorType) {
    return _buildCreatorFatAddressData(
      ref,
      externalAddress: externalAddress,
      externalTypePrefix: externalTypePrefix,
      eventReference: eventReference,
    );
  }

  return _buildContentFatAddressData(
    ref,
    externalAddress: externalAddress,
    externalTypePrefix: externalTypePrefix,
    eventReference: eventReference,
  );
}

Future<FatAddressData> _buildCreatorFatAddressData(
  Ref ref, {
  required String externalAddress,
  required String externalTypePrefix,
  required EventReference? eventReference,
}) async {
  final pubkey = _resolveMasterPubkey(externalAddress, eventReference: eventReference);

  final metadata = await ref.watch(userMetadataProvider(pubkey).future);
  if (metadata == null) {
    throw UserMetadataNotFoundException(pubkey);
  }

  final bscNetworkId = await _requireBscNetworkId(ref);
  final creatorAddress = metadata.data.wallets?[bscNetworkId];
  if (creatorAddress == null || creatorAddress.isEmpty) {
    throw CreatorWalletAddressNotFoundException(
      pubkey: pubkey,
      networkId: bscNetworkId,
    );
  }

  final username = metadata.data.name.trim();
  final displayName = metadata.data.trimmedDisplayName.trim();

  final symbol = username.isNotEmpty ? username : pubkey;
  final name = displayName.isNotEmpty ? displayName : symbol;

  return FatAddressData.creator(
    symbol: symbol,
    name: name,
    externalAddress: externalAddress,
    externalTypePrefix: externalTypePrefix,
    creatorAddress: creatorAddress,
  );
}

Future<FatAddressData> _buildContentFatAddressData(
  Ref ref, {
  required String externalAddress,
  required String externalTypePrefix,
  required EventReference? eventReference,
}) async {
  final masterPubkey = _resolveMasterPubkey(externalAddress, eventReference: eventReference);

  final metadata = await ref.watch(userMetadataProvider(masterPubkey).future);
  if (metadata == null) {
    throw UserMetadataNotFoundException(masterPubkey);
  }

  final bscNetworkId = await _requireBscNetworkId(ref);
  final creatorAddress = metadata.data.wallets?[bscNetworkId];
  if (creatorAddress == null || creatorAddress.isEmpty) {
    throw CreatorWalletAddressNotFoundException(
      pubkey: masterPubkey,
      networkId: bscNetworkId,
    );
  }

  final creatorTokenReference = ReplaceableEventReference(
    kind: UserMetadataEntity.kind,
    masterPubkey: masterPubkey,
  );
  final creatorTokenExternalAddress = creatorTokenReference.toString();
  final creatorTokenInfo =
      await ref.watch(tokenMarketInfoProvider(creatorTokenExternalAddress).future);
  final creatorTokenAddress = creatorTokenInfo?.addresses.blockchain;
  if (creatorTokenAddress == null || creatorTokenAddress.isEmpty) {
    throw TokenAddressNotFoundException(creatorTokenExternalAddress);
  }

  return FatAddressData.content(
    symbol: externalAddress,
    name: masterPubkey,
    externalAddress: externalAddress,
    externalTypePrefix: externalTypePrefix,
    creatorAddress: creatorAddress,
    creatorTokenAddress: creatorTokenAddress,
  );
}

String _resolveMasterPubkey(String externalAddress, {required EventReference? eventReference}) {
  return eventReference?.masterPubkey ??
      ReplaceableEventReference.fromString(externalAddress).masterPubkey;
}

Future<String> _requireBscNetworkId(Ref ref) async {
  final networks = await ref.watch(networksProvider.future);
  final bscNetwork = networks.firstWhereOrNull((n) => n.isBsc && !n.isTestnet) ??
      networks.firstWhereOrNull((n) => n.isBsc);
  if (bscNetwork == null) {
    throw BscNetworkNotFoundException();
  }
  return bscNetwork.id;
}
