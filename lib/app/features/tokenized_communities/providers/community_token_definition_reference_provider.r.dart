// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/providers/community_token_definition_builder_provider.r.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_reference_provider.r.g.dart';

@riverpod
Future<EventReference> communityTokenDefinitionReference(
  Ref ref, {
  required EventReference origEventReference,
}) async {
  final communityTokenDefinitionBuilder = ref.read(communityTokenDefinitionBuilderProvider);
  final communityTokenDefinition = await communityTokenDefinitionBuilder.build(
    origEventReference: origEventReference,
    type: CommunityTokenDefinitionType.original,
  );
  return communityTokenDefinition.toReplaceableEventReference(origEventReference.masterPubkey);
}
