// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:typed_data';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// One-shot isolate function which creates detector and checks all media in single isolate
@pragma('vm:entry-point')
Future<Map<String, NsfwResult>> nsfwCheckAllMediaOneShotFn(List<dynamic> params) async {
  final modelPath = params[0] as String;
  final blockThreshold = params[1] as double;
  final pathToBytes = params[2] as Map<String, Uint8List>;
  final results = <String, NsfwResult>{};

  final interpreter = Interpreter.fromFile(
    File(modelPath),
    options: NsfwDetector.defaultInterpreterOptions,
  );

  final detector = await NsfwDetector.create(
    interpreter: interpreter,
    blockThreshold: blockThreshold,
  );

  // Check all items
  for (final entry in pathToBytes.entries) {
    final path = entry.key;
    final bytes = entry.value;
    final result = await detector.classifyBytes(bytes);
    results[path] = result;
  }

  return results;
}
