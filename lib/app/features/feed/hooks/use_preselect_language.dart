// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/selected_entity_language_notifier.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/ion_content_labeler/ion_content_labeler_provider.r.dart';

void usePreselectLanguage(
  WidgetRef ref, {
  required EventReference? eventReference,
}) {
  useOnInit(
    () {
      if (eventReference != null) {
        final modifiedEntity =
            ref.read(ionConnectEntityProvider(eventReference: eventReference)).valueOrNull;

        final languageLabel = switch (modifiedEntity) {
          ModifiablePostEntity() => modifiedEntity.data.language,
          ArticleEntity() => modifiedEntity.data.language,
          _ => throw UnsupportedEventReference(eventReference),
        };
        final language = languageLabel != null && languageLabel.values.isNotEmpty
            ? languageLabel.values.first
            : null;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(selectedEntityLanguageNotifierProvider.notifier).langLabel =
              language != null ? ContentLanguage(value: language) : null,
        );
      }
    },
  );
}
