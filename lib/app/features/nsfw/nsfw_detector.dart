// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:ion/app/services/logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum NsfwDecision { allow, block }

@immutable
class NsfwResult {
  const NsfwResult({
    required this.nsfw,
    required this.sfw,
    required this.decision,
  });

  final double nsfw; // 0..1
  final double sfw; // 0..1 or 1-nsfw
  final NsfwDecision decision;
}

class NsfwDetector {
  NsfwDetector._(
    this._interpreter, {
    double blockThreshold = 0.60,
  }) : _blockThreshold = blockThreshold;

  final Interpreter _interpreter;
  final double _blockThreshold;

  static const _size = 224;

  static Future<NsfwDetector> create({
    double blockThreshold = 0.50,
  }) async {
    final options = InterpreterOptions()
      ..threads = Platform.numberOfProcessors
      ..useNnApiForAndroid = false;
    // Enable XNNPACK for better CPU performance when available
    try {
      options.addDelegate(
        XNNPackDelegate(options: XNNPackDelegateOptions(numThreads: Platform.numberOfProcessors)),
      );
    } catch (e) {
      Logger.warning("XNNPACK isn't available on the platform");
      // Safe fallback: continue without the delegate
    }
    final interpreter = await Interpreter.fromAsset('assets/ml/nsfw_int8.tflite', options: options);
    return NsfwDetector._(interpreter, blockThreshold: blockThreshold);
  }

  void dispose() => _interpreter.close();

  /// Classifies image bytes and returns NSFW score, SFW score, and decision.
  Future<NsfwResult> classifyBytes(Uint8List bytes) async {
    final input = _preprocess(bytes); // Flattened NHWC RGB, length = 224*224*3

    // The model outputs [1,2] (sfw, nsfw)
    final output = List.generate(1, (_) => List<double>.filled(2, 0));

    _interpreter.run(input, output);

    final sfw = output[0][0];
    final nsfw = output[0][1];

    final decision = _decide(nsfw);
    return NsfwResult(nsfw: nsfw, sfw: sfw, decision: decision);
  }

  /// Threshold strategy for turning a probability into a decision.
  NsfwDecision _decide(double nsfw) {
    if (nsfw >= _blockThreshold) return NsfwDecision.block;
    return NsfwDecision.allow;
  }

  // Pipeline: resize(short=256) -> center-crop 224 -> RGB uint8 -> NHWC
  Uint8List _preprocess(Uint8List bytes) {
    var im = img.decodeImage(bytes);
    if (im == null) {
      throw StateError('decodeImage failed');
    }
    im = img.bakeOrientation(im); // apply EXIF orientation

    final w = im.width;
    final h = im.height;
    final shortSide = w < h ? w : h;
    final scale = 256 / shortSide;
    final newW = (w * scale).round();
    final newH = (h * scale).round();

    final resized = img.copyResize(
      im,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    final x0 = ((newW - _size) / 2).floor();
    final y0 = ((newH - _size) / 2).floor();
    final cropped = img.copyCrop(
      resized,
      x: x0.clamp(0, newW - _size),
      y: y0.clamp(0, newH - _size),
      width: _size,
      height: _size,
    );

    final rgb = img.copyResizeCropSquare(cropped, size: _size); // ensure 224x224
    final out = rgb.getBytes(order: img.ChannelOrder.rgb);
    // Model expects [1,224,224,3] uint8 RGB (NHWC).
    return out;
  }
}
