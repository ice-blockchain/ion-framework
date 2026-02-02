// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

void removeBlock(
  QuillController controller,
  Embed node,
) {
  final blockIndex = node.documentOffset;
  var blockLength = node.length;
  final plainText = controller.document.toPlainText();
  final nextIndex = blockIndex + blockLength;
  if (nextIndex < plainText.length && plainText[nextIndex] == '\n') {
    blockLength += 1;
  }

  final deleteDelta = Delta()
    ..retain(blockIndex)
    ..delete(blockLength);

  controller.compose(
    deleteDelta,
    TextSelection.collapsed(offset: blockIndex),
    ChangeSource.local,
  );
}
