// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/services/file_cache/ion_cache_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_file_cache_manager.r.g.dart';

@Riverpod(keepAlive: true)
CacheManager ionFileCacheManager(Ref ref) => IONCacheManager.instance;

@Riverpod(keepAlive: true)
FileCacheService ionConnectFileCacheService(Ref ref) => FileCacheService(
      ref.watch(ionFileCacheManagerProvider),
      cacheKeyBuilder: (url) => Uri.tryParse(url)?.path ?? url,
    );

class FileCacheService {
  FileCacheService(
    this._cacheManager, {
    String Function(String url)? cacheKeyBuilder,
  }) : _cacheKeyBuilder = cacheKeyBuilder ?? ((url) => url);

  final CacheManager _cacheManager;

  final String Function(String url) _cacheKeyBuilder;

  Future<File> getFile(String url) async {
    return _cacheManager.getSingleFile(url, key: _cacheKeyBuilder(url));
  }

  Future<FileInfo?> getFileFromCache(String url) async {
    return _cacheManager.getFileFromCache(_cacheKeyBuilder(url));
  }

  Future<File> putFile({
    required String url,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    return _cacheManager.putFile(
      url,
      key: _cacheKeyBuilder(url),
      bytes,
      fileExtension: fileExtension,
    );
  }

  Future<void> removeFile(String url) async {
    await _cacheManager.removeFile(_cacheKeyBuilder(url));
  }
}
