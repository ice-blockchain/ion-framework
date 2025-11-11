// SPDX-License-Identifier: ice License 1.0

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_message_entity_interface.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/compressors/audio_compressor.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_message_media_path_provider.r.g.dart';

@riverpod
Future<String?> chatMessageMediaPath(
  Ref ref, {
  required EncryptedMessageEntityWithMedia entity,
  String? cacheKey,
  MediaAttachment? mediaAttachment,
  bool loadThumbnail = true,
  bool convertAudioToWav = false,
}) async {
  if (cacheKey != null) {
    final cachedFile = await ref.watch(mediaServiceProvider).getFileFromAppDirectory(cacheKey);

    if (cachedFile != null) {
      if (convertAudioToWav && !cachedFile.path.endsWith('.wav')) {
        final wavFilePath =
            await ref.watch(audioCompressorProvider).compressAudioToWav(cachedFile.path);
        return wavFilePath;
      }
      return cachedFile.path;
    }
  }

  // If no cached file and no media attachment, exit
  if (mediaAttachment == null) {
    return null;
  }

  final MediaAttachment? mediaAttachmentToLoad;
  if (loadThumbnail) {
    // Get thumbnail from media attachments
    mediaAttachmentToLoad =
        entity.data.media.values.firstWhereOrNull((e) => e.url == mediaAttachment.thumb);

    if (mediaAttachmentToLoad == null) {
      return null;
    }
  } else {
    mediaAttachmentToLoad = mediaAttachment;
  }

  final encryptedMedia = await ref
      .watch(mediaEncryptionServiceProvider)
      .getEncryptedMedia(mediaAttachmentToLoad, authorPubkey: entity.masterPubkey);

  if (convertAudioToWav && !encryptedMedia.path.endsWith('.wav')) {
    final wavFilePath =
        await ref.watch(audioCompressorProvider).compressAudioToWav(encryptedMedia.path);
    return wavFilePath;
  }

  return encryptedMedia.path;
}
