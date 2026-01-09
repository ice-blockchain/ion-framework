// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/domain/content_payment_token_resolver_service.dart';
import 'package:ion/app/features/tokenized_communities/providers/bsc_network_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/trade_infrastructure_providers.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_payment_token_context_provider.r.g.dart';

@riverpod
ContentPaymentTokenResolverService contentPaymentTokenResolverService(Ref ref) {
  return const ContentPaymentTokenResolverService();
}

@riverpod
Future<ContentPaymentTokenContext?> contentPaymentTokenContext(
  Ref ref, {
  required String externalAddress,
  required ExternalAddressType externalAddressType,
  EventReference? eventReference,
}) async {
  if (!externalAddressType.isContentToken) {
    return null;
  }

  final creatorMasterPubkey = MasterPubkeyResolver.resolve(
    externalAddress,
    eventReference: eventReference,
  );
  final creatorTokenExternalAddress = ReplaceableEventReference(
    kind: UserMetadataEntity.kind,
    masterPubkey: creatorMasterPubkey,
  ).toString();

  final (creatorTokenInfo, bscNetwork, supportedSwapTokens) = await (
    ref.watch(tokenMarketInfoProvider(creatorTokenExternalAddress).future),
    ref.watch(bscNetworkDataProvider.future),
    ref.watch(supportedSwapTokensProvider.future),
  ).wait;

  final service = ref.watch(contentPaymentTokenResolverServiceProvider);
  return service.resolve(
    creatorTokenInfo: creatorTokenInfo,
    creatorTokenExternalAddress: creatorTokenExternalAddress,
    bscNetwork: bscNetwork,
    supportedSwapTokens: supportedSwapTokens,
  );
}
