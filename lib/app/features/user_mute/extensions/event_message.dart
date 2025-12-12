// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user_mute/model/database/user_mute_database.m.dart';

extension UserMuteEventExtensions on EventMessage {
  UserMuteEventDbModel toMuteEventDbModel(EventReference eventReference) {
    return UserMuteEventDbModel(
      id: id,
      kind: kind,
      tags: tags,
      pubkey: pubkey,
      content: content,
      createdAt: createdAt,
      masterPubkey: masterPubkey,
      eventReference: eventReference,
    );
  }
}

extension UserMuteEventDbModelExtensions on UserMuteEventDbModel {
  EventMessage toEventMessage() {
    return EventMessage(
      id: id,
      kind: kind,
      pubkey: pubkey,
      createdAt: createdAt,
      content: content,
      tags: tags,
      sig: null,
    );
  }
}
