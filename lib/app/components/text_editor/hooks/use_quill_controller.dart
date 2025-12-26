// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/utils/delta_bridge.dart';

QuillController useQuillController({String? content}) {
  final quillController = useMemoized(
    () {
      const defaultConfig = QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: false,
        ),
      );
      if (content != null) {
        try {
          final deltaJson = jsonDecode(content) as List<dynamic>;
          final doc = Document.fromDelta(
            DeltaBridge.normalizeToEmbedFormat(Delta.fromJson(deltaJson)),
          );
          return QuillController(
            document: doc,
            selection: TextSelection.collapsed(offset: doc.length - 1),
            config: defaultConfig,
          );
        } on FormatException {
          // Fallback to plain text
          final doc = Document()..insert(0, content);
          return QuillController(
            document: doc,
            selection: TextSelection.collapsed(offset: content.length),
            config: defaultConfig,
          );
        }
      } else {
        return QuillController.basic(config: defaultConfig);
      }
    },
    [content],
  );

  useEffect(() => quillController.dispose, [quillController]);

  return quillController;
}
