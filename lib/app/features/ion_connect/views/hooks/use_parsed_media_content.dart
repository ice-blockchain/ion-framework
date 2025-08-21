// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

/// Returns [content] in Delta format with excluded media links
/// and List of media attachments, extracted from the content.
({Delta content, List<MediaAttachment> media}) useParsedMediaContent({
  required EntityDataWithMediaContent data,
  required WidgetRef ref,
  Key? key,
}) {
  return useMemoized(
    () {
      final parsedMedia = ref.watch(parsedMediaProvider(data)).valueOrNull;

      if (parsedMedia == null) {
        return (
          content: Delta().blank,
          media: <MediaAttachment>[],
        );
      }
      return parsedMedia;
    },
    [data, key],
  );
}
