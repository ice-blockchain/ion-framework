// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:typed_data';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// Global detector instance (persistent in isolate)
NsfwDetector? _detector;

// Initializes NSFW detector with model file
@pragma('vm:entry-point')
Future<void> nsfwInitializeModelFn(List<dynamic> params) async {
  final modelPath = params[0] as String;
  final blockThreshold = params[1] as double;

  _detector = await _createDetector(modelPath, blockThreshold);
}

// Checks single image for NSFW content
@pragma('vm:entry-point')
Future<NsfwResult> nsfwCheckImageFn(List<dynamic> params) async {
  final imageBytes = params[0] as Uint8List;
  final detector = _getDetector();

  return detector.classifyBytes(imageBytes);
}

// Checks multiple images for NSFW content in parallel
@pragma('vm:entry-point')
Future<Map<String, NsfwResult>> nsfwCheckImagesFn(List<dynamic> params) async {
  final pathToBytes = params[0] as Map<String, Uint8List>;
  final results = <String, NsfwResult>{};

  final detector = _getDetector();

  for (final entry in pathToBytes.entries) {
    final path = entry.key;
    final bytes = entry.value;

    final result = await detector.classifyBytes(bytes);
    results[path] = result;

    if (result.decision == NsfwDecision.block) {
      return results;
    }
  }

  return results;
}

// Gets cached detector or throws if not initialized
NsfwDetector _getDetector() {
  if (_detector == null) {
    throw StateError(
      'NSFW detector not initialized. Call nsfwInitializeModelFn first.',
    );
  }
  return _detector!;
}

// Creates and configures NSFW detector
Future<NsfwDetector> _createDetector(
  String modelPath,
  double blockThreshold,
) async {
  // Configure interpreter options
  final options = InterpreterOptions()
    ..threads = 1 // Each isolate uses 1 thread
    ..useNnApiForAndroid = false;

  // Try to enable XNNPACK for better CPU performance
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

  // Create detector
  return NsfwDetector.internal(
    interpreter,
    blockThreshold: blockThreshold,
  );
}
