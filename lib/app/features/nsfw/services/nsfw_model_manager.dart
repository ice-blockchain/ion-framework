// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:path_provider/path_provider.dart';

// Manages the NSFW TensorFlow Lite model file.
// Handles copying the model from assets to file system for isolate access.
class NsfwModelManager {
  static const _assetPath = 'assets/ml/nsfw_int8.tflite';
  static const _modelFileName = 'nsfw_int8.tflite';
  static String? _cachedModelPath;
  static Future<String>? _loadingFuture;

  static Future<String> getModelPath() {
    if (_cachedModelPath != null) {
      return Future.value(_cachedModelPath);
    }

    _loadingFuture ??= _loadModel();
    return _loadingFuture!;
  }

  static Future<String> _loadModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_modelFileName';
      final file = File(path);

      if (file.existsSync()) {
        _cachedModelPath = path;
        _loadingFuture = null;
        return path;
      }

      final bytes = await rootBundle.load(_assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List());

      _cachedModelPath = path;
      _loadingFuture = null;

      return path;
    } catch (e, st) {
      // Reset loading future on error to allow retry
      _loadingFuture = null;
      Logger.error(e, message: 'Failed to load NSFW model', stackTrace: st);
      rethrow;
    }
  }
}
