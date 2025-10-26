// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:isolate';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';
import 'package:ion/app/features/nsfw/static/nsfw_isolate_messages.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// This worker receives image bytes, runs ML inference, and sends back results.
/// Each worker maintains its own TensorFlow Lite interpreter instance.
class NsfwIsolateWorker {
  static Future<void> run(SendPort mainSendPort) async {
    final workerReceivePort = ReceivePort();

    mainSendPort.send(workerReceivePort.sendPort);

    NsfwDetector? detector;

    try {
      // Listen for messages from main isolate
      await for (final message in workerReceivePort) {
        // Handle initialization
        if (message is NsfwInitMessage) {
          try {
            detector = await _initializeDetector(
              modelPath: message.modelPath,
              blockThreshold: message.blockThreshold,
            );
            mainSendPort.send('initialized');
          } catch (e) {
            mainSendPort.send('error: $e');
          }
          continue;
        }

        // Handle shutdown
        if (message is NsfwShutdownMessage) {
          detector?.dispose();
          workerReceivePort.close();
          break;
        }

        // Handle NSFW check request
        if (message is NsfwCheckRequest) {
          if (detector == null) {
            mainSendPort.send(
              NsfwCheckResponse(
                id: message.id,
                result: null,
                error: 'Detector not initialized',
              ),
            );
            continue;
          }

          try {
            final result = await detector.classifyBytes(message.imageBytes);
            mainSendPort.send(
              NsfwCheckResponse(
                id: message.id,
                result: result,
              ),
            );
          } catch (e, st) {
            mainSendPort.send(
              NsfwCheckResponse(
                id: message.id,
                result: null,
                error: 'Classification failed: $e\n$st',
              ),
            );
          }
          continue;
        }
      }
    } catch (e) {
      // Fatal error in worker
      mainSendPort.send('fatal: $e');
    } finally {
      detector?.dispose();
    }
  }

  /// Creates and initializes an NSFW detector in this isolate.
  static Future<NsfwDetector> _initializeDetector({
    required String modelPath,
    required double blockThreshold,
  }) async {
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
}
