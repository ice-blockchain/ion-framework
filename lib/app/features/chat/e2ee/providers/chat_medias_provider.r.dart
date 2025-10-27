// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_medias_provider.r.g.dart';

@riverpod
Stream<List<MessageMediaTableData>> chatMedias(Ref ref, {required EventReference eventReference}) {
  return ref.watch(messageMediaDaoProvider).watchByEventId(eventReference);
}
