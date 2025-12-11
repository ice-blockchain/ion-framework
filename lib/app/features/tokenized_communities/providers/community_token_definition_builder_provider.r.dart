// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_builder_provider.r.g.dart';

class CommunityTokenDefinitionBuilder {
  CommunityTokenDefinitionBuilder({
    required Future<IonConnectEntity?> Function(EventReference eventReference) getIonConnectEntity,
  }) : _getIonConnectEntity = getIonConnectEntity;

  final Future<IonConnectEntity?> Function(EventReference eventReference) _getIonConnectEntity;

  Future<CommunityTokenDefinition> build({
    required EventReference origEventReference,
    required CommunityTokenDefinitionType type,
  }) async {
    final kind = switch (origEventReference) {
      ReplaceableEventReference() => origEventReference.kind,
      _ => switch (await _getIonConnectEntity(origEventReference)) {
          PostEntity() => PostEntity.kind,
          _ => throw UnsupportedError('Unsupported IonConnectEntity $origEventReference'),
        }
    };

    return CommunityTokenDefinition.fromEventReference(
      eventReference: origEventReference,
      kind: kind,
      type: type,
    );
  }
}

@riverpod
CommunityTokenDefinitionBuilder communityTokenDefinitionBuilder(Ref ref) {
  return CommunityTokenDefinitionBuilder(
    getIonConnectEntity: (eventReference) =>
        ref.read(ionConnectEntityProvider(eventReference: eventReference).future),
  );
}
