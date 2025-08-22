// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/delta.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/feed/providers/parsed_media_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/entity_data_with_media_content.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

class VideoTextPost extends HookConsumerWidget {
  const VideoTextPost({
    required this.entity,
    super.key,
  });

  final IonConnectEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postData = switch (entity) {
      final ModifiablePostEntity post => post.data,
      final PostEntity post => post.data,
      _ => null,
    };

    if (postData is! EntityDataWithMediaContent) {
      return const SizedBox.shrink();
    }

    final (:content, :media) = ref.watch(cachedParsedMediaProvider(postData));
    final isTextExpanded = useState(false);
    final style = context.theme.appTextThemes.body2.copyWith(
      color: context.theme.appColors.secondaryBackground,
    );

    final isOneLine = useMemoized(
      () {
        return _isTextOneLine(
          text: Document.fromDelta(content).toPlainText(),
          style: style,
          maxWidth: MediaQuery.sizeOf(context).width,
        );
      },
      [
        content,
        MediaQuery.sizeOf(context).width,
      ],
    );

    if (content.isBlank) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 10.0.s),
        GestureDetector(
          onTap: isOneLine ? null : () => isTextExpanded.value = !isTextExpanded.value,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              );
            },
            child: TextEditorPreview(
              content: content,
              maxHeight: isTextExpanded.value
                  ? null
                  : 20.0.s, //TODO:find a better way to collapse/expand quill
              customStyles:
                  textEditorStyles(context, color: context.theme.appColors.secondaryBackground),
            ),
          ),
        ),
      ],
    );
  }

  bool _isTextOneLine({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return !textPainter.didExceedMaxLines;
  }
}
