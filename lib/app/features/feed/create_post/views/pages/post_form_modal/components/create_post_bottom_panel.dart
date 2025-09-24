// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/text_editor/components/suggestions_container.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/views/components/character_limit_exceed_indicator/character_limit_exceed_indicator.dart';
import 'package:ion/app/features/feed/create_post/views/components/post_submit_button/post_submit_button.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/who_can_reply_settings_option.f.dart';
import 'package:ion/app/features/feed/providers/root_post_provider.r.dart';
import 'package:ion/app/features/feed/providers/selected_who_can_reply_option_provider.r.dart';
import 'package:ion/app/features/feed/views/components/actions_toolbar/actions_toolbar.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_bold_button.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_image_button.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_italic_button.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_poll_button.dart';
import 'package:ion/app/features/feed/views/pages/who_can_reply_settings_modal/who_can_reply_settings_modal.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/typedefs/typedefs.dart';
import 'package:ion/generated/assets.gen.dart';

class _Delimiter extends StatelessWidget {
  const _Delimiter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 0.5.s,
      color: context.theme.appColors.onTertiaryFill,
    );
  }
}

class CreatePostBottomPanel extends StatelessWidget {
  const CreatePostBottomPanel({
    required this.textEditorController,
    required this.parentEvent,
    required this.quotedEvent,
    required this.modifiedEvent,
    required this.attachedMediaNotifier,
    required this.attachedMediaLinksNotifier,
    required this.attachedVideoNotifier,
    required this.createOption,
    required this.scrollController,
    required this.textEditorKey,
    super.key,
  });

  final QuillController textEditorController;
  final EventReference? parentEvent;
  final EventReference? quotedEvent;
  final EventReference? modifiedEvent;
  final AttachedMediaNotifier attachedMediaNotifier;
  final ValueNotifier<MediaFile?> attachedVideoNotifier;
  final AttachedMediaLinksNotifier attachedMediaLinksNotifier;
  final CreatePostOption createOption;
  final ScrollController scrollController;
  final GlobalKey<TextEditorState> textEditorKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenSideOffset.small(
          child: SuggestionsContainer(
            scrollController: scrollController,
            editorKey: textEditorKey,
          ),
        ),
        _WhoCanReplySection(
          createOption: createOption,
          modifiedEvent: modifiedEvent,
          parentEvent: parentEvent,
        ),
        const _Delimiter(),
        SizedBox(
          height: 8.0.s,
        ),
        _ActionsSection(
          textEditorController: textEditorController,
          parentEvent: parentEvent,
          quotedEvent: quotedEvent,
          modifiedEvent: modifiedEvent,
          attachedMediaNotifier: attachedMediaNotifier,
          attachedMediaLinksNotifier: attachedMediaLinksNotifier,
          attachedVideoNotifier: attachedVideoNotifier,
          createOption: createOption,
        ),
        SizedBox(
          height: 8.0.s,
        ),
      ],
    );
  }
}

class _WhoCanReplySection extends HookConsumerWidget {
  const _WhoCanReplySection({
    required this.createOption,
    this.parentEvent,
    this.modifiedEvent,
  });

  final CreatePostOption createOption;
  final EventReference? parentEvent;
  final EventReference? modifiedEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOption = ref.watch(selectedWhoCanReplyOptionProvider);
    final modifiableEntity = modifiedEvent != null
        ? ref.watch(ionConnectEntityProvider(eventReference: modifiedEvent!)).valueOrNull
        : null;

    final rootEntity = parentEvent != null
        ? ref.watch(rootPostEntityProvider(eventReference: parentEvent!))
        : null;

    useOnInit(
      () async {
        if (rootEntity != null && rootEntity is ModifiablePostEntity) {
          ref.read(selectedWhoCanReplyOptionProvider.notifier).option =
              rootEntity.data.whoCanReplySetting;
        } else if (modifiableEntity != null && modifiableEntity is ModifiablePostEntity) {
          ref.read(selectedWhoCanReplyOptionProvider.notifier).option =
              modifiableEntity.data.whoCanReplySetting;
        }
      },
      [modifiableEntity, rootEntity],
    );

    if (parentEvent != null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const _Delimiter(),
        ScreenSideOffset.small(
          child: ListItem(
            title: Text(
              selectedOption.getTitle(context),
              style: context.theme.appTextThemes.caption.copyWith(
                color: context.theme.appColors.primaryAccent,
              ),
            ),
            contentPadding: EdgeInsets.zero,
            backgroundColor: context.theme.appColors.secondaryBackground,
            leading: selectedOption.getIcon(context),
            trailing: Assets.svg.iconArrowRight.icon(
              color: context.theme.appColors.primaryAccent,
            ),
            constraints: BoxConstraints(minHeight: 40.0.s),
            onTap: () => showSimpleBottomSheet<void>(
              context: context,
              child: WhoCanReplySettingsModal(
                title: createOption == CreatePostOption.video
                    ? context.i18n.who_can_reply_settings_title_video
                    : context.i18n.who_can_reply_settings_title_post,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.textEditorController,
    required this.parentEvent,
    required this.quotedEvent,
    required this.modifiedEvent,
    required this.attachedMediaNotifier,
    required this.attachedMediaLinksNotifier,
    required this.attachedVideoNotifier,
    required this.createOption,
  });

  final QuillController textEditorController;
  final EventReference? parentEvent;
  final EventReference? quotedEvent;
  final EventReference? modifiedEvent;
  final AttachedMediaNotifier attachedMediaNotifier;
  final AttachedMediaLinksNotifier attachedMediaLinksNotifier;
  final ValueNotifier<MediaFile?> attachedVideoNotifier;
  final CreatePostOption createOption;

  @override
  Widget build(BuildContext context) {
    final isVideo = createOption == CreatePostOption.video;

    final alreadyAttachedMediaCount = attachedMediaLinksNotifier.value.length;

    return ScreenSideOffset.small(
      child: ActionsToolbar(
        actions: [
          ToolbarMediaButton(
            delegate: AttachedMediaHandler(attachedMediaNotifier),
            maxMedia:
                isVideo ? 1 : ModifiablePostEntity.contentMediaLimit - alreadyAttachedMediaCount,
            enabled: !isVideo,
          ),
          ToolbarPollButton(
            enabled: !isVideo,
          ),
          ToolbarItalicButton(textEditorController: textEditorController),
          ToolbarBoldButton(textEditorController: textEditorController),
        ],
        trailing: Row(
          children: [
            CharacterLimitExceedIndicator(
              maxCharacters: ModifiablePostEntity.contentCharacterLimit,
              textEditorController: textEditorController,
            ),
            SizedBox(width: 8.0.s),
            PostSubmitButton(
              textEditorController: textEditorController,
              parentEvent: parentEvent,
              quotedEvent: quotedEvent,
              modifiedEvent: modifiedEvent,
              mediaFiles: [
                ...attachedMediaNotifier.value,
                if (attachedVideoNotifier.value != null) attachedVideoNotifier.value!,
              ],
              mediaAttachments: attachedMediaLinksNotifier.value,
              createOption: createOption,
              shouldShowTooltip:
                  parentEvent == null && quotedEvent == null && modifiedEvent == null,
            ),
          ],
        ),
      ),
    );
  }
}
