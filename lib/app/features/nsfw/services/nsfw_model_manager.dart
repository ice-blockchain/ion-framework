// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Manages the NSFW TensorFlow Lite model file.
/// Handles copying the model from assets to file system for isolate access.
class NsfwModelManager {
  NsfwModelManager._();

  static const String _assetPath = 'assets/ml/nsfw_int8.tflite';
  static const String _modelFileName = 'nsfw_int8.tflite';

  static String? _cachedModelPath;

  /// Gets the file path to the NSFW model.
  /// On first call, copies the model from assets to app documents directory.
  /// Next calls just return the cached path.
  /// This is required, as isolates cannot access rootBundle.

  static Future<String> getModelPath() async {
    if (_cachedModelPath != null) {
      final file = File(_cachedModelPath!);
      if (file.existsSync()) {
        return _cachedModelPath!;
      }
    }

    // Get app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final modelPath = '${directory.path}/$_modelFileName';
    final file = File(modelPath);
    if (file.existsSync()) {
      _cachedModelPath = modelPath;
      return modelPath;
    }

    // Copy model from assets to file system
    try {
      final bytes = await rootBundle.load(_assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List());

      _cachedModelPath = modelPath;
      return modelPath;
    } catch (e, st) {
      Logger.error(
        e,
        message: 'Failed to copy NSFW model from assets',
        stackTrace: st,
      );
      rethrow;
    }
  }

  static Future<void> clearCache() async {
    if (_cachedModelPath == null) return;

    try {
      final file = File(_cachedModelPath!);
      if (file.existsSync()) {
        await file.delete();
      }
      _cachedModelPath = null;
    } catch (e, st) {
      Logger.error(
        e,
        message: 'Failed to clear NSFW model cache',
        stackTrace: st,
      );
    }
  }

  static Future<bool> isModelCached() async {
    if (_cachedModelPath == null) return false;
    final file = File(_cachedModelPath!);
    return file.existsSync();
  }
}
