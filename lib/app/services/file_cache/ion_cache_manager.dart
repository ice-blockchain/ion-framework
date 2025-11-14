// SPDX-License-Identifier: ice License 1.0

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:ion/app/utils/url.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class IONCacheManager {
  static const key = 'ionCacheKey';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      maxNrOfCacheObjects: 1000,
      stalePeriod: const Duration(days: 60),
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IONFileSystem(key),
      fileService: HttpFileService(),
    ),
  );

  static final ionNetworkImage = CacheManager(
    Config(
      'ionNetworkImageCache',
      maxNrOfCacheObjects: 1000,
      stalePeriod: const Duration(days: 60),
    ),
  );

  static final ionConnectNetworkImage = CacheManager(
    Config(
      'ionConnectNetworkImageCacheKey',
      maxNrOfCacheObjects: 1000,
      stalePeriod: const Duration(days: 1),
    ),
  );

  static final networkVideos = CacheManager(
    Config(
      'networkVideosCacheKey',
      maxNrOfCacheObjects: 100,
      stalePeriod: const Duration(days: 1),
    ),
  );

  static final preCachePictures = CacheManager(
    Config(
      'preCachePicturesCacheKey',
      maxNrOfCacheObjects: 1000,
      stalePeriod: const Duration(days: 60),
    ),
  );

  // Using the media path last fragment as a cache key because it’s a unique identifier for media
  // that may be hosted on different relays or CDN.
  static String getCacheKeyFromIonUrl(String url) {
    if (!isIonMediaUrl(url)) {
      return url;
    }

    return Uri.tryParse(url)?.pathSegments.lastOrNull ?? url;
  }
}

class IONFileSystem implements FileSystem {
  IONFileSystem(this._cacheKey) : _fileDir = createDirectory(_cacheKey);

  final Future<Directory> _fileDir;
  final String _cacheKey;

  static Future<Directory> createDirectory(String key) async {
    final baseDir = await getApplicationSupportDirectory();
    final path = p.join(baseDir.path, key);

    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<File> createFile(String name) async {
    final directory = await _fileDir;
    if (!(await directory.exists())) {
      await createDirectory(_cacheKey);
    }
    return directory.childFile(name);
  }
}
