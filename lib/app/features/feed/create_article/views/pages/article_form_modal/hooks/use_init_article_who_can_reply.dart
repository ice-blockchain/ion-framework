// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/providers/selected_who_can_reply_option_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

void useInitArticleWhoCanReply(WidgetRef ref, {EventReference? modifiedEvent}) {
  final modifiableEntity = modifiedEvent != null
      ? ref.watch(ionConnectEntityProvider(eventReference: modifiedEvent)).valueOrNull
      : null;

  useOnInit(
    () {
      if (modifiableEntity is ArticleEntity) {
        ref.read(selectedWhoCanReplyOptionProvider.notifier).option =
            modifiableEntity.data.whoCanReplySetting;
      }
    },
    [modifiableEntity],
  );
}
