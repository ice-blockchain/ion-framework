// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/model/rich_text.f.dart';

mixin EntityDataWithEncryptedMediaContent {
  String get content;

  Map<String, MediaAttachment> get media;

  RichText? get richText;

  bool get hasVideo =>
      media.values.any((media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.video);

  MediaAttachment? get primaryMedia => media.values.firstOrNull;

  MediaAttachment? get primaryVideo => media.values.firstWhereOrNull(
        (media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.video,
      );

  List<MediaAttachment> get visualMedias => media.values
      .where(
        (m) =>
            (m.mediaTypeEncrypted ?? m.mediaType) == MediaType.image ||
            (m.mediaTypeEncrypted ?? m.mediaType) == MediaType.video,
      )
      .toList();

  List<MediaAttachment> get videos => media.values
      .where((media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.video)
      .toList();

  MediaAttachment? get primaryAudio => media.values.firstWhereOrNull(
        (media) => (media.mediaTypeEncrypted ?? media.mediaType) == MediaType.audio,
      );
}
