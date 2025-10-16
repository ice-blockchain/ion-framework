// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/text_editor/hooks/use_text_delta.dart';
import 'package:ion/app/components/text_editor/text_editor_preview.dart';
import 'package:ion/app/components/text_editor/utils/text_editor_styles.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/profile_mode.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';

class UserAbout extends HookConsumerWidget {
  const UserAbout({
    required this.pubkey,
    this.padding = EdgeInsets.zero,
    this.profileMode = ProfileMode.light,
    super.key,
  });

  final String pubkey;
  final EdgeInsetsGeometry padding;
  final ProfileMode profileMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final about = ref.watch(
      userMetadataProvider(pubkey).select((state) => state.valueOrNull?.data.about),
    );

    if (about == null) {
      return const SizedBox.shrink();
    }

    final content = useTextDelta(about);

    final customStyles = profileMode == ProfileMode.dark
        ? textEditorStyles(
            context,
            color: context.theme.appColors.secondaryBackground,
          )
        : null;

    return Padding(
      padding: padding,
      child: TextEditorPreview(
        scrollable: false,
        content: content,
        customStyles: customStyles,
      ),
    );
  }
}
