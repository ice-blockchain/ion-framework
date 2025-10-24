// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/checkbox/labeled_checkbox.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/components/verify_identity/verify_identity_prompt_dialog_helper.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_manager.r.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_state.f.dart';
import 'package:ion/app/features/ion_connect/providers/restore_device_keypair_notifier.r.dart';
import 'package:ion/app/features/ion_connect/providers/upload_device_keypair_notifier.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

const _iconSize = 80.0;

class DeviceKeypairDialog extends HookConsumerWidget {
  const DeviceKeypairDialog({
    required this.state,
    super.key,
  });

  final DeviceKeypairState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(
      () => ref.read(deviceKeypairDialogShownOnceProvider.notifier).markShownOnce,
      [],
    );

    return switch (state) {
      DeviceKeypairState.needsUpload || DeviceKeypairState.uploadInProgress => _UploadDialog(
          isInProgress: state == DeviceKeypairState.uploadInProgress,
        ),
      DeviceKeypairState.needsRestore => const _RestoreDialog(),
      _ => throw StateError('Invalid state: $state'),
    };
  }
}

class _UploadDialog extends HookConsumerWidget {
  const _UploadDialog({
    required this.isInProgress,
  });

  final bool isInProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dontShowAgain = useState(false);

    final shownOnce = ref.watch(deviceKeypairDialogShownOnceProvider).valueOrNull ?? false;
    final showCheckbox = shownOnce;

    ref
      ..listenError(uploadDeviceKeypairNotifierProvider, (_) => _popIfMounted(context))
      ..listenSuccess(uploadDeviceKeypairNotifierProvider, (_) => _popIfMounted(context));

    return _DeviceKeypairDialogContent(
      icon: Assets.svg.actionchatsynckey.icon(size: _iconSize.s),
      title: isInProgress
          ? context.i18n.device_keypair_upload_complete_title
          : context.i18n.device_keypair_upload_title,
      description: isInProgress
          ? context.i18n.device_keypair_upload_incomplete_description
          : context.i18n.device_keypair_upload_description,
      actionButtonLabel: showCheckbox && dontShowAgain.value
          ? context.i18n.button_close
          : isInProgress
              ? context.i18n.device_keypair_button_complete_upload
              : context.i18n.device_keypair_button_upload_now,
      showCheckbox: showCheckbox,
      checkboxLabel: context.i18n.device_keypair_button_dont_show_again,
      isDontShowAgain: dontShowAgain.value,
      onToggleDontShowAgain: (v) => dontShowAgain.value = v,
      onActionButtonPressed: () async {
        if (showCheckbox && dontShowAgain.value) {
          await ref.read(deviceKeypairDialogSuppressedProvider.notifier).setSuppressed(value: true);
          if (context.mounted) context.pop();
          return;
        }
        await guardPasskeyDialog(
          context,
          (child) {
            return RiverpodUserActionSignerRequestBuilder(
              provider: uploadDeviceKeypairNotifierProvider,
              request: (signer) async {
                await ref
                    .read(uploadDeviceKeypairNotifierProvider.notifier)
                    .uploadDeviceKeypair(signer: signer);
              },
              child: child,
            );
          },
        );
      },
    );
  }
}

class _RestoreDialog extends HookConsumerWidget {
  const _RestoreDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dontShowAgain = useState(false);

    final shownOnce = ref.watch(deviceKeypairDialogShownOnceProvider).valueOrNull ?? false;
    final showCheckbox = shownOnce;

    ref
      ..listenError(restoreDeviceKeypairNotifierProvider, (_) => _popIfMounted(context))
      ..listenSuccess(restoreDeviceKeypairNotifierProvider, (_) => _popIfMounted(context));

    return _DeviceKeypairDialogContent(
      icon: Assets.svg.actionchatrestorekey.icon(size: _iconSize.s),
      title: context.i18n.device_keypair_restore_title,
      description: context.i18n.device_keypair_restore_description,
      actionButtonLabel: showCheckbox && dontShowAgain.value
          ? context.i18n.button_close
          : context.i18n.device_keypair_button_restore_now,
      showCheckbox: showCheckbox,
      checkboxLabel: context.i18n.device_keypair_button_dont_show_again,
      isDontShowAgain: dontShowAgain.value,
      onToggleDontShowAgain: (v) => dontShowAgain.value = v,
      onActionButtonPressed: () async {
        if (showCheckbox && dontShowAgain.value) {
          await ref.read(deviceKeypairDialogSuppressedProvider.notifier).setSuppressed(value: true);
          if (context.mounted) context.pop();
          return;
        }
        await guardPasskeyDialog(
          context,
          (child) {
            return RiverpodUserActionSignerRequestBuilder(
              provider: restoreDeviceKeypairNotifierProvider,
              request: (signer) async {
                await ref
                    .read(restoreDeviceKeypairNotifierProvider.notifier)
                    .restoreDeviceKeypair(signer: signer);
              },
              child: child,
            );
          },
        );
      },
    );
  }
}

void _popIfMounted(BuildContext context) {
  if (context.mounted) {
    context.pop();
  }
}

class _DeviceKeypairDialogContent extends StatelessWidget {
  const _DeviceKeypairDialogContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionButtonLabel,
    required this.onActionButtonPressed,
    this.showCheckbox = false,
    this.checkboxLabel,
    this.isDontShowAgain = false,
    this.onToggleDontShowAgain,
  });

  final Widget icon;
  final String title;
  final String description;
  final String actionButtonLabel;
  final VoidCallback onActionButtonPressed;
  final bool showCheckbox;
  final String? checkboxLabel;
  final bool isDontShowAgain;
  final ValueChanged<bool>? onToggleDontShowAgain;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.theme.appTextThemes;
    final colors = context.theme.appColors;

    return SheetContent(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationAppBar.modal(
            showBackButton: false,
            actions: const [
              NavigationCloseButton(),
            ],
          ),
          ScreenSideOffset.medium(
            child: Column(
              children: [
                icon,
                SizedBox(height: 8.0.s),
                Text(
                  title,
                  style: textStyles.title,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.0.s),
                Text(
                  description,
                  style: textStyles.body2.copyWith(color: colors.secondaryText),
                  textAlign: TextAlign.center,
                ),
                if (showCheckbox) ...[
                  SizedBox(height: 16.0.s),
                  LabeledCheckbox(
                    isChecked: isDontShowAgain,
                    onChanged: (v) => onToggleDontShowAgain?.call(v),
                    label: checkboxLabel ?? '',
                    textStyle: textStyles.body.copyWith(color: colors.primaryText),
                  ),
                ],
                SizedBox(height: 28.0.s),
                Button(
                  minimumSize: Size(double.infinity, 56.0.s),
                  label: Text(actionButtonLabel),
                  onPressed: onActionButtonPressed,
                ),
              ],
            ),
          ),
          ScreenBottomOffset(),
        ],
      ),
    );
  }
}
