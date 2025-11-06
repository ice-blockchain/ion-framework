// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ion/app/components/text_editor/components/custom_blocks/text_editor_single_image_block/text_editor_single_image_block.dart';
import 'package:ion/app/components/text_editor/components/gallery_permission_button.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';

abstract class ToolbarMediaButtonDelegate {
  void onMediaSelected(List<MediaFile>? mediaFiles) {
    if (mediaFiles != null && mediaFiles.isNotEmpty) {
      handleSelectedMedia(mediaFiles);
    }
  }

  ValueNotifier<List<MediaFile>> get attachedMediaNotifier;

  void handleSelectedMedia(List<MediaFile> files);
}

///
/// Handles and stores attached media files using a [attachedMediaNotifier].
///
class AttachedMediaHandler extends ToolbarMediaButtonDelegate {
  AttachedMediaHandler(this.attachedMediaNotifier);

  @override
  final ValueNotifier<List<MediaFile>> attachedMediaNotifier;

  @override
  void handleSelectedMedia(List<MediaFile> files) {
    for (final file in files) {
      if (!attachedMediaNotifier.value.any((e) => e.path == file.path)) {
        attachedMediaNotifier.value.add(file);
      }
    }
  }
}

///
/// Integrates selected media into a text using single image block and QuillController.
///
class QuillControllerHandler extends ToolbarMediaButtonDelegate {
  QuillControllerHandler(this._textEditorController, this.attachedMediaNotifier);

  final QuillController _textEditorController;

  @override
  final ValueNotifier<List<MediaFile>> attachedMediaNotifier;

  @override
  void handleSelectedMedia(List<MediaFile> files) {
    for (final file in files) {
      final index = _textEditorController.selection.baseOffset;
      _textEditorController
        ..replaceText(
          index,
          0,
          TextEditorSingleImageEmbed.image(file.path),
          TextSelection.collapsed(
            offset: _textEditorController.document.length,
          ),
        )
        ..replaceText(
          index + 1,
          0,
          '\n',
          TextSelection.collapsed(offset: _textEditorController.document.length),
        );
    }
  }
}

class ToolbarMediaButton extends StatelessWidget {
  const ToolbarMediaButton({
    required this.delegate,
    this.maxMedia,
    this.enabled = true,
    super.key,
  });

  final ToolbarMediaButtonDelegate delegate;
  final int? maxMedia;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final alreadyPickedMedia = delegate.attachedMediaNotifier.value;

    return GalleryPermissionButton(
      mediaPickerType: MediaPickerType.common,
      onMediaSelected: delegate.onMediaSelected,
      preselectedMedia: alreadyPickedMedia,
      maxSelection: maxMedia,
      enabled: enabled,
    );
  }
}
