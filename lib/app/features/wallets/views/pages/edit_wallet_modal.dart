// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_clear_button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/providers/update_wallet_view_provider.r.dart';
import 'package:ion/app/features/wallets/providers/wallet_view_data_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class EditWalletModal extends HookConsumerWidget {
  const EditWalletModal({required this.walletId, super.key});

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletView = ref.watch(walletViewByIdProvider(id: walletId)).valueOrNull;

    if (walletView == null) {
      return const SizedBox.shrink();
    }

    final walletName = useState(walletView.name);
    final controller = useTextEditingController(text: walletName.value);
    final isNameChanged = walletName.value != (walletView.name) && walletName.value.isNotEmpty;
    final walletCanBeRemoved = !walletView.isMainWalletView;

    return SheetContent(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_edit),
              actions: const [NavigationCloseButton()],
            ),
            ScreenSideOffset.small(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: 21.0.s, bottom: 24.0.s),
                child: TextInput(
                  onChanged: (String newValue) => walletName.value = newValue,
                  controller: controller,
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
                child: isNameChanged || !walletCanBeRemoved
                    ? Button(
                        disabled: !isNameChanged,
                        onPressed: () {
                          ref.read(updateWalletViewNotifierProvider.notifier).updateWalletView(
                                walletView: walletView,
                                updatedName: walletName.value,
                              );
                          context.pop();
                        },
                        label: Text(context.i18n.button_save),
                        mainAxisSize: MainAxisSize.max,
                      )
                    : Button(
                        onPressed: () {
                          DeleteWalletRoute(walletId: walletId).replace(context);
                        },
                        leadingIcon: Assets.svg.iconBlockDelete
                            .icon(color: context.theme.appColors.onPrimaryAccent),
                        label: Text(context.i18n.wallet_delete),
                        mainAxisSize: MainAxisSize.max,
                        backgroundColor: context.theme.appColors.attentionRed,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
