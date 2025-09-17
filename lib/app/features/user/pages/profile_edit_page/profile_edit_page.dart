// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/separated/separator.dart';
import 'package:ion/app/components/text_editor/components/suggestions_container.dart';
import 'package:ion/app/components/text_editor/text_editor.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/bio_rich_text_input.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/location_input.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/name_input.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/nickname_input.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/website_input.dart';
import 'package:ion/app/features/feed/providers/suggestions/suggestions_notifier_provider.r.dart';
import 'package:ion/app/features/user/hooks/use_nickname_availability_error_message.dart';
import 'package:ion/app/features/user/pages/components/profile_avatar/profile_avatar.dart';
import 'package:ion/app/features/user/pages/profile_edit_page/components/category_selector/category_selector.dart';
import 'package:ion/app/features/user/pages/profile_edit_page/components/edit_submit_button/edit_submit_button.dart';
import 'package:ion/app/features/user/pages/profile_edit_page/components/header/header.dart';
import 'package:ion/app/features/user/pages/profile_edit_page/hooks/use_draft_metadata.dart';
import 'package:ion/app/features/user/providers/update_user_metadata_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/user/providers/user_nickname_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/utils/url.dart';

class ProfileEditPage extends HookConsumerWidget {
  const ProfileEditPage({
    super.key,
  });

  static double get paddingValue => 20.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final pubkey = ref.watch(currentPubkeySelectorProvider)!;
    final userMetadata = ref.watch(userMetadataProvider(pubkey)).valueOrNull;

    if (userMetadata == null) {
      return const SizedBox.shrink();
    }

    final (:hasChanges, :draftRef, :update) = useDraftMetadata(ref, userMetadata.data);

    final nickname = useState(userMetadata.data.name);
    final debouncedNickname = useDebounced(nickname.value.trim(), const Duration(seconds: 1));
    useOnInit(
      () {
        if (debouncedNickname != null &&
            validateNickname(debouncedNickname, context) == null &&
            debouncedNickname != userMetadata.data.name) {
          ref
              .read(userNicknameNotifierProvider.notifier)
              .verifyNicknameAvailability(nickname: debouncedNickname);
        }
      },
      [debouncedNickname, context, userMetadata.data.name],
    );

    final verifyNicknameErrorMessage =
        useNicknameAvailabilityErrorMessage(ref, userNicknameNotifierProvider);
    final updateUserMetadataError =
        useNicknameAvailabilityErrorMessage(ref, updateUserMetadataNotifierProvider);

    final textEditorKey = useMemoized(TextEditorKeys.bioInput);
    final scrollController = useScrollController();
    final suggestionsState = ref.watch(suggestionsNotifierProvider);

    return Scaffold(
      body: KeyboardDismissOnTap(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: ScreenTopOffset(
                      child: ScreenSideOffset.large(
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              ProfileAvatar(pubkey: pubkey, showAvatarPicker: true),
                              SizedBox(height: paddingValue),
                              NameInput(
                                initialValue: userMetadata.data.displayName,
                                isLive: true,
                                onChanged: (text) =>
                                    update(draftRef.value.copyWith(displayName: text)),
                              ),
                              SizedBox(height: paddingValue),
                              NicknameInput(
                                initialValue: userMetadata.data.name,
                                isLive: true,
                                errorText: updateUserMetadataError.value ??
                                    verifyNicknameErrorMessage.value,
                                onChanged: (text) {
                                  updateUserMetadataError.value = null;
                                  verifyNicknameErrorMessage.value = null;
                                  update(draftRef.value.copyWith(name: text));
                                  nickname.value = text;
                                },
                              ),
                              SizedBox(height: paddingValue),
                              BioRichTextInput(
                                textEditorKey: textEditorKey,
                                initialValue: userMetadata.data.about,
                                onChanged: (text) => update(
                                  draftRef.value.copyWith(about: text.trim().isEmpty ? null : text),
                                ),
                              ),
                              SuggestionsContainer(
                                scrollController: scrollController,
                                editorKey: textEditorKey,
                              ),
                              if (!(suggestionsState.isVisible &&
                                  suggestionsState.suggestions.isNotEmpty))
                                SizedBox(height: paddingValue),
                              CategorySelector(
                                selectedCategory: draftRef.value.category,
                                onChanged: (category) => update(
                                  draftRef.value.copyWith(category: category),
                                ),
                              ),
                              SizedBox(height: paddingValue),
                              LocationInput(
                                initialValue: userMetadata.data.location,
                                onChanged: (text) => update(
                                  draftRef.value.copyWith(location: text.isEmpty ? null : text),
                                ),
                              ),
                              SizedBox(height: paddingValue),
                              WebsiteInput(
                                initialValue: removeHttpsPrefix(userMetadata.data.website),
                                onChanged: (text) => update(
                                  draftRef.value
                                      .copyWith(website: text.trim().isEmpty ? null : text),
                                ),
                              ),
                              SizedBox(height: paddingValue),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HorizontalSeparator(),
                    SizedBox(height: 16.0.s),
                    ScreenSideOffset.large(
                      child: EditSubmitButton(
                        formKey: formKey,
                        hasChanges: hasChanges,
                        draftRef: draftRef,
                      ),
                    ),
                    SizedBox(height: paddingValue),
                  ],
                ),
              ],
            ),
            PositionedDirectional(child: Header(pubkey: pubkey)),
          ],
        ),
      ),
    );
  }
}
