// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/components/text_editor/utils/extract_image_ids.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/color.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'draft_article_provider.m.freezed.dart';

part 'draft_article_provider.m.g.dart';

@freezed
class DraftArticleState with _$DraftArticleState {
  const factory DraftArticleState({
    required Delta content,
    @Default([]) List<String> imageIds,
    MediaFile? image,
    @Default('') String title,
    String? imageColor,
    @Default({}) Map<String, String> codeBlocks,
    String? imageUrl,
    @Default({}) Map<String, MediaAttachment> mediaAttachments,
  }) = _DraftArticleState;
}

@Riverpod(keepAlive: true)
class DraftArticle extends _$DraftArticle {
  @override
  DraftArticleState build() {
    return DraftArticleState(content: Delta());
  }

  Future<void> updateArticleDetails(
    QuillController textEditorController,
    MediaFile? image,
    String title,
    String? imageUrl,
    String? imageUrlColor,
    Map<String, MediaAttachment>? mediaAttachments,
  ) async {
    final delta = textEditorController.document.toDelta();
    final imageIds = extractImageIds(textEditorController.document.toDelta());

    final colorHex = imageUrl != null ? imageUrlColor : await _extractDominantColorFromImage(image);

    state = state.copyWith(
      content: delta,
      imageIds: imageIds,
      image: image,
      imageUrl: imageUrl,
      title: title.trim(),
      imageColor: colorHex,
      mediaAttachments: mediaAttachments ?? state.mediaAttachments,
    );
  }

  void updateCodeBlock(String id, String content) {
    final updatedCodeBlocks = Map<String, String>.from(state.codeBlocks);
    updatedCodeBlocks[id] = content;

    state = state.copyWith(
      codeBlocks: updatedCodeBlocks,
    );
  }

  void removeCodeBlock(String id) {
    final updatedCodeBlocks = Map<String, String>.from(state.codeBlocks)..remove(id);
    state = state.copyWith(codeBlocks: updatedCodeBlocks);
  }

  String? getCodeBlockContent(String id) {
    return state.codeBlocks[id];
  }

  Map<String, String> getAllCodeBlocks() {
    return state.codeBlocks;
  }

  Future<String?> _extractDominantColorFromImage(MediaFile? image) async {
    if (image == null) return null;

    final imageProvider = FileImage(File(image.path));
    final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
    final dominantColor = paletteGenerator.dominantColor?.color;

    return dominantColor != null ? toHexColor(dominantColor) : null;
  }

  void clear() {
    state = DraftArticleState(content: Delta());
  }
}
