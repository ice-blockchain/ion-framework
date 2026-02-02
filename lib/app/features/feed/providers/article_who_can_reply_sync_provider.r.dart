// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/providers/selected_who_can_reply_option_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'article_who_can_reply_sync_provider.r.g.dart';

@riverpod
class ArticleWhoCanReplySync extends _$ArticleWhoCanReplySync {
  bool _initialized = false;

  @override
  WhoCanReplySettingsOption build(EventReference? modifiedEvent) {
    final selected = ref.watch(selectedWhoCanReplyOptionProvider);

    if (modifiedEvent == null) {
      return selected;
    }

    final entity = ref.watch(ionConnectEntityProvider(eventReference: modifiedEvent)).valueOrNull;
    if (!_initialized && entity is ArticleEntity) {
      ref.read(selectedWhoCanReplyOptionProvider.notifier).option = entity.data.whoCanReplySetting;
      _initialized = true;
      return entity.data.whoCanReplySetting;
    }

    return selected;
  }
}
