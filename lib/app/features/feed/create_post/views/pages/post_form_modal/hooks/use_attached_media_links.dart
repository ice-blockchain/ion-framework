// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';

ValueNotifier<Map<String, MediaAttachment>> useAttachedMediaLinksNotifier(
  WidgetRef ref, {
  required EventReference? modifiedEvent,
}) {
  final initialAttachedLinks = useMemoized(
    () {
      if (modifiedEvent == null) {
        return <String, MediaAttachment>{};
      }

      final modifiedEntity =
          ref.read(ionConnectEntityProvider(eventReference: modifiedEvent)).valueOrNull;

      if (modifiedEntity is! ModifiablePostEntity) {
        throw UnsupportedEventReference(modifiedEvent);
      }
      return modifiedEntity.data.media;
    },
  );
  return useState<Map<String, MediaAttachment>>(initialAttachedLinks);
}
