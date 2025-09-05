// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';
import 'dart:isolate';

import 'package:ion_content_labeler/src/ffi/fast_text.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';

enum TextLabelerModel {
  language(AssetModelFile(name: 'language_identification.176.ftz')),
  category(NetworkModelFile(
    name: 'labeling_v3',
    url:
        'https://github.com/ice-blockchain/ion-app/raw/063772ec0dd75fac8946b2f33fb4ea33d04308aa/assets/labeling_3.ftz',
  ));

  final ModelFile file;

  const TextLabelerModel(this.file);
}

class IONTextLabeler {
  Future<TextLabelerResult> detect(
    String input, {
    required TextLabelerModel model,
    int count = 3,
  }) async {
    final normalizedInput = _normalizeInput(input);

    final modelPath = (await model.file.load()).path;

    final predictionsJson = await Isolate.run(() {
      final lib = FastText();
      try {
        lib.loadModel(modelPath);
        return lib.predict(normalizedInput);
      } finally {
        lib.dispose();
      }
    });

    final labels = (jsonDecode(predictionsJson) as List<dynamic>)
        .map((prediction) => _normalizeLabel(Label.fromMap(prediction)))
        .toList();

    return TextLabelerResult(
      input: normalizedInput,
      labels: labels,
    );
  }

  Label _normalizeLabel(Label label) {
    return label.copyWith(name: label.name.replaceFirst('__label__', ''));
  }

  String _normalizeInput(String input) {
    return input
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), '')
        .toLowerCase()
        .trim();
  }
}
