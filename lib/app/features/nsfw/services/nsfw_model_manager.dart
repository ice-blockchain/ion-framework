// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

// Manages the NSFW TensorFlow Lite model file.
// Handles copying the model from assets to file system for isolate access.
class NsfwModelManager {
  static const _assetPath = 'assets/ml/nsfw_int8.tflite';
  static const _modelFileName = 'nsfw_int8.tflite';
  static String? _cachedModelPath;

  static final _lock = Lock();

  static Future<String> getModelPath() {
    return _lock.synchronized(_loadModel);
  }

  static Future<String> _loadModel() async {
    try {
      if (_cachedModelPath != null) {
        return _cachedModelPath!;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_modelFileName';
      final file = File(path);

      if (file.existsSync()) {
        _cachedModelPath = path;
        return path;
      }

      final bytes = await rootBundle.load(_assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List());

      _cachedModelPath = path;

      return path;
    } catch (e, st) {
      Logger.error(e, message: 'Failed to load NSFW model', stackTrace: st);
      rethrow;
    }
  }
}
