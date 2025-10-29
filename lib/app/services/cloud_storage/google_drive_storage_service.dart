// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io' as io;

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/services/cloud_storage/cloud_storage_service.r.dart';
import 'package:path_provider/path_provider.dart';

final class GoogleDriveStorageService extends CloudStorageService {
  static const appDataFolder = 'appDataFolder';

  @override
  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn.standard(scopes: [DriveApi.driveAppdataScope]);
      await googleSignIn.signOut();
    } catch (_) {}
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Will throw if google drive not available
      await _getAuthenticatedDriveApi();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> listFilesPaths({String? directory}) async {
    try {
      final drive = await _getAuthenticatedDriveApi();

      if (directory == null || directory.isEmpty) {
        final files = await drive.files.list(
          q: '"$appDataFolder" in parents',
          spaces: appDataFolder,
        );
        final paths = files.files?.map((file) => file.name).nonNulls.toList();
        return paths ?? [];
      }

      final directoryId = await _getDirectoryId(drive, directory);
      if (directoryId == null) {
        return [];
      }
      final filesInFolder = await drive.files.list(
        q: '"$directoryId" in parents',
        spaces: appDataFolder,
      );
      final paths = filesInFolder.files?.map((file) => file.name).nonNulls.toList();
      return paths ?? [];
    } catch (e) {
      throw CloudFilesGatherFailedException(e);
    }
  }

  @override
  Future<void> uploadFile(String filePath, String fileContent) async {
    try {
      final drive = await _getAuthenticatedDriveApi();

      final pathSegments = filePath.split('/');
      final fileName = pathSegments.last;
      final directory = await getApplicationDocumentsDirectory();
      final tempFile = io.File('${directory.path}/$fileName');
      await tempFile.writeAsString(fileContent);
      final content = Media(tempFile.openRead(), tempFile.lengthSync());

      final directories = pathSegments.sublist(0, pathSegments.length - 1);
      final folderId = await _prepareFolders(drive, directories);

      final googleFile = File()..name = fileName;

      final existingFileId = await _getFileId(drive, fileName, parentId: folderId);
      if (existingFileId == null) {
        googleFile.parents = [folderId];
      }
      final uploadedFile = existingFileId != null
          ? await drive.files.update(googleFile, existingFileId, uploadMedia: content)
          : await drive.files.create(googleFile, uploadMedia: content);
      if (uploadedFile.id == null) {
        throw CloudUploadedFileNotFoundException();
      }
    } catch (e) {
      throw CloudFileUploadFailedException(e);
    }
  }

  @override
  Future<String?> downloadFile(String filePath) async {
    try {
      final drive = await _getAuthenticatedDriveApi();

      final pathSegments = filePath.split('/');
      final fileName = pathSegments.last;

      final directory = pathSegments.sublist(0, pathSegments.length - 1).join('/');
      final directoryId = await _getDirectoryId(drive, directory);
      final fileId = await _getFileId(drive, fileName, parentId: directoryId);
      if (fileId == null) {
        return null;
      }

      final file =
          await drive.files.get(fileId, downloadOptions: DownloadOptions.fullMedia) as Media?;
      if (file == null) {
        return null;
      }

      final documentsDirectory = await getApplicationDocumentsDirectory();
      final tempFile = io.File('${documentsDirectory.path}/$fileName');
      final first = await file.stream.first;
      await tempFile.writeAsBytes(first);
      final fileContent = await tempFile.readAsString();
      unawaited(tempFile.delete());
      return fileContent;
    } catch (e) {
      throw CloudFileDownloadFailedException(e);
    }
  }

  @override
  Future<void> deleteFile(String filePath) async {
    try {
      final drive = await _getAuthenticatedDriveApi();

      final pathSegments = filePath.split('/');
      final fileName = pathSegments.last;

      final directory = pathSegments.sublist(0, pathSegments.length - 1).join('/');
      final directoryId = await _getDirectoryId(drive, directory);
      final fileId = await _getFileId(drive, fileName, parentId: directoryId);
      if (fileId == null) {
        return;
      }

      await drive.files.delete(fileId);
    } catch (e) {
      throw CloudFileDeleteFailedException(e);
    }
  }

  Future<DriveApi> _getAuthenticatedDriveApi() async {
    final googleSignIn = GoogleSignIn.standard(scopes: [DriveApi.driveAppdataScope]);
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw CloudPermissionFailedException();
    }

    final authClient = await googleSignIn.authenticatedClient();

    if (authClient == null) {
      throw CloudPermissionFailedException();
    }

    return DriveApi(authClient);
  }

  Future<String?> _getFileId(DriveApi api, String fileName, {String? parentId}) async {
    final parentQuery = parentId == null ? '' : " and '$parentId' in parents";
    final found = await api.files.list(
      q: "name = '$fileName'$parentQuery",
      spaces: appDataFolder,
    );
    final files = found.files;
    if (files == null) {
      return null;
    }

    if (files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }

  Future<String?> _getDirectoryId(DriveApi api, String directory) async {
    final pathSegments = directory.split('/');
    if (pathSegments.isEmpty) {
      return null;
    }
    if (pathSegments.length == 1) {
      return _getSingleRootFolderId(api, directory);
    }
    var parentFolderId = appDataFolder;
    for (final subDirectory in pathSegments) {
      final found = await api.files.list(
        q: "name = '$subDirectory' and mimeType = 'application/vnd.google-apps.folder' and '$parentFolderId' in parents",
        spaces: appDataFolder,
      );
      final files = found.files;

      if (files != null && files.isNotEmpty) {
        parentFolderId = files.first.id!;
      } else {
        return null;
      }
    }
    return parentFolderId;
  }

  Future<String?> _getSingleRootFolderId(DriveApi api, String folder) async {
    final found = await api.files.list(
      q: 'mimeType = "application/vnd.google-apps.folder" and name = "$folder" and "$appDataFolder" in parents',
      spaces: appDataFolder,
    );
    return found.files?.firstOrNull?.id;
  }

  Future<String> _prepareFolders(DriveApi api, List<String> subDirectories) async {
    var parentFolderId = appDataFolder;
    for (final subDirectory in subDirectories) {
      final found = await api.files.list(
        q: "name = '$subDirectory' and mimeType = 'application/vnd.google-apps.folder' and '$parentFolderId' in parents",
        spaces: appDataFolder,
      );
      final files = found.files;

      if (files != null && files.isNotEmpty) {
        parentFolderId = files.first.id!;
      } else {
        final folder = File()
          ..name = subDirectory
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = [parentFolderId];
        final createdFolder = await api.files.create(folder);
        parentFolderId = createdFolder.id!;
      }
    }
    return parentFolderId;
  }
}
