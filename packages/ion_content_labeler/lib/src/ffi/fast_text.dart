// SPDX-License-Identifier: ice License 1.0

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ion_content_labeler/src/exceptions.dart';

class FastText {
  factory FastText() {
    final lib = _loadLibrary();

    final createInstance = lib.lookupFunction<Int32 Function(), int Function()>('create_instance');

    final loadModel = lib.lookupFunction<Int32 Function(Int32 handle, Pointer<Utf8> filename),
        int Function(int handle, Pointer<Utf8> filename)>('load_model');

    final predict = lib.lookupFunction<
        Int32 Function(
          Int32 handle,
          Pointer<Utf8> input,
          Int32 k,
          Pointer<Utf8> out,
          Size outSize,
        ),
        int Function(
          int handle,
          Pointer<Utf8> input,
          int k,
          Pointer<Utf8> out,
          int outSize,
        )>('predict');

    final destroyInstance =
        lib.lookupFunction<Int32 Function(Int32 handle), int Function(int handle)>(
      'destroy_instance',
    );

    final handle = createInstance();
    if (handle < 0) {
      throw const CreateFastTextInstanceException();
    }

    return FastText._(
      handle,
      loadModel,
      predict,
      destroyInstance,
    );
  }

  FastText._(this._handle, this._loadModel, this._predict, this._destroyInstance);

  final int _handle;

  final int Function(int handle, Pointer<Utf8> filename) _loadModel;
  final int Function(int handle, Pointer<Utf8> input, int k, Pointer<Utf8> out, int outSize)
      _predict;
  final int Function(int handle) _destroyInstance;

  void loadModel(String modelPath) {
    final modelPathPtr = modelPath.toNativeUtf8();

    try {
      final resultCode = _loadModel(_handle, modelPathPtr);
      if (resultCode != 0) {
        throw LoadFfiModelException('error code $resultCode');
      }
    } finally {
      calloc.free(modelPathPtr);
    }
  }

  String predict(String text, {int k = 3}) {
    final textPtr = text.toNativeUtf8();
    final outPtr = calloc.allocate<Utf8>(512);

    try {
      final resultCode = _predict(_handle, textPtr, k, outPtr, 512);
      if (resultCode != 0) {
        throw FastTextPredictionException('error code $resultCode');
      }
      return outPtr.toDartString();
    } finally {
      calloc
        ..free(textPtr)
        ..free(outPtr);
    }
  }

  void dispose() {
    final resultCode = _destroyInstance(_handle);
    if (resultCode != 0) {
      throw FastTextDisposeException('error code $resultCode');
    }
  }

  static DynamicLibrary _loadLibrary() {
    try {
      if (Platform.isIOS) {
        return DynamicLibrary.open('fasttext_predict.framework/fasttext_predict');
      } else if (Platform.isAndroid) {
        return DynamicLibrary.open('libfasttext_predict.so');
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
    } catch (error) {
      throw LoadFfiLibraryException(error);
    }
  }
}
