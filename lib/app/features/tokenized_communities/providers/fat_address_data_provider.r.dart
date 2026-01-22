// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/suggested_token_details.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_v2.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/ion_identity/ion_identity_client_provider.r.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fat_address_data_provider.r.g.dart';

@riverpod
Future<FatAddressV2Data> fatAddressData(
  Ref ref, {
  required String externalAddress,
  required ExternalAddressType externalAddressType,
  EventReference? eventReference,

  /// Suggested token details for creation of the contentToken from token info API
  SuggestedTokenDetails? suggestedDetails,
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
    suggestedDetails: suggestedDetails,
  );
}

Future<FatAddressV2Data> _buildCreatorFatAddressData(
  Ref ref, {
  required String externalAddress,
  required String externalTypePrefix,
  required EventReference? eventReference,
}) async {
  final pubkey = MasterPubkeyResolver.resolve(externalAddress, eventReference: eventReference);

  final metadata = await ref.watch(userMetadataProvider(pubkey).future);
  if (metadata == null) {
    throw UserMetadataNotFoundException(pubkey);
  }

  final bscNetworkId = (await ref.watch(bscNetworkDataProvider.future)).id;
  final creatorAddress = metadata.data.wallets?[bscNetworkId];
  if (creatorAddress == null || creatorAddress.isEmpty) {
    throw CreatorWalletAddressNotFoundException(
      pubkey: pubkey,
      networkId: bscNetworkId,
    );
  }

  final affiliateAddress = await _resolveAffiliateAddress(
    ref,
    creatorMasterPubkey: pubkey,
    bscNetworkId: bscNetworkId,
  );

  final username = metadata.data.name.trim();
  final displayName = metadata.data.trimmedDisplayName.trim();

  final symbol = username.isNotEmpty ? username : pubkey;
  final name = displayName.isNotEmpty ? displayName : symbol;

  return FatAddressV2Data(
    tokens: [
      FatAddressV2TokenRecord(
        name: name,
        symbol: symbol,
        externalAddress: externalAddress,
        externalType: _externalTypeByte(externalTypePrefix),
      ),
    ],
    creatorAddress: creatorAddress,
    affiliateAddress: affiliateAddress,
  );
}

Future<FatAddressV2Data> _buildContentFatAddressData(
  Ref ref, {
  required String externalAddress,
  required String externalTypePrefix,
  required EventReference? eventReference,
  required SuggestedTokenDetails? suggestedDetails,
}) async {
  final masterPubkey =
      MasterPubkeyResolver.resolve(externalAddress, eventReference: eventReference);

  final metadata = await ref.watch(userMetadataProvider(masterPubkey).future);
  if (metadata == null) {
    throw UserMetadataNotFoundException(masterPubkey);
  }

  final bscNetworkId = (await ref.watch(bscNetworkDataProvider.future)).id;
  final creatorAddress = metadata.data.wallets?[bscNetworkId];
  if (creatorAddress == null || creatorAddress.isEmpty) {
    throw CreatorWalletAddressNotFoundException(
      pubkey: masterPubkey,
      networkId: bscNetworkId,
    );
  }

  final affiliateAddress = await _resolveAffiliateAddress(
    ref,
    creatorMasterPubkey: masterPubkey,
    bscNetworkId: bscNetworkId,
  );

  final creatorTokenExternalAddress = ReplaceableEventReference(
    kind: UserMetadataEntity.kind,
    masterPubkey: masterPubkey,
  ).toString();

  final creatorTokenInfo =
      await ref.watch(tokenMarketInfoProvider(creatorTokenExternalAddress).future);
  final creatorTokenExists = (creatorTokenInfo?.addresses.blockchain?.trim() ?? '').isNotEmpty;

  final tokens = <FatAddressV2TokenRecord>[];
  if (!creatorTokenExists) {
    final username = metadata.data.name.trim();
    final displayName = metadata.data.trimmedDisplayName.trim();

    final creatorSymbol = username.isNotEmpty ? username : masterPubkey;
    final creatorName = displayName.isNotEmpty ? displayName : creatorSymbol;

    tokens.add(
      FatAddressV2TokenRecord(
        name: creatorName,
        symbol: creatorSymbol,
        externalAddress: creatorTokenExternalAddress,
        externalType: _externalTypeByte(const ExternalAddressType.ionConnectUser().prefix),
      ),
    );
  }

  tokens.add(
    FatAddressV2TokenRecord(
      name: suggestedDetails?.name ?? masterPubkey,
      symbol: suggestedDetails?.ticker ?? externalAddress,
      externalAddress: externalAddress,
      externalType: _externalTypeByte(externalTypePrefix),
    ),
  );

  return FatAddressV2Data(
    tokens: tokens,
    creatorAddress: creatorAddress,
    affiliateAddress: affiliateAddress,
  );
}

Future<String?> _resolveAffiliateAddress(
  Ref ref, {
  required String creatorMasterPubkey,
  required String bscNetworkId,
}) async {
  try {
    final ionIdentityClient = await ref.watch(ionIdentityClientProvider.future);
    final socialProfile = await ionIdentityClient.users.getUserSocialProfile(
      userIdOrMasterKey: creatorMasterPubkey,
    );

    final referralMasterPubkey = socialProfile.referralMasterKey?.trim() ?? '';
    if (referralMasterPubkey.isEmpty) {
      return null;
    }

    final referralMetadata = await ref.watch(userMetadataProvider(referralMasterPubkey).future);
    final affiliateAddress = referralMetadata?.data.wallets?[bscNetworkId];
    if (affiliateAddress == null || affiliateAddress.isEmpty) {
      return null;
    }

    return affiliateAddress;
  } catch (_) {
    return null;
  }
}

int _externalTypeByte(String externalTypePrefix) {
  final trimmed = externalTypePrefix.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('externalTypePrefix must not be empty');
  }
  if (trimmed.length != 1) {
    throw FormatException('externalTypePrefix must be 1 character: $externalTypePrefix');
  }
  return trimmed.codeUnitAt(0);
}
