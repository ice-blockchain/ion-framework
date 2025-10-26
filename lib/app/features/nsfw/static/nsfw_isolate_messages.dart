// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:ion/app/features/nsfw/nsfw_detector.dart';

/// Messages sent between main isolate and worker isolates.
/// These classes define the communication way for NSFW detection in isolates.

class NsfwInitMessage {
  const NsfwInitMessage({
    required this.modelPath,
    required this.blockThreshold,
  });

  final String modelPath;
  final double blockThreshold;
}

class NsfwCheckRequest {
  const NsfwCheckRequest({
    required this.id,
    required this.imageBytes,
  });

  final String id;
  final Uint8List imageBytes;
}

class NsfwCheckResponse {
  const NsfwCheckResponse({
    required this.id,
    required this.result,
    this.error,
  });

  final String id;
  final NsfwResult? result;
  final String? error;

  bool get hasError => error != null;

  bool get isSuccess => result != null && error == null;
}

/// Message to shutdown a worker isolate.
class NsfwShutdownMessage {
  const NsfwShutdownMessage();
}
