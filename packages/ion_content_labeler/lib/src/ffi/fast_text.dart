// SPDX-License-Identifier: ice License 1.0

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:ion_content_labeler/src/exceptions.dart';

class FastText {
  factory FastText() {
    final lib = _loadLibrary();

    final createInstance = lib.lookupFunction<Uint64 Function(), int Function()>('create_instance');

    final loadModel = lib.lookupFunction<Void Function(Uint64 handle, Pointer<Utf8> filename),
        void Function(int handle, Pointer<Utf8> filename)>('load_model');

    final predict = lib.lookupFunction<
        Void Function(
          Uint64 handle,
          Pointer<Utf8> input,
          Int32 k,
          Pointer<Utf8> out,
          Uint64 outSize,
        ),
        void Function(
          int handle,
          Pointer<Utf8> input,
          int k,
          Pointer<Utf8> out,
          int outSize,
        )>('predict');

    final destroyInstance =
        lib.lookupFunction<Void Function(Uint64 handle), void Function(int handle)>(
      'destroy_instance',
    );

    final handle = createInstance();
    if (handle == 0) {
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

  final void Function(int handle, Pointer<Utf8> filename) _loadModel;
  final void Function(int handle, Pointer<Utf8> input, int k, Pointer<Utf8> out, int outSize)
      _predict;
  final void Function(int handle) _destroyInstance;

  void loadModel(String modelPath) {
    final modelPathPtr = modelPath.toNativeUtf8();
    try {
      _loadModel(_handle, modelPathPtr);
    } catch (error) {
      throw LoadFfiModelException(error);
    } finally {
      calloc.free(modelPathPtr);
    }
  }

  String predict(String text, {int k = 3}) {
    final textPtr = text.toNativeUtf8();
    final outPtr = calloc.allocate<Utf8>(512);

    try {
      _predict(_handle, textPtr, k, outPtr, 512);
      return outPtr.toDartString();
    } catch (error) {
      throw FastTextPredictionException(error);
    } finally {
      calloc
        ..free(textPtr)
        ..free(outPtr);
    }
  }

  void dispose() {
    try {
      _destroyInstance(_handle);
    } catch (error) {
      throw FastTextDisposeException(error);
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
