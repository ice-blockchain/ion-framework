// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/general_user_data_input.dart';
import 'package:ion/app/features/chat/community/models/group_type.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message/send_e2ee_chat_message_service.r.dart';
import 'package:ion/app/features/chat/providers/create_group_form_controller_provider.r.dart';
import 'package:ion/app/features/chat/views/components/general_selection_button.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/componentes/group_participant_list_item.dart';
import 'package:ion/app/features/components/avatar_picker/avatar_picker.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/app/services/uuid/uuid.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

class CreateGroupModal extends HookConsumerWidget {
  const CreateGroupModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const nameMaxLength = 100;
    final loading = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final currentMasterPubkey = ref.watch(currentPubkeySelectorProvider);

    final createGroupForm = ref.watch(createGroupFormControllerProvider);
    final createGroupFormNotifier = ref.watch(createGroupFormControllerProvider.notifier);
    final nameController = useTextEditingController(text: createGroupForm.name);

    final participantsMasterPubkeys = currentMasterPubkey != null
        ? [
            ...createGroupForm.participantsMasterPubkeys,
            currentMasterPubkey,
          ]
        : <String>[];

    useEffect(
      () {
        void updateTitle() {
          createGroupFormNotifier.title = nameController.text;
        }

        nameController.addListener(updateTitle);
        return () => nameController.removeListener(updateTitle);
      },
      [nameController],
    );

    return SheetContent(
      topPadding: 0,
      body: Column(
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            title: Text(context.i18n.group_create_title),
            actions: const [
              NavigationCloseButton(),
            ],
          ),
          SizedBox(height: 27.0.s),
          Expanded(
            child: Form(
              key: formKey,
              child: ScreenSideOffset.small(
                child: Column(
                  children: [
                    Row(
                      children: [
                        AvatarPicker(
                          avatarSize: 58.0.s,
                          iconSize: 14.0.s,
                          iconBackgroundSize: 21.0.s,
                        ),
                        SizedBox(width: 16.0.s),
                        Expanded(
                          child: GeneralUserDataInput(
                            controller: nameController,
                            prefixIconAssetName: Assets.svg.iconFieldName,
                            labelText: context.i18n.group_create_name_label,
                            validator: (String? value) {
                              if (Validators.isEmpty(value)) return '';
                              if (Validators.isInvalidLength(value, maxLength: nameMaxLength)) {
                                return context.i18n.error_input_length_max(nameMaxLength);
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.0.s),
                    GeneralSelectionButton(
                      iconAsset: Assets.svg.iconChannelType,
                      title: context.i18n.group_create_type,
                      selectedValue: createGroupForm.type.getTitle(context),
                      onPress: () {},
                    ),
                    SizedBox(height: 24.0.s),
                    Row(
                      children: [
                        Assets.svg.iconCategoriesFollowing.icon(size: 16.0.s),
                        SizedBox(width: 6.0.s),
                        Text(
                          context.i18n
                              .group_create_members_number(participantsMasterPubkeys.length - 1),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            AddParticipantsToGroupModalRoute().go(context);
                          },
                          child: Text(
                            context.i18n.button_edit.toLowerCase(),
                            style: context.theme.appTextThemes.caption.copyWith(
                              color: context.theme.appColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0.s),
                    Expanded(
                      child: ListView.separated(
                        itemCount: participantsMasterPubkeys.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.0.s),
                        itemBuilder: (_, int i) {
                          final participantMasterkey = participantsMasterPubkeys[i];

                          if (participantMasterkey == currentMasterPubkey) {
                            return const SizedBox.shrink();
                          }

                          return GroupParticipantsListItem(
                            participantMasterkey: participantMasterkey,
                            onRemove: () {
                              createGroupFormNotifier.toggleMember(participantMasterkey);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const HorizontalSeparator(),
          SizedBox(height: 16.0.s),
          ScreenBottomOffset(
            margin: 32.0.s,
            child: ScreenSideOffset.medium(
              child: Button(
                disabled: loading.value,
                mainAxisSize: MainAxisSize.max,
                label: Text(context.i18n.group_create_create_button),
                leadingIcon: loading.value
                    ? IONLoadingIndicator(size: Size(16.s, 16.s))
                    : Assets.svg.iconPlusCreatechannel.icon(
                        size: 32.s,
                        color: context.theme.appColors.onPrimaryAccent,
                      ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (createGroupForm.type == GroupType.encrypted) {
                      final avatarProcessorState =
                          ref.read(imageProcessorNotifierProvider(ImageProcessingType.avatar));

                      final groupPicture = avatarProcessorState.whenOrNull(
                        cropped: (file) => file,
                        processed: (file) => file,
                      );

                      loading.value = true;

                      await ref.read(sendE2eeChatMessageServiceProvider).sendMessage(
                            content: '',
                            subject: createGroupForm.name,
                            conversationId: generateUuid(),
                            participantsMasterPubkeys: participantsMasterPubkeys,
                            mediaFiles: groupPicture != null ? [groupPicture] : [],
                          );

                      loading.value = false;

                      if (context.mounted) {
                        context.pop();
                      }
                    } else {
                      throw UnimplementedError();
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
