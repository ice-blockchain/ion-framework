// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_message_load_media_provider.r.g.dart';

@Riverpod(keepAlive: true)
Raw<Future<File?>> chatMessageLoadMedia(
  Ref ref, {
  required EncryptedDirectMessageEntity entity,
  String? cacheKey,
  MediaAttachment? mediaAttachment,
  bool loadThumbnail = true,
}) async {
  if (cacheKey != null) {
    final cachedFile = await ref.watch(mediaServiceProvider).getFileFromAppDirectory(cacheKey);

    if (cachedFile != null) {
      return cachedFile;
    }
  }

  // If no cached file and no media attachment, exit
  if (mediaAttachment == null) {
    return null;
  }

  final MediaAttachment? mediaAttachmentToLoad;
  if (loadThumbnail) {
    // Get thumbnail from media attachments
    mediaAttachmentToLoad = entity.data.media.values.firstWhereOrNull(
      (e) => e.url == mediaAttachment.thumb,
    );

    if (mediaAttachmentToLoad == null) {
      return null;
    }
  } else {
    mediaAttachmentToLoad = mediaAttachment;
  }

  final encryptedMedia = await ref
      .watch(mediaEncryptionServiceProvider)
      .getEncryptedMedia(mediaAttachmentToLoad, authorPubkey: entity.masterPubkey);

  return encryptedMedia;
}
