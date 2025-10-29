// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/cloud_storage/cloud_storage_service.r.dart';
import 'package:path_provider/path_provider.dart';

final class ICloudStorageService extends CloudStorageService {
  ICloudStorageService({required this.containerId});

  final String containerId;

  @override
  Future<void> signOut() async {
    // no op for iCloud
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await ICloudStorage.gather(
        containerId: containerId,
      );
      return true;
    } catch (e) {
      if (e is PlatformException && e.code == PlatformExceptionCode.iCloudConnectionOrPermission) {
        return false;
      }
      throw CloudFilesGatherFailedException(e);
    }
  }

  @override
  Future<List<String>> listFilesPaths({String? directory}) async {
    try {
      final fileList = await ICloudStorage.gather(
        containerId: containerId,
      );
      return fileList.map((file) => file.relativePath).toList();
    } catch (e) {
      if (e is PlatformException && e.code == PlatformExceptionCode.iCloudConnectionOrPermission) {
        throw CloudPermissionFailedException();
      }
      throw CloudFilesGatherFailedException(e);
    }
  }

  @override
  Future<void> uploadFile(String filePath, String fileContent) async {
    try {
      final completer = Completer<void>();
      StreamSubscription<double>? uploadProgressSubscription;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = filePath.split('/').last;
      final tempFilePath = '${directory.path}/$fileName';
      final file = File(tempFilePath);
      await file.writeAsString(fileContent);

      await ICloudStorage.upload(
        containerId: containerId,
        filePath: tempFilePath,
        destinationRelativePath: filePath,
        onProgress: (stream) {
          uploadProgressSubscription?.cancel();
          uploadProgressSubscription = stream.listen(
            (_) {},
            onError: (dynamic e) {
              completer.completeError(_mapUploadException(e));
            },
            cancelOnError: true,
          );
        },
      );
      uploadProgressSubscription?.onDone(() async {
        unawaited(file.delete());
        completer.complete();
      });

      return completer.future;
    } catch (e) {
      throw _mapUploadException(e);
    }
  }

  @override
  Future<String?> downloadFile(String filePath) async {
    try {
      final completer = Completer<String?>();
      StreamSubscription<double>? downloadProgressSubscription;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = filePath.split('/').last;
      final destinationPath = '${directory.path}/$fileName';
      await ICloudStorage.download(
        containerId: containerId,
        relativePath: filePath,
        destinationFilePath: destinationPath,
        onProgress: (stream) {
          downloadProgressSubscription?.cancel();
          downloadProgressSubscription = stream.listen(
            (_) {},
            onError: (dynamic e) {
              completer.completeError(_mapDownloadException(e));
            },
            cancelOnError: true,
          );
        },
      );
      downloadProgressSubscription?.onDone(() async {
        final savedFile = File(destinationPath);
        final contents = await savedFile.readAsString();
        unawaited(savedFile.delete());
        completer.complete(contents);
      });

      return completer.future;
    } catch (e) {
      throw _mapDownloadException(e);
    }
  }

  @override
  Future<void> deleteFile(String filePath) async {
    try {
      await ICloudStorage.delete(
        containerId: containerId,
        relativePath: filePath,
      );
    } catch (e) {
      throw CloudFileDeleteFailedException(e);
    }
  }

  Exception _mapUploadException(dynamic e) {
    if (e is PlatformException && e.code == PlatformExceptionCode.iCloudConnectionOrPermission) {
      return CloudPermissionFailedException();
    }
    return CloudFileUploadFailedException(e);
  }

  Exception _mapDownloadException(dynamic e) {
    if (e is PlatformException && e.code == PlatformExceptionCode.iCloudConnectionOrPermission) {
      return CloudPermissionFailedException();
    }
    return CloudFileDownloadFailedException(e);
  }
}
