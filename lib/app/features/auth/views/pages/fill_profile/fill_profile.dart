// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/hooks/use_referrer_controller.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/onboarding_data_provider.m.dart';
import 'package:ion/app/features/auth/views/components/auth_scrolled_body/auth_scrolled_body.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/name_input.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/nickname_input.dart';
import 'package:ion/app/features/auth/views/components/user_data_inputs/referral_input.dart';
import 'package:ion/app/features/auth/views/pages/fill_profile/components/fill_prifile_submit_button.dart';
import 'package:ion/app/features/components/avatar_picker/avatar_picker.dart';
import 'package:ion/app/features/user/hooks/use_verify_nickname_availability_error_message.dart';
import 'package:ion/app/features/user/hooks/use_verify_referral_exists_error_message.dart';
import 'package:ion/app/features/user/providers/image_proccessor_notifier.m.dart';
import 'package:ion/app/features/user/providers/user_nickname_provider.r.dart';
import 'package:ion/app/features/user/providers/user_referral_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/services/clipboard/clipboard.dart';
import 'package:ion/app/services/media_service/image_proccessing_config.dart';
import 'package:ion/generated/assets.gen.dart';

class FillProfile extends HookConsumerWidget {
  const FillProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final onboardingData = ref.watch(onboardingDataProvider);
    final isAvatarCompressing = ref.watch(
      imageProcessorNotifierProvider(ImageProcessingType.avatar)
          .select((state) => state is ImageProcessorStateCropped),
    );
    final initialName = onboardingData.displayName ?? '';
    final name = useState(initialName);
    final initialNickname = onboardingData.name ?? '';
    final nickname = useState(onboardingData.name ?? '');
    final debouncedNickname = useDebounced(nickname.value.trim(), const Duration(seconds: 1));

    final referralController = useReferrerController(ref, context);
    final debouncedReferral = useDebounced(
      referralController.text.trim(),
      const Duration(seconds: 1),
    );

    final isLoading = useState(false);
    //to insure that we are suggesting to use clipboard value only once
    final hasCheckedClipboardForReferral = useRef(false);

    final onSubmit = useCallback(() async {
      final referral = referralController.text;
      if (formKey.currentState!.validate()) {
        isLoading.value = true;
        await Future.wait(
          [
            ref
                .read(userNicknameNotifierProvider.notifier)
                .verifyNicknameAvailability(nickname: nickname.value),
            if (referral.isNotEmpty)
              ref
                  .read(userReferralNotifierProvider.notifier)
                  .verifyReferralExists(referral: referral),
          ],
        );
        isLoading.value = false;
        if (ref.read(userNicknameNotifierProvider).hasError ||
            (referral.isNotEmpty && ref.read(userReferralNotifierProvider).hasError)) {
          return;
        }

        final pickedAvatar = ref
            .read(imageProcessorNotifierProvider(ImageProcessingType.avatar))
            .whenOrNull(processed: (file) => file);
        if (pickedAvatar != null) {
          ref.read(onboardingDataProvider.notifier).avatar = pickedAvatar;
        }
        ref.read(onboardingDataProvider.notifier).name = nickname.value;
        ref.read(onboardingDataProvider.notifier).displayName = name.value;
        if (referral.isNotEmpty) {
          ref.read(onboardingDataProvider.notifier).referralName = referral;
        }
        if (context.mounted) {
          await SelectLanguagesRoute().push<void>(context);
        }
      }
    });

    final onFocused = useCallback(
      (bool hasFocus) async {
        if (hasFocus && referralController.text.isEmpty && !hasCheckedClipboardForReferral.value) {
          hasCheckedClipboardForReferral.value = true;
          //make sure that field selection is visible before requesting clipboard permission
          await Future<void>.delayed(const Duration(milliseconds: 100));
          final clipboardValue = await getClipboardText();
          if (!context.mounted) {
            return;
          }
          if (clipboardValue.isNotEmpty) {
            final validationError = validateNickname(clipboardValue, context);
            if (validationError == null) {
              referralController.text = clipboardValue;
            }
          }
        }
      },
      [referralController, hasCheckedClipboardForReferral],
    );

    useOnInit(
      () {
        if (debouncedNickname != null && validateNickname(debouncedNickname, context) == null) {
          ref
              .read(userNicknameNotifierProvider.notifier)
              .verifyNicknameAvailability(nickname: debouncedNickname);
        }
      },
      [debouncedNickname, context],
    );

    useOnInit(
      () {
        if (debouncedReferral != null && validateNickname(debouncedReferral, context) == null) {
          ref
              .read(userReferralNotifierProvider.notifier)
              .verifyReferralExists(referral: debouncedReferral);
        }
      },
      [debouncedReferral, context],
    );

    final verifyNicknameErrorMessage = useVerifyNicknameAvailabilityErrorMessage(ref);
    final verifyReferralErrorMessage = useVerifyReferralExistsErrorMessage(ref);

    return SheetContent(
      body: KeyboardDismissOnTap(
        child: AuthScrollContainer(
          title: context.i18n.fill_profile_title,
          description: context.i18n.fill_profile_description,
          icon: Assets.svg.iconLoginIcelogo.icon(size: 44.0.s),
          mainAxisAlignment: MainAxisAlignment.start,
          onBackPress: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              GetStartedRoute().go(context);
            }
          },
          children: [
            Form(
              key: formKey,
              child: Column(
                children: [
                  ScreenSideOffset.large(
                    child: Column(
                      children: [
                        SizedBox(height: 20.0.s),
                        AvatarPicker(
                          avatarWidget: onboardingData.avatar != null
                              ? Image.file(File(onboardingData.avatar!.path))
                              : null,
                        ),
                        SizedBox(height: 28.0.s),
                        NameInput(
                          isLive: true,
                          initialValue: initialName,
                          onChanged: (newValue) => name.value = newValue,
                        ),
                        SizedBox(height: 16.0.s),
                        NicknameInput(
                          isLive: true,
                          initialValue: initialNickname,
                          textInputAction: TextInputAction.done,
                          onChanged: (newValue) {
                            nickname.value = newValue;
                            verifyNicknameErrorMessage.value = null;
                          },
                          errorText: verifyNicknameErrorMessage.value,
                        ),
                        SizedBox(height: 16.0.s),
                        ReferralInput(
                          isLive: true,
                          controller: referralController,
                          textInputAction: TextInputAction.done,
                          onChanged: (newValue) {
                            verifyReferralErrorMessage.value = null;
                          },
                          onFocused: onFocused,
                          errorText: verifyReferralErrorMessage.value,
                        ),
                        SizedBox(height: 26.0.s),
                        FillProfileSubmitButton(
                          disabled: name.value.isEmpty || nickname.value.isEmpty || isLoading.value,
                          loading: isAvatarCompressing || isLoading.value,
                          onPressed: onSubmit,
                        ),
                        SizedBox(
                          height: 40.0.s + MediaQuery.paddingOf(context).bottom,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
