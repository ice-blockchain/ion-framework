// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget buildTextFieldContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  if (defaultTargetPlatform == TargetPlatform.iOS && SystemContextMenu.isSupported(context)) {
    return SystemContextMenu.editableText(
      editableTextState: editableTextState,
      items: [
        if (editableTextState.copyEnabled) const IOSSystemContextMenuItemCopy(),
        if (editableTextState.cutEnabled) const IOSSystemContextMenuItemCut(),
        if (editableTextState.pasteEnabled) const IOSSystemContextMenuItemPaste(),
        if (editableTextState.selectAllEnabled) const IOSSystemContextMenuItemSelectAll(),
        if (editableTextState.lookUpEnabled) const IOSSystemContextMenuItemLookUp(),
        if (editableTextState.searchWebEnabled) const IOSSystemContextMenuItemSearchWeb(),
      ],
    );
  }

  final buttonItems = editableTextState.contextMenuButtonItems

    // Remove the "Scan Text" (Live Text Input) option
    ..removeWhere((ContextMenuButtonItem buttonItem) {
      return buttonItem.type == ContextMenuButtonType.liveTextInput;
    });

  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}
