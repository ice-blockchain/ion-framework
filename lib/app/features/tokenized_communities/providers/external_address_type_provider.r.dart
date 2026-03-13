// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_market_info_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'external_address_type_provider.r.g.dart';

/// Provides the [ExternalAddressType] for a given external address.
///
/// It fetches the token info associated with the external address, then
/// fetches the token definition based on the token info, and finally
/// determines the external address type from the token definition.
///
/// When the token definition is unavailable (e.g. relay lag), falls back to
/// inferring the type from market info.
///
/// [IMPORTANT]: This provider works only with the existing tokens.
/// If u need to get `ExternalAddressType` for an ion connect entity, use `entity.externalAddressType` instead.
@riverpod
Future<ExternalAddressType?> externalAddressType(
  Ref ref, {
  required String externalAddress,
}) async {
  CommunityTokenDefinitionEntity? tokenDefinitionEntity;
  try {
    tokenDefinitionEntity = await ref
        .watch(tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress).future);
  } catch (_) {
    // Token definition fetch can throw (e.g. relay lag, missing creator address).
    // Fall through to market-info fallback below.
  }

  if (tokenDefinitionEntity != null) {
    final resolved = await _resolveFromDefinition(ref, tokenDefinitionEntity);
    if (resolved != null) return resolved;
  }

  return _inferFromMarketInfo(ref, externalAddress);
}

Future<ExternalAddressType?> _resolveFromDefinition(
  Ref ref,
  CommunityTokenDefinitionEntity entity,
) async {
  final tokenDefinition = entity.data;

  if (tokenDefinition is CommunityTokenDefinitionExternal) {
    return const ExternalAddressType.x();
  }

  if (tokenDefinition is CommunityTokenDefinitionIon) {
    final ionEntity = await ref
        .watch(ionConnectEntityProvider(eventReference: tokenDefinition.eventReference).future);
    return ionEntity?.externalAddressType;
  }

  return null;
}

/// Best-effort fallback: infer [ExternalAddressType] from market info when the
/// token definition is not available (relay lag / replica inconsistency).
Future<ExternalAddressType?> _inferFromMarketInfo(
  Ref ref,
  String externalAddress,
) async {
  final tokenInfo = await ref.watch(tokenMarketInfoProvider(externalAddress).future);
  if (tokenInfo == null) return null;

  if (tokenInfo.source.isTwitter) {
    return const ExternalAddressType.x();
  }

  final ionAddress = tokenInfo.addresses.ionConnect;
  if (ionAddress == null) return null;

  final kindStr = UserMetadataEntity.kind.toString();
  if (ionAddress.startsWith(kindStr)) {
    return const ExternalAddressType.ionConnectUser();
  }

  final articleKindStr = ArticleEntity.kind.toString();
  if (ionAddress.startsWith(articleKindStr)) {
    return const ExternalAddressType.ionConnectArticle();
  }

  return const ExternalAddressType.ionConnectTextPost();
}
