// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/generated/assets.gen.dart';

class EditSubmitButton extends ConsumerWidget {
  const EditSubmitButton({
    required this.hasChanges,
    required this.draftRef,
    required this.formKey,
    super.key,
  });

  final bool hasChanges;

  final ObjectRef<UserMetadata> draftRef;

  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(updateUserMetadataNotifierProvider.select((state) => state.isLoading));

    return Button(
      disabled: !hasChanges || isLoading,
      type: hasChanges ? ButtonType.primary : ButtonType.disabled,
      leadingIcon: isLoading
          ? const IONLoadingIndicator()
          : Assets.svg.iconProfileSave.icon(
              color: context.theme.appColors.onPrimaryAccent,
            ),
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          final avatarFile = ref
              .read(imageProcessorNotifierProvider(ImageProcessingType.avatar))
              .whenOrNull(processed: (file) => file);
          final bannerFile = ref
              .read(imageProcessorNotifierProvider(ImageProcessingType.banner))
              .whenOrNull(processed: (file) => file);
          await ref
              .read(updateUserMetadataNotifierProvider.notifier)
              .publish(draftRef.value, avatar: avatarFile, banner: bannerFile);
          if (context.mounted && !ref.read(updateUserMetadataNotifierProvider).hasError) {
            context.maybePop();
          }
        }
      },
      label: Text(context.i18n.profile_save),
      mainAxisSize: MainAxisSize.max,
    );
  }
}
