// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/modal_action_button/modal_action_button.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/separated/separated_column.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/auth/providers/registration_restrictions_provider.r.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/components/accounts_list/accounts_list.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/providers/switch_account_modal_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/app/utils/username.dart';
import 'package:ion/generated/assets.gen.dart';

class SwitchAccountModal extends HookConsumerWidget {
  const SwitchAccountModal({
    super.key,
    this.enableAccountManagement = true,
    this.showAddAccountOptions = false,
  });

  final bool enableAccountManagement;
  final bool showAddAccountOptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showAddAccountOptions) {
      return _AddAccountOptionsModal(enableAccountManagement: enableAccountManagement);
    }

    final userMetadataValue = ref.watch(currentUserMetadataProvider).valueOrNull;
    final currentPubkey = ref.watch(currentPubkeySelectorProvider);

    return SheetContent(
      body: ScreenSideOffset.small(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0.s,
            children: [
              NavigationAppBar.modal(
                showBackButton: false,
                title: Text(context.i18n.profile_switch_user_header),
                actions: const [NavigationCloseButton()],
              ),
              if (enableAccountManagement)
                ModalActionButton(
                  icon: Assets.svg.iconChannelType.icon(
                    color: context.theme.appColors.primaryAccent,
                  ),
                  label: context.i18n.profile_create_new_account,
                  onTap: () => AddAccountOptionsRoute().push<void>(context),
                ),
              SwitchAccountModalList(
                enableAccountManagement: enableAccountManagement,
              ),
              if (enableAccountManagement && currentPubkey != null)
                ModalActionButton(
                  icon: Assets.svg.iconMenuLogout.icon(size: 24.0.s),
                  label: context.i18n.profile_log_out(
                    withPrefix(
                      input: userMetadataValue?.data.name,
                      textDirection: Directionality.of(context),
                    ),
                  ),
                  onTap: () => ConfirmLogoutRoute(pubkey: currentPubkey).push<void>(context),
                ),
              ScreenBottomOffset(margin: 32.0.s),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAccountOptionsModal extends ConsumerWidget {
  const _AddAccountOptionsModal({
    required this.enableAccountManagement,
  });

  final bool enableAccountManagement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              onBackPress: () => context.pop(true),
              title: Text(context.i18n.profile_create_new_account),
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.small(
              child: SeparatedColumn(
                separator: SizedBox(height: 9.0.s),
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModalActionButton(
                    icon: Assets.svg.iconAccount.icon(
                      color: context.theme.appColors.primaryAccent,
                    ),
                    label: context.i18n.profile_log_in_existing_account,
                    onTap: () => _onLogInTap(context, ref),
                  ),
                  ModalActionButton(
                    icon: Assets.svg.iconChannelType.icon(
                      color: context.theme.appColors.primaryAccent,
                    ),
                    label: context.i18n.profile_create_a_new_account,
                    onTap: () => _onCreateAccountTap(context, ref),
                  ),
                ],
              ),
            ),
            ScreenBottomOffset(margin: 48.0.s),
          ],
        ),
      ),
    );
  }

  Future<void> _onLogInTap(BuildContext context, WidgetRef ref) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    await ref.read(switchAccountModalNotifierProvider.notifier).clearCurrentUserForAuthentication();
    if (rootContext.mounted) {
      GetStartedRoute().go(rootContext);
    }
  }

  Future<void> _onCreateAccountTap(BuildContext context, WidgetRef ref) async {
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final registrationRestrictionType = await ref.read(registrationRestrictionProvider.future);
    await ref.read(switchAccountModalNotifierProvider.notifier).clearCurrentUserForAuthentication();
    if (rootContext.mounted) {
      GetStartedRoute().go(rootContext);
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!rootContext.mounted) {
      return;
    }
    switch (registrationRestrictionType) {
      case RegistrationRestrictionType.fullyAllowed:
        final result = await SignUpPasskeyRoute().push<bool>(rootContext);
        if (result == null || result) {
          return;
        }
        if (rootContext.mounted) {
          await SignUpPasswordRoute().push<void>(rootContext);
        }
      case RegistrationRestrictionType.earlyAccessOnly:
        await SignUpEarlyAccessRoute().push<void>(rootContext);
      case RegistrationRestrictionType.restricted:
        await SignUpRestrictedRoute().push<void>(rootContext);
    }
  }
}
