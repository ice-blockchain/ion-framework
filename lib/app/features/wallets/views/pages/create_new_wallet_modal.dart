// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_clear_button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/providers/create_wallet_view_provider.r.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';

class CreateNewWalletModal extends HookConsumerWidget {
  const CreateNewWalletModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletName = useState('');
    final controller = useTextEditingController();

    final isCreating = ref.watch(createWalletViewNotifierProvider).isLoading;

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_create_new),
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.small(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: 21.0.s, bottom: 24.0.s),
                child: TextInput(
                  controller: controller,
                  onChanged: (String newValue) => walletName.value = newValue,
                  labelText: context.i18n.wallet_name,
                  suffixIcon: walletName.value.isEmpty
                      ? null
                      : TextInputIcons(
                          icons: [
                            TextInputClearButton(
                              controller: controller,
                            ),
                          ],
                        ),
                ),
              ),
            ),
            ScreenBottomOffset(
              child: ScreenSideOffset.small(
                child: Button(
                  onPressed: () async {
                    if (walletName.value.isEmpty) {
                      return;
                    }
                    await ref
                        .read(createWalletViewNotifierProvider.notifier)
                        .createWalletView(name: walletName.value);

                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  trailingIcon: isCreating ? const IONLoadingIndicator() : null,
                  label: Text(context.i18n.wallet_create),
                  disabled: walletName.value.isEmpty || isCreating,
                  mainAxisSize: MainAxisSize.max,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
