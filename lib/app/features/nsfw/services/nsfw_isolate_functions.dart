// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:typed_data';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// Creates and configures NSFW detector
Future<NsfwDetector> _createDetector(
  String modelPath,
  double blockThreshold,
) async {
  final options = InterpreterOptions()
    ..threads = 1 // Each isolate uses 1 thread
    ..useNnApiForAndroid = false;

  try {
    options.addDelegate(
      XNNPackDelegate(
        options: XNNPackDelegateOptions(numThreads: 1),
      ),
    );
  } catch (e) {
    // XNNPACK not available, continue without it
  }

  // Load interpreter from file (isolate-safe)
  final interpreter = Interpreter.fromFile(
    File(modelPath),
    options: options,
  );

  return NsfwDetector.internal(
    interpreter,
    blockThreshold: blockThreshold,
  );
}

// One-shot isolate function which creates detector and checks all media in single isolate
@pragma('vm:entry-point')
Future<Map<String, NsfwResult>> nsfwCheckAllMediaOneShotFn(List<dynamic> params) async {
  final modelPath = params[0] as String;
  final blockThreshold = params[1] as double;
  final pathToBytes = params[2] as Map<String, Uint8List>;
  final results = <String, NsfwResult>{};

  // Create detector (one-time per isolate)
  final detector = await _createDetector(modelPath, blockThreshold);

  // Check all items
  for (final entry in pathToBytes.entries) {
    final path = entry.key;
    final bytes = entry.value;
    final result = await detector.classifyBytes(bytes);
    results[path] = result;
  }

  return results;
}
