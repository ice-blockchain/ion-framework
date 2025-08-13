// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:es_compression/brotli.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'brotli_compressor.r.g.dart';

class BrotliCompressionSettings {
  const BrotliCompressionSettings({
    this.quality = 11,
  });

  final int quality;
}

class BrotliCompressor implements Compressor<BrotliCompressionSettings> {
  final _brotliCodec = BrotliCodec();

  ///
  /// Compresses a file using the Brotli algorithm.
  ///
  @override
  Future<MediaFile> compress(MediaFile file, {BrotliCompressionSettings? settings}) async {
    try {
      final outputFilePath = await generateOutputPath(extension: 'br');
      return await compute(
        (arg) async {
          final inputData = await File(arg.path).readAsBytes();
          final compressedData = _brotliCodec.encode(inputData);
          return _saveBytesIntoFile(
            bytes: compressedData,
            extension: 'br',
            outputFilePath: arg.outputFilePath,
          );
        },
        (path: file.path, outputFilePath: outputFilePath),
      );
    } catch (error, stackTrace) {
      Logger.log('Error during Brotli compression!', error: error, stackTrace: stackTrace);
      throw CompressWithBrotliException();
    }
  }

  ///
  /// Decompresses a Brotli-compressed file.
  ///
  Future<File> decompress(List<int> compressedData, {String outputExtension = ''}) async {
    try {
      final outputFilePath = await generateOutputPath(extension: outputExtension);
      return await compute(
        (arg) async {
          final decompressedData = _brotliCodec.decode(arg.compressedData);
          final outputFile = await _saveBytesIntoFile(
            bytes: decompressedData,
            extension: arg.outputExtension,
            outputFilePath: arg.outputFilePath,
          );
          return File(outputFile.path);
        },
        (
          compressedData: compressedData,
          outputFilePath: outputFilePath,
          outputExtension: outputExtension
        ),
      );
    } catch (error, stackTrace) {
      Logger.log('Error during Brotli decompression!', error: error, stackTrace: stackTrace);
      throw DecompressBrotliException();
    }
  }

  Future<MediaFile> _saveBytesIntoFile({
    required List<int> bytes,
    required String extension,
    required String outputFilePath,
  }) async {
    final outputFile = File(outputFilePath);
    await outputFile.writeAsBytes(bytes);

    return MediaFile(
      path: outputFilePath,
      mimeType: MimeType.brotli.value,
      width: 0,
      height: 0,
    );
  }
}

@Riverpod(keepAlive: true)
BrotliCompressor brotliCompressor(Ref ref) => BrotliCompressor();
