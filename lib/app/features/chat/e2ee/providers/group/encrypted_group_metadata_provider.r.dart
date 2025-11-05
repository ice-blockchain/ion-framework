// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/chat/community/models/entities/tags/conversation_identifier.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/group_subject.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_group_metadata_provider.r.g.dart';

@riverpod
class EncryptedGroupMetadata extends _$EncryptedGroupMetadata {
  @override
  Stream<GroupMetadata> build(String id) async* {
    // Watch for all EventMessages that contain the group ID and empty content
    final results = ref.watch(eventMessageDaoProvider).watchAllFiltered(
      tags: [
        [GroupSubject.tagName],
        ConversationIdentifier(value: id).toTag(),
      ],
      kinds: [EncryptedGroupMessageEntity.kind],
    );

    final metadataEntities = results.map(
      (eventMessages) =>
          eventMessages.map(EncryptedGroupMessageEntity.fromEventMessage).toList()..sort(),
    );

    await for (final entities in metadataEntities) {
      // As for now, we only care about the latest metadata entity, but this will
      // be extended in the future to merge multiple entities and track changes over time.
      final lastEntity = entities.isNotEmpty ? entities.last : null;

      if (lastEntity != null) {
        yield GroupMetadata(
          id: id,
          members: lastEntity.data.members ?? [],
          name: lastEntity.data.groupSubject?.value ?? '',
          avatar: (masterPubkey: lastEntity.masterPubkey, media: lastEntity.data.primaryMedia),
        );
      }
    }
  }
}
