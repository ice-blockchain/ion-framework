// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';

extension ParsedMediaWidgetRefX on WidgetRef {
  ({Delta content, List<MediaAttachment> media}) watchParsedMediaWithMentions(
    EntityDataWithMediaContent data,
  ) {
    final baseParsedMedia = parseMediaContent(data: data);
    final mentions = watch(mentionsOverlayProvider(data));

    final content = mentions.maybeWhen(
      data: (value) => value,
      orElse: () => baseParsedMedia.content,
    );

    return (content: content, media: baseParsedMedia.media);
  }
}
