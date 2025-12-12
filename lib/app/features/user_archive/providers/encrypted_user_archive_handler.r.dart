// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/user_archive/model/database/user_archive_database.m.dart';
import 'package:ion/app/features/user_archive/model/entities/user_archive_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'encrypted_user_archive_handler.r.g.dart';

class EncryptedUserArchiveHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  EncryptedUserArchiveHandler(this.userArchiveEventDao);

  final UserArchiveEventDao userArchiveEventDao;

  @override
  bool canHandle({required IonConnectGiftWrapEntity entity}) {
    return entity.data.kinds.containsList([
      UserArchiveEntity.kind.toString(),
    ]);
  }

  @override
  Future<EventReference?> handle(EventMessage rumor) async {
    final entity = UserArchiveEntity.fromEventMessage(rumor);

    await userArchiveEventDao.add(rumor);
    return entity.toEventReference();
  }
}

@riverpod
EncryptedUserArchiveHandler encryptedUserArchiveHandler(Ref ref) {
  return EncryptedUserArchiveHandler(ref.watch(userArchiveEventDaoProvider));
}
