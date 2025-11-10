// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/general_user_data_input.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/group_member_role.f.dart';
import 'package:ion/app/features/chat/e2ee/model/group_metadata.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/encrypted_group_metadata_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/update_group_metadata_service.r.dart';
import 'package:ion/app/features/chat/e2ee/views/pages/group_admin_page/components/group_avatar.dart';
import 'package:ion/app/features/chat/views/components/general_selection_button.dart';
import 'package:ion/app/features/components/avatar_picker/avatar_picker.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupEditPage extends HookConsumerWidget {
  const GroupEditPage({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupMetadata = ref.watch(encryptedGroupMetadataProvider(conversationId)).valueOrNull;
    final formKey = useMemoized(GlobalKey<FormState>.new);

    if (groupMetadata == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final nameController = useTextEditingController(text: groupMetadata.name);

    final adminCount = groupMetadata.members
        .where((member) => member is GroupMemberRoleOwner || member is GroupMemberRoleAdmin)
        .length;

    return SheetContent(
      topPadding: 0,
      body: Column(
        children: [
          Container(
            padding: EdgeInsetsDirectional.only(
              top: 20.0.s,
              start: 16.0.s,
              end: 16.0.s,
              bottom: 16.0.s,
            ),
            child: NavigationAppBar.modal(
              showBackButton: false,
              title: Text(
                context.i18n.group_edit_title,
                style: context.theme.appTextThemes.subtitle.copyWith(
                  color: context.theme.appColors.primaryText,
                ),
              ),
              horizontalPadding: 0,
              actions: const [
                NavigationCloseButton(),
              ],
            ),
          ),
          Expanded(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: 287.0.s,
                    child: Column(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvatarPicker(
                              avatarSize: 100.0.s,
                              iconSize: 24.0.s,
                              iconBackgroundSize: 36.0.s,
                              avatarWidget: GroupAvatar(
                                avatar: groupMetadata.avatar,
                                size: 100.0.s,
                                borderRadius: BorderRadius.circular(20.0.s),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.0.s),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GeneralUserDataInput(
                              controller: nameController,
                              prefixIconAssetName: Assets.svg.iconFieldName,
                              labelText: context.i18n.group_create_name_label,
                              initialVerification: false,
                              validator: (String? value) {
                                if (Validators.isEmpty(value)) return '';
                                if (Validators.isInvalidLength(
                                  value,
                                  maxLength: EncryptedGroupMessageEntity.nameMaxLength,
                                )) {
                                  return context.i18n.error_input_length_max(
                                    EncryptedGroupMessageEntity.nameMaxLength,
                                  );
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20.0.s),
                            GeneralSelectionButton(
                              iconAsset: Assets.svg.iconChannelType,
                              title: context.i18n.group_create_type,
                              selectedValue: context.i18n.group_create_type_encrypted,
                              enabled: false,
                            ),
                            SizedBox(height: 20.0.s),
                            GeneralSelectionButton(
                              iconAsset: Assets.svg.iconChannelAdmin,
                              title: context.i18n.channel_create_admins,
                              selectedValue: adminCount.toString(),
                              onPress: () {
                                GroupAdminsModalRoute(conversationId: conversationId)
                                    .push<void>(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _EditGroupButton(
            formKey: formKey,
            conversationId: conversationId,
            nameController: nameController,
            groupMetadata: groupMetadata,
          ),
        ],
      ),
    );
  }
}

class _EditGroupButton extends HookConsumerWidget {
  const _EditGroupButton({
    required this.formKey,
    required this.conversationId,
    required this.nameController,
    required this.groupMetadata,
  });

  final GlobalKey<FormState> formKey;
  final String conversationId;
  final TextEditingController nameController;
  final GroupMetadata groupMetadata;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final isFormValid = useState(true);
    final hasTitleChanged = useState(false);
    final hasPictureChanged = useState(false);

    final avatarProcessorState =
        ref.watch(imageProcessorNotifierProvider(ImageProcessingType.avatar));

    // Check if title has changed
    useEffect(
      () {
        void checkTitleChange() {
          hasTitleChanged.value = nameController.text.trim() != groupMetadata.name.trim();
        }

        nameController.addListener(checkTitleChange);
        checkTitleChange();
        return () {
          nameController.removeListener(checkTitleChange);
        };
      },
      [nameController, groupMetadata.name],
    );

    // Check if picture has changed
    useEffect(
      () {
        final groupPicture = avatarProcessorState.whenOrNull(
          cropped: (file) => file,
          processed: (file) => file,
        );
        hasPictureChanged.value = groupPicture != null;
        return null;
      },
      [avatarProcessorState],
    );

    // Check if anything has changed
    final hasChanges = hasTitleChanged.value || hasPictureChanged.value;

    useEffect(
      () {
        void validateForm() {
          isFormValid.value = formKey.currentState?.validate() ?? false;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          validateForm();
          nameController.addListener(validateForm);
        });
        return () {
          nameController.removeListener(validateForm);
        };
      },
      [nameController],
    );
    return Container(
      padding: EdgeInsetsDirectional.only(
        start: 44.0.s,
        end: 44.0.s,
        top: 16.0.s,
        bottom: 16.0.s,
      ),
      child: Button(
        mainAxisSize: MainAxisSize.max,
        label: Text(
          context.i18n.button_save,
          style: context.theme.appTextThemes.body.copyWith(
            color: context.theme.appColors.onPrimaryAccent,
          ),
        ),
        leadingIcon: isLoading.value
            ? IONLoadingIndicator(size: Size(24.s, 24.s))
            : Assets.svg.iconProfileSave.icon(
                color: context.theme.appColors.onPrimaryAccent,
                size: 24.0.s,
              ),
        disabled: !isFormValid.value || isLoading.value || !hasChanges,
        trailingIcon: isLoading.value ? const IONLoadingIndicator() : null,
        type: isFormValid.value && hasChanges ? ButtonType.primary : ButtonType.disabled,
        onPressed: () async {
          if (formKey.currentState!.validate() && hasChanges) {
            isLoading.value = true;

            try {
              final groupPicture = avatarProcessorState.whenOrNull(
                cropped: (file) => file,
                processed: (file) => file,
              );

              await ref.read(updateGroupMetaDataServiceProvider).updateMetadata(
                    groupId: conversationId,
                    title: hasTitleChanged.value ? nameController.text.trim() : null,
                    newGroupPicture: hasPictureChanged.value ? groupPicture : null,
                  );

              if (context.mounted) {
                context.pop();
              }
            } finally {
              isLoading.value = false;
            }
          }
        },
      ),
    );
  }
}
