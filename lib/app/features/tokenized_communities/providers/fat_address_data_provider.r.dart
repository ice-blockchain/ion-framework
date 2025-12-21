// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_data.f.dart';
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
}) async {
  final externalTypePrefix = externalAddressType.prefix;

  final isCreatorType = externalTypePrefix == const ExternalAddressType.ionConnectUser().prefix;
  if (isCreatorType) {
    return _buildCreatorFatAddressData(
      ref,
      externalAddress: externalAddress,
      externalTypePrefix: externalTypePrefix,
    );
  }

  return _buildContentFatAddressData(
    externalAddress: externalAddress,
    externalTypePrefix: externalTypePrefix,
  );
}

Future<FatAddressData> _buildCreatorFatAddressData(
  Ref ref, {
  required String externalAddress,
  required String externalTypePrefix,
}) async {
  final pubkey = _resolveCreatorPubkey(externalAddress);

  final metadata = await ref.watch(userMetadataProvider(pubkey).future);
  if (metadata == null) {
    throw StateError('Metadata not found for pubkey $pubkey');
  }

  final bscNetworkId = await _requireBscNetworkId(ref);
  final creatorAddress = metadata.data.wallets?[bscNetworkId];
  if (creatorAddress == null || creatorAddress.isEmpty) {
    throw StateError(
      'Creator wallet address is missing for pubkey $pubkey on network $bscNetworkId',
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

Future<FatAddressData> _buildContentFatAddressData({
  required String externalAddress,
  required String externalTypePrefix,
}) async {
  throw UnimplementedError(
    'Content fat address is not implemented yet. '
    'externalTypePrefix=$externalTypePrefix, externalAddress=$externalAddress',
  );
}

String _resolveCreatorPubkey(String externalAddress) {
  return ReplaceableEventReference.fromString(externalAddress).masterPubkey;
}

Future<String> _requireBscNetworkId(Ref ref) async {
  final networks = await ref.watch(networksProvider.future);
  final bscNetwork = networks.firstWhereOrNull((n) => n.isBsc && !n.isTestnet) ??
      networks.firstWhereOrNull((n) => n.isBsc);
  if (bscNetwork == null) {
    throw StateError('BSC network is missing');
  }
  return bscNetwork.id;
}
