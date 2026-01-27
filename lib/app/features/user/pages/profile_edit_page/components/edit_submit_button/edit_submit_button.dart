// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/tokenized_communities/providers/token_action_first_buy_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart' as user_model;
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class EditSubmitButton extends ConsumerWidget {
  const EditSubmitButton({
    required this.hasChanges,
    required this.draftRef,
    required this.formKey,
    super.key,
  });

  final bool hasChanges;

  final ObjectRef<user_model.UserMetadata> draftRef;

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

          final isPublished = await _publishChanges(
            context: context,
            ref: ref,
            draft: draftRef.value,
            avatarFile: avatarFile,
            bannerFile: bannerFile,
          );

          if (context.mounted &&
              !ref.read(updateUserMetadataNotifierProvider).hasError &&
              isPublished) {
            context.maybePop();
          }
        }
      },
      label: Text(context.i18n.profile_save),
      mainAxisSize: MainAxisSize.max,
    );
  }

  Future<bool> _publishChanges({
    required BuildContext context,
    required WidgetRef ref,
    required user_model.UserMetadata draft,
    MediaFile? avatarFile,
    MediaFile? bannerFile,
  }) async {
    final currentUserMetadata = ref.read(currentUserMetadataProvider).valueOrNull;
    if (currentUserMetadata == null) {
      return false;
    }

    final nameOrNicknameChanged = draft.name != currentUserMetadata.data.name ||
        draft.displayName != currentUserMetadata.data.displayName;

    if (nameOrNicknameChanged) {

      final hasCreatorToken = await ref.read(
        ionConnectEntityHasTokenProvider(
          eventReference: currentUserMetadata.toEventReference(),
        ).future,
      );

      if (hasCreatorToken && context.mounted) {
        await guardPasskeyDialog(
          context,
          (child) => RiverpodUserActionSignerRequestBuilder(
            provider: updateUserMetadataNotifierProvider,
            request: (UserActionSignerNew signer) async {
              await ref
                  .read(updateUserMetadataNotifierProvider.notifier)
                  .publishWithUserActionSigner(
                    draft,
                    avatar: avatarFile,
                    banner: bannerFile,
                    userActionSigner: signer,
                  );
            },
            identityKeyName: ref.read(currentIdentityKeyNameSelectorProvider),
            child: child,
          ),
        );

        return true;
      }
    }
    await ref
        .read(updateUserMetadataNotifierProvider.notifier)
        .publish(draft, avatar: avatarFile, banner: bannerFile);

    return true;
  }
}
