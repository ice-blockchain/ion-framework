// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:typed_data';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/static/nsfw_isolate_pool.dart';
import 'package:ion/app/features/nsfw/static/nsfw_model_manager.dart';

class NsfwParallelChecker {
  NsfwParallelChecker._();

  static Future<bool> hasNsfwInImagePaths({
    required List<String> imagePaths,
    required double blockThreshold,
    int? poolSize,
  }) async {
    if (imagePaths.isEmpty) return false;

    NsfwIsolatePool? pool;

    try {
      // Step 1: Ensure model is available in file system
      final modelPath = await NsfwModelManager.getModelPath();

      // Step 2: Read all image bytes in parallel
      final imageBytesListFutures = imagePaths.map((path) async {
        try {
          final file = File(path);
          return await file.readAsBytes();
        } catch (e) {
          return null;
        }
      }).toList();

      final imageBytesListNullable = await Future.wait(imageBytesListFutures);
      final imageBytesList =
          imageBytesListNullable.where((bytes) => bytes != null).map((bytes) => bytes!).toList();

      if (imageBytesList.isEmpty) {
        return false;
      }

      // Step 3: Create isolate pool
      pool = await NsfwIsolatePool.create(
        poolSize: poolSize,
        modelPath: modelPath,
        blockThreshold: blockThreshold,
      );

      // Step 4: Process all images in parallel
      final results = await pool.checkImages(imageBytesList);

      // Step 5: Check if any image is NSFW
      var nsfwCount = 0;
      for (var i = 0; i < results.length; i++) {
        final result = results[i];
        if (result.decision == NsfwDecision.block) {
          nsfwCount++;
        }
      }

      final hasNsfw = nsfwCount > 0;

      return hasNsfw;
    } catch (e) {
      rethrow;
    } finally {
      await pool?.shutdown();
    }
  }

  /// Similar to [hasNsfwInImagePaths] but accepts raw image bytes instead of file paths.
  /// Useful when images are already loaded in memory, for example when processing videos.
  static Future<bool> hasNsfwInImageBytes({
    required List<Uint8List> imageBytesList,
    required double blockThreshold,
    int? poolSize,
  }) async {
    if (imageBytesList.isEmpty) return false;

    NsfwIsolatePool? pool;

    try {
      // Step 1: Ensure model is available
      final modelPath = await NsfwModelManager.getModelPath();

      // Step 2: Create isolate pool
      pool = await NsfwIsolatePool.create(
        poolSize: poolSize,
        modelPath: modelPath,
        blockThreshold: blockThreshold,
      );

      // Step 3: Process all images in parallel
      final results = await pool.checkImages(imageBytesList);

      // Step 4: Check if any image is NSFW
      final hasNsfw = results.any((r) => r.decision == NsfwDecision.block);

      return hasNsfw;
    } catch (e) {
      rethrow;
    } finally {
      await pool?.shutdown();
    }
  }
}
