// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:ion/app/components/text_editor/utils/delta_bridge.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';

QuillController? usePostQuillController(
  WidgetRef ref, {
  String? content,
  EventReference? modifiedEvent,
}) {
  final modifiedEntity = modifiedEvent != null
      ? ref.watch(ionConnectEntityProvider(eventReference: modifiedEvent)).valueOrNull
      : null;

  return useMemoized(
    () {
      const defaultConfig = QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: false,
        ),
      );
      if (content != null) {
        final document = Document.fromDelta(
          DeltaBridge.normalizeToEmbedFormat(Delta.fromJson(jsonDecode(content) as List<dynamic>)),
        );
        return QuillController(
          document: document,
          selection: TextSelection.collapsed(offset: document.length - 1),
          config: defaultConfig,
        );
      }
      if (modifiedEntity != null) {
        if (modifiedEntity is ModifiablePostEntity) {
          final (:content, :media) =
              ref.watch(parsedMediaWithMentionsProvider(modifiedEntity.data));
          if (content.isNotEmpty) {
            final document = Document.fromDelta(
              DeltaBridge.normalizeToEmbedFormat(content),
            );
            return QuillController(
              document: document,
              selection: TextSelection.collapsed(offset: document.length - 1),
              config: defaultConfig,
            );
          }
        }
        return null;
      }
      return QuillController.basic(config: defaultConfig);
    },
    [content, modifiedEntity],
  );
}
