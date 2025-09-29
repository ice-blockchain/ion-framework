// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/core/providers/ion_connect_media_url_fallback_provider.r.dart';
import 'package:ion/app/features/core/services/global_long_lived_isolate.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/compressors/brotli_compressor.r.dart';
import 'package:ion/app/services/file_cache/ion_file_cache_manager.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/services/media_service/mime_resolver/mime_resolver.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_encryption_service.m.freezed.dart';
part 'media_encryption_service.m.g.dart';

class MediaEncryptionService {
  MediaEncryptionService({
    required this.fileCacheService,
    required this.brotliCompressor,
    required this.generateMediaUrlFallback,
  });

  final FileCacheService fileCacheService;
  final BrotliCompressor brotliCompressor;
  final Future<String?> Function(String url, {required String authorPubkey})
      generateMediaUrlFallback;

  Future<File> retrieveEncryptedMedia(
    MediaAttachment attachment, {
    required String authorPubkey,
  }) async {
    try {
      if (attachment.encryptionKey != null &&
          attachment.encryptionNonce != null &&
          attachment.encryptionMac != null) {
        final url = attachment.url;

        final cacheFileInfo = await fileCacheService.getFileFromCache(url);

        if (cacheFileInfo != null) {
          return cacheFileInfo.file;
        }

        final file = await _downloadFile(url, authorPubkey: authorPubkey);

        final decryptedFileBytes = await globalLongLivedIsolate.compute(
          (args) async {
            return decryptMediaFileFn(args);
          },
          (file: file, attachment: attachment),
        );
        final decryptedFile = File.fromRawPath(decryptedFileBytes);

        final mimeType =
            ionMimeTypeResolver.lookup(decryptedFile.path, headerBytes: decryptedFileBytes);

        final fileExtension = mimeType != null ? extensionFromMime(mimeType) ?? '' : '';

        await fileCacheService.removeFile(url);

        final mediaType = mimeType != null ? MediaType.fromMimeType(mimeType) : MediaType.unknown;

        if (mediaType == MediaType.unknown) {
          final decompressedFile = await brotliCompressor.decompress(decryptedFileBytes);

          final decryptedFile = await fileCacheService.putFile(
            url: url,
            bytes: decompressedFile.readAsBytesSync(),
            fileExtension: fileExtension,
          );

          return decryptedFile;
        } else {
          final decryptedFile = await fileCacheService.putFile(
            url: url,
            bytes: decryptedFileBytes,
            fileExtension: fileExtension,
          );
          return decryptedFile;
        }
      } else {
        Logger.error('Media does not have a valid encryption prop');
        throw FailedToDecryptFileException();
      }
    } catch (e, st) {
      Logger.error(e, stackTrace: st);
      throw FailedToDecryptFileException();
    }
  }

  Future<EncryptedMediaFile> encryptMediaFile(
    MediaFile mediaFile,
  ) async {
    final documentsDir = await getApplicationDocumentsDirectory();

    final encryptedMediaFile = await globalLongLivedIsolate.compute(
      (args) async {
        final mediaFile = args.mediaFile;
        final documentsDir = args.documentsDir;
        final encryptedMediaFile = await encryptMediaFileFn(mediaFile, documentsDir: documentsDir);
        return encryptedMediaFile;
      },
      (mediaFile: mediaFile, documentsDir: documentsDir),
    );

    return encryptedMediaFile;
  }

  Future<File> _downloadFile(
    String url, {
    required String authorPubkey,
    bool withFallback = true,
  }) async {
    try {
      return await fileCacheService.getFile(url);
    } catch (error) {
      if (!withFallback) {
        rethrow;
      }

      final fallbackUrl = await generateMediaUrlFallback(url, authorPubkey: authorPubkey);

      if (fallbackUrl == null) {
        throw FailedToGenerateMediaUrlFallback();
      }

      return _downloadFile(fallbackUrl, authorPubkey: authorPubkey, withFallback: false);
    }
  }
}

@riverpod
MediaEncryptionService mediaEncryptionService(Ref ref) => MediaEncryptionService(
      fileCacheService: ref.read(fileCacheServiceProvider),
      brotliCompressor: ref.read(brotliCompressorProvider),
      generateMediaUrlFallback:
          ref.read(iONConnectMediaUrlFallbackProvider.notifier).generateFallback,
    );

@freezed
class EncryptedMediaFile with _$EncryptedMediaFile {
  const factory EncryptedMediaFile({
    required MediaFile mediaFile,
    required String secretKey,
    required String nonce,
    required String mac,
  }) = _EncryptedMediaFile;
}

@pragma('vm:entry-point')
Future<EncryptedMediaFile> encryptMediaFileFn(
  MediaFile mediaFile, {
  required Directory documentsDir,
}) async {
  final encryptedFiles = <File>[];

  try {
    final secretKey = await AesGcm.with256bits().newSecretKey();
    final secretKeyBytes = await secretKey.extractBytes();
    final secretKeyString = base64Encode(secretKeyBytes);

    final compressedMediaFileBytes = await File(mediaFile.path).readAsBytes();

    final secretBox = await AesGcm.with256bits().encrypt(
      compressedMediaFileBytes,
      secretKey: secretKey,
    );

    final nonceBytes = secretBox.nonce;
    final nonceString = base64Encode(nonceBytes);
    final macString = base64Encode(secretBox.mac.bytes);

    final compressedEncryptedFile =
        File('${documentsDir.path}/${compressedMediaFileBytes.hashCode}.enc');

    await compressedEncryptedFile.writeAsBytes(secretBox.cipherText);

    encryptedFiles.add(compressedEncryptedFile);

    final compressedEncryptedMediaFile = MediaFile(
      path: compressedEncryptedFile.path,
      width: mediaFile.width,
      height: mediaFile.height,
      mimeType: MimeType.generic.value,
      originalMimeType: mediaFile.originalMimeType,
      duration: mediaFile.duration,
    );

    return EncryptedMediaFile(
      mediaFile: compressedEncryptedMediaFile,
      secretKey: secretKeyString,
      nonce: nonceString,
      mac: macString,
    );
  } catch (e) {
    for (final file in encryptedFiles) {
      await file.delete();
    }
    rethrow;
  }
}

@pragma('vm:entry-point')
Future<Uint8List> decryptMediaFileFn(({MediaAttachment attachment, File file}) args) async {
  final file = args.file;
  final attachment = args.attachment;

  final fileBytes = await file.readAsBytes();

  final mac = base64Decode(attachment.encryptionMac!);
  final nonce = base64Decode(attachment.encryptionNonce!);
  final secretKey = base64Decode(attachment.encryptionKey!);

  final secretBox = SecretBox(
    fileBytes,
    nonce: nonce,
    mac: Mac(mac),
  );

  final decryptedFileBytesList = await AesGcm.with256bits().decrypt(
    secretBox,
    secretKey: SecretKey(secretKey),
  );

  final decryptedFileBytes = Uint8List.fromList(decryptedFileBytesList);

  return decryptedFileBytes;
}
