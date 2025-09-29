// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:es_compression/brotli.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/model/mime_type.dart';
import 'package:ion/app/features/core/services/global_long_lived_isolate.dart';
import 'package:ion/app/services/compressors/compressor.r.dart';
import 'package:ion/app/services/compressors/output_path_generator.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'brotli_compressor.r.g.dart';

final brotliCodec = BrotliCodec();

class BrotliCompressionSettings {
  const BrotliCompressionSettings({
    this.quality = 11,
  });

  final int quality;
}

class BrotliCompressor implements Compressor<BrotliCompressionSettings> {
  ///
  /// Compresses a file using the Brotli algorithm.
  ///
  @override
  Future<MediaFile> compress(MediaFile file, {BrotliCompressionSettings? settings}) async {
    try {
      final outputFilePath = await generateOutputPath(extension: 'br');
      return await globalLongLivedIsolate.compute(
        (args) async {
          final mediaFile = await compressBrotliFn(args);
          return mediaFile;
        },
        (
          path: file.path,
          outputFilePath: outputFilePath,
          originalMimeType: file.originalMimeType,
          name: file.name,
        ),
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
      return await globalLongLivedIsolate.compute(
        (arg) async {
          final decompressedData = await decompressBrotliFn(arg);
          return decompressedData;
        },
        (
          compressedData: compressedData,
          outputFilePath: outputFilePath,
          outputExtension: outputExtension,
        ),
      );
    } catch (error, stackTrace) {
      Logger.log('Error during Brotli decompression!', error: error, stackTrace: stackTrace);
      throw DecompressBrotliException();
    }
  }
}

@Riverpod(keepAlive: true)
BrotliCompressor brotliCompressor(Ref ref) => BrotliCompressor();

@pragma('vm:entry-point')
Future<MediaFile> compressBrotliFn(
  ({String? name, String? originalMimeType, String outputFilePath, String path}) args,
) async {
  final inputData = await File(args.path).readAsBytes();
  final compressedData = brotliCodec.encode(inputData);
  final mediaFile = await saveBytesIntoFile(
    mimeType: MimeType.brotli,
    bytes: compressedData,
    extension: 'br',
    outputFilePath: args.outputFilePath,
    originalMimeType: args.originalMimeType,
    name: args.name,
  );

  return mediaFile;
}

@pragma('vm:entry-point')
Future<File> decompressBrotliFn(
  ({List<int> compressedData, String outputFilePath, String outputExtension}) args,
) async {
  final decompressedData = brotliCodec.decode(args.compressedData);
  final outputFile = await saveBytesIntoFile(
    mimeType: MimeType.brotli,
    bytes: decompressedData,
    extension: args.outputExtension,
    outputFilePath: args.outputFilePath,
  );
  return File(outputFile.path);
}
