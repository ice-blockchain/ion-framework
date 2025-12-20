import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/utils/external_address_extension.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'external_address_type_provider.r.g.dart';

/// Provides the [ExternalAddressType] for a given external address.
///
/// It fetches the token info associated with the external address, then
/// fetches the token definition based on the token info, and finally
/// determines the external address type from the token definition.
///
/// [IMPORTANT]: This provider works only with the existing tokens.
/// If u need to get `ExternalAddressType` for an ion connect entity, use `entity.externalAddressType` instead.
@riverpod
Future<ExternalAddressType?> externalAddressType(
  Ref ref, {
  required String externalAddress,
}) async {
  final tokenDefinitionEntity = await ref
      .watch(tokenDefinitionForExternalAddressProvider(externalAddress: externalAddress).future);

  if (tokenDefinitionEntity == null) return null;

  final tokenDefinition = tokenDefinitionEntity.data;

  if (tokenDefinition is CommunityTokenDefinitionExternal) {
    return const ExternalAddressType.x();
  }

  if (tokenDefinition is CommunityTokenDefinitionIon) {
    final entity = await ref
        .watch(ionConnectEntityProvider(eventReference: tokenDefinition.eventReference).future);

    if (entity == null) return null;

    return entity.externalAddressType;
  }

  return null;
}
