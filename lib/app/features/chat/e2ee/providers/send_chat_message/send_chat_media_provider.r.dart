// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:async/async.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/compress_chat_media_provider.r.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/database/event_messages_database.m.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/entity_expiration.f.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_upload_notifier.m.dart';
import 'package:ion/app/services/compressors/video_compressor.r.dart';
import 'package:ion/app/services/ion_connect/ed25519_key_store.dart';
import 'package:ion/app/services/media_service/blurhash_service.r.dart';
import 'package:ion/app/services/media_service/media_encryption_service.m.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_chat_media_provider.r.g.dart';

@Riverpod(keepAlive: true)
class SendChatMedia extends _$SendChatMedia {
  CancelableOperation<AsyncValue<List<MediaAttachment>>>? _cancellableOperation;

  @override
  Future<List<MediaAttachment>> build(int messageMediaId) async {
    return [];
  }

  Future<List<(String, List<MediaAttachment>)>> sendChatMedia(
    List<String> participantsMasterPubkeys,
    MediaFile mediaFile,
  ) async {
    final mediaAttachments = <MediaAttachment>[];
    final result = <(String, List<MediaAttachment>)>[];

    state = const AsyncLoading();

    _cancellableOperation = CancelableOperation.fromFuture(
      AsyncValue.guard(() async {
        final compressedMediaFile = await ref.read(
          compressChatMediaProvider(mediaFile),
        );

        for (final participantKey in participantsMasterPubkeys) {
          if (_cancellableOperation?.isCanceled ?? false) {
            return [];
          }

          final processedAttachments = await _processMedia(
            compressedMediaFile,
            participantKey,
          );

          mediaAttachments.addAll(processedAttachments);
          result.add((participantKey, processedAttachments));
        }

        if (_cancellableOperation?.isCanceled ?? false) {
          return [];
        }

        return mediaAttachments;
      }),
    );

    final operation = await _cancellableOperation?.valueOrCancellation(
      const AsyncValue.data([]),
    );

    state = operation!;

    if (_cancellableOperation?.isCanceled ?? false) {
      return [];
    }

    return result;
  }

  Future<void> cancel() async {
    await _cancellableOperation?.cancel();
    await ref.read(messageMediaDaoProvider).cancel(messageMediaId);
  }

  Future<List<MediaAttachment>> _processMedia(
    MediaFile mediaFile,
    String masterPubkey,
  ) async {
    final mediaAttachments = <MediaAttachment>[];
    final oneTimeEventSigner = await Ed25519KeyStore.generate();
    final env = ref.read(envProvider.notifier);

    final isVideo = mediaFile.mimeType?.startsWith('video/') ?? false;
    final isImage = mediaFile.mimeType?.startsWith('image/') ?? false;

    var blurHash = await ref.read(generateBlurhashProvider(mediaFile));
    String? thumbUrl;

    if (isVideo) {
      final thumbMediaFile = await ref.read(videoCompressorProvider).getThumbnail(mediaFile);
      blurHash = await ref.read(generateBlurhashProvider(thumbMediaFile));
      final thumbMediaAttachment = (await _processMedia(thumbMediaFile, masterPubkey)).first;
      mediaAttachments.add(thumbMediaAttachment);
      thumbUrl = thumbMediaAttachment.url;
    }

    final encryptedMediaFile = await ref.read(mediaEncryptionServiceProvider).encryptMediaFile(
          mediaFile,
        );

    final uploadResult = await ref.read(ionConnectUploadNotifierProvider.notifier).upload(
          encryptedMediaFile.mediaFile,
          alt: FileAlt.message,
          customEventSigner: oneTimeEventSigner,
        );

    if (isImage) {
      thumbUrl = uploadResult.mediaAttachment.url;
    }

    final mediaMetadataEvent = await uploadResult.fileMetadata
        .copyWith(
      blurhash: blurHash,
      thumb: thumbUrl,
    )
        .toEventMessage(
      oneTimeEventSigner,
      tags: [
        EntityExpiration(
          value: DateTime.now()
              .add(
                Duration(hours: env.get<int>(EnvVariable.GIFT_WRAP_EXPIRATION_HOURS)),
              )
              .microsecondsSinceEpoch,
        ).toTag(),
      ],
    );

    unawaited(
      ref.read(ionConnectNotifierProvider.notifier).sendEvent(
            mediaMetadataEvent,
            actionSource: ActionSource.user(masterPubkey, anonymous: true),
            cache: false,
          ),
    );

    final mediaAttachment = uploadResult.mediaAttachment.copyWith(
      blurhash: blurHash,
      encryptionKey: encryptedMediaFile.secretKey,
      encryptionNonce: encryptedMediaFile.nonce,
      encryptionMac: encryptedMediaFile.mac,
      thumb: thumbUrl,
    );
    return [
      mediaAttachment,
      ...mediaAttachments,
    ];
  }
}
