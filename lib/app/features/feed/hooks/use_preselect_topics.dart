// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/selected_interests_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/related_hashtag.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';

void usePreselectTopics(
  WidgetRef ref, {
  required EventReference? eventReference,
}) {
  useOnInit(
    () {
      if (eventReference != null) {
        final modifiedEntity =
            ref.read(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

        final relatedHashtags = switch (modifiedEntity) {
          ModifiablePostEntity() => modifiedEntity.data.relatedHashtags,
          ArticleEntity() => modifiedEntity.data.relatedHashtags,
          _ => throw UnsupportedEventReference(eventReference),
        };
        final topics = RelatedHashtag.extractTopics(relatedHashtags);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(selectedInterestsNotifierProvider.notifier).interests = topics,
        );
      }
    },
  );
}
