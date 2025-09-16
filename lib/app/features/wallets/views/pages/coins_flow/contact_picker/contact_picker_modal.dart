// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/pages/user_picker_sheet/user_picker_sheet.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/contact_wallet_error_modals.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

enum ContactPickerValidatorType { none, networkWallet }

class ContactPickerModal extends HookConsumerWidget {
  const ContactPickerModal({
    super.key,
    this.networkId,
    this.validatorType = ContactPickerValidatorType.none,
  });

  final String? networkId;
  final ContactPickerValidatorType validatorType;

  String? _getWalletAddress(UserMetadataEntity? metadata, String networkId) {
    final wallets = metadata?.data.wallets;
    final address = wallets?[networkId];
    return address;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validator = useCallback(
      (
        WidgetRef ref,
        BuildContext context,
        UserMetadataEntity user,
      ) async {
        if (validatorType == ContactPickerValidatorType.none || networkId == null) return true;

        final network = await ref.read(networkByIdProvider(networkId!).future);
        if (network == null) return false;

        final isPrivateWallets = user.data.wallets == null;
        final walletAddress = _getWalletAddress(user, network.id) ??
            _getWalletAddress(
              await ref.read(userMetadataProvider(user.masterPubkey, cache: false).future),
              network.id,
            );

        if (walletAddress != null) return true;

        if (context.mounted) {
          unawaited(
            showContactWalletError(
              ref.context,
              user: user,
              network: network,
              isPrivate: isPrivateWallets,
            ),
          );
        }

        return false;
      },
      [validatorType, networkId],
    );

    return SheetContent(
      topPadding: 0,
      body: UserPickerSheet(
        controlPrivacy: true,
        navigationBar: NavigationAppBar.modal(
          title: Text(context.i18n.friends_modal_title),
          actions: const [NavigationCloseButton()],
        ),
        onUserSelected: (user) async {
          if (await validator(ref, context, user) && context.mounted) {
            context.pop(user.masterPubkey);
          }
        },
      ),
    );
  }
}
