// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/delegation_complete_provider.r.dart';
import 'package:ion/app/features/auth/providers/onboarding_complete_notifier.r.dart';
import 'package:ion/app/features/auth/views/pages/turn_on_notifications/turn_on_notifications.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/core/permissions/data/models/permissions_types.dart';
import 'package:ion/app/features/core/permissions/providers/permissions_provider.r.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_utils.dart';
import 'package:ion/app/features/ion_connect/providers/restore_device_keypair_notifier.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/ui_event_queue/ui_event_queue_notifier.r.dart';
import 'package:ion/generated/assets.gen.dart';
import 'package:ion_identity_client/ion_identity.dart';

class ShowLinkNewDeviceDialogEvent extends UiEvent {
  const ShowLinkNewDeviceDialogEvent() : super(id: 'link_new_device_dialog');

  @override
  Future<void> performAction(BuildContext context) async {
    await showSimpleBottomSheet<void>(
      context: context,
      isDismissible: false,
      child: const LinkNewDeviceDialog(),
    );
  }
}

class LinkNewDeviceDialog extends HookConsumerWidget {
  const LinkNewDeviceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

    final delegationComplete = ref.watch(delegationCompleteProvider).valueOrNull.falseOrValue;
    useOnInit(
      () {
        if (delegationComplete) {
          Navigator.of(ref.context).pop();

          if (!ref.read(hasPermissionProvider(Permission.notifications))) {
            ref
                .read(uiEventQueueNotifierProvider.notifier)
                .emit(const ShowTurnOnNotificationsEvent());
          }
        }
      },
      [delegationComplete],
    );

    final state = ref.watch(onboardingCompleteNotifierProvider);
    ref.displayErrors(
      onboardingCompleteNotifierProvider,
      excludedExceptions: excludedPasskeyExceptions,
    );

    return ScreenSideOffset.medium(
      child: Column(
        children: [
          SizedBox(height: 48.0.s),
          Assets.svg.actionLoginLinkaccount.icon(size: 80.0.s),
          SizedBox(height: 6.0.s),
          Text(
            context.i18n.auth_link_new_device_title,
            style: textStyles.title,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.0.s),
          Text(
            context.i18n.auth_link_new_device_description,
            style: textStyles.body2.copyWith(color: colors.secondaryText),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.0.s),
          Button(
            minimumSize: Size(double.infinity, 56.0.s),
            disabled: state.isLoading,
            trailingIcon: state.isLoading ? const IONLoadingIndicator() : const SizedBox.shrink(),
            label: Text(context.i18n.auth_link_new_device_link_button),
            onPressed: () => _linkNewDevice(ref),
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }

  Future<void> _linkNewDevice(WidgetRef ref) async {
    final hasUploadedKeypair = await _hasUploadedKeypair(ref);

    if (hasUploadedKeypair) {
      // There's an uploaded keypair - restore it instead of creating new delegation
      await _restoreKeypair(ref);
    } else {
      // No uploaded keypair - proceed with normal delegation creation
      await _addDelegation(ref);
    }
  }

  Future<bool> _hasUploadedKeypair(WidgetRef ref) async {
    try {
      final currentUserMetadata = await ref.read(currentUserMetadataProvider.future);
      final keypairAttachment =
          DeviceKeypairUtils.extractDeviceKeypairAttachmentFromMetadata(currentUserMetadata);
      return keypairAttachment != null;
    } catch (e) {
      Logger.error(
        e,
        stackTrace: StackTrace.current,
        message: 'Failed to check metadata for uploaded keypair',
      );
      return false;
    }
  }

  Future<void> _restoreKeypair(WidgetRef ref) async {
    await guardPasskeyDialog(
      ref.context,
      (child) => RiverpodUserActionSignerRequestBuilder(
        provider: restoreDeviceKeypairNotifierProvider,
        request: (signer) async {
          await ref
              .read(restoreDeviceKeypairNotifierProvider.notifier)
              .restoreDeviceKeypair(signer: signer);
        },
        child: child,
      ),
    );
    // If something went wrong during keypair restoration
    // or if the restored keypair is no longer delegated,
    // fallback to adding a new delegation
    if (ref.read(restoreDeviceKeypairNotifierProvider).hasError ||
        !(await ref.read(delegationCompleteProvider.future))) {
      return _addDelegation(ref);
    }
  }

  Future<void> _addDelegation(WidgetRef ref) async {
    await guardPasskeyDialog(
      ref.context,
      (child) => RiverpodVerifyIdentityRequestBuilder(
        requestWithVerifyIdentity: (OnVerifyIdentity<GenerateSignatureResponse> onVerifyIdentity) {
          ref.read(onboardingCompleteNotifierProvider.notifier).addDelegation(onVerifyIdentity);
        },
        provider: onboardingCompleteNotifierProvider,
        child: child,
      ),
    );
  }
}
