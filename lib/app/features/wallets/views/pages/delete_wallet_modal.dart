// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/rounded_card.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/app/features/wallets/providers/delete_wallet_view_provider.r.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class DeleteWalletModal extends HookConsumerWidget {
  const DeleteWalletModal({required this.walletId, super.key});

  final String walletId;

  static double get buttonsSize => 56.0.s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonMinimalSize = Size(buttonsSize, buttonsSize);

    final isDeleting =
        ref.watch(deleteWalletViewNotifierProvider(walletViewId: walletId)).isLoading;

    final isConfirmed = useState(false);

    return SheetContent(
      body: ScreenSideOffset.small(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: 31.0.s, bottom: 4.0.s),
              child: Assets.svg.actionWalletDelete.icon(size: 80.0.s),
            ),
            Text(
              context.i18n.wallet_delete_q,
              style: context.theme.appTextThemes.title.copyWith(
                color: context.theme.appColors.primaryText,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: 8.0.s,
                start: 36.0.s,
                end: 36.0.s,
              ),
              child: Text(
                context.i18n.wallet_delete_message,
                style: context.theme.appTextThemes.body2.copyWith(
                  color: context.theme.appColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(vertical: 16.0.s),
              child: IgnorePointer(
                ignoring: isDeleting,
                child: _ConfirmDeleteCheckbox(
                  selected: isConfirmed.value,
                  onChanged: (selected) => isConfirmed.value = selected,
                ),
              ),
            ),
            ScreenBottomOffset(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Button.compact(
                      type: ButtonType.outlined,
                      label: Text(
                        context.i18n.button_cancel,
                      ),
                      onPressed: () {
                        context.maybePop();
                      },
                      minimumSize: buttonMinimalSize,
                    ),
                  ),
                  SizedBox(
                    width: 15.0.s,
                  ),
                  Expanded(
                    child: Button.compact(
                      label: Text(context.i18n.button_delete),
                      disabled: isDeleting || !isConfirmed.value,
                      type: isConfirmed.value ? ButtonType.primary : ButtonType.disabled,
                      trailingIcon: isDeleting ? const IONLoadingIndicator() : null,
                      onPressed: () async {
                        await ref
                            .read(deleteWalletViewNotifierProvider(walletViewId: walletId).notifier)
                            .delete();

                        if (context.mounted) {
                          context.maybePop();
                        }
                      },
                      minimumSize: buttonMinimalSize,
                      backgroundColor:
                          isConfirmed.value ? context.theme.appColors.attentionRed : null,
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

class _ConfirmDeleteCheckbox extends StatelessWidget {
  const _ConfirmDeleteCheckbox({
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!selected),
      child: RoundedCard.filled(
        padding: EdgeInsets.all(12.0.s),
        child: Row(
          children: [
            if (selected)
              Assets.svg.iconBlockCheckboxOn.icon()
            else
              Assets.svg.iconBlockCheckboxOff.icon(),
            SizedBox(width: 10.0.s),
            Flexible(
              child: Text(
                context.i18n.wallet_delete_confirmation,
                style: context.theme.appTextThemes.body2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
