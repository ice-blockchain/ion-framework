// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_post_message_provider.r.g.dart';

@riverpod
class SharedPostMessage extends _$SharedPostMessage {
  @override
  Future<IonConnectEntity?> build(EventReference eventReference) async {
    final kind16EventMessage =
        await ref.watch(eventMessageDaoProvider).getByReference(eventReference);
    final postEventMessage = EventMessage.fromPayloadJson(
      jsonDecode(kind16EventMessage.content) as Map<String, dynamic>,
    );

    final postEntity = switch (postEventMessage.kind) {
      PostEntity.kind => PostEntity.fromEventMessage(postEventMessage),
      ArticleEntity.kind => ArticleEntity.fromEventMessage(postEventMessage),
      ModifiablePostEntity.kind => ModifiablePostEntity.fromEventMessage(postEventMessage),
      CommunityTokenDefinitionEntity.kind =>
        CommunityTokenDefinitionEntity.fromEventMessage(postEventMessage),
      _ => null,
    };

    return postEntity;
  }
}
