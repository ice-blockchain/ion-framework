// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/components/import_token_form.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/components/security_risks.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/providers/import_token_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/providers/token_form_notifier_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class ImportTokenPage extends HookConsumerWidget {
  const ImportTokenPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = useState(false);

    ref
      ..displayErrors(importTokenNotifierProvider)
      ..listenSuccess(importTokenNotifierProvider, (_) => _onTokenImported(context))
      ..listen(tokenFormNotifierProvider, (_, next) => isFormValid.value = next.canBeImported);

    final isButtonDisabled = !isFormValid.value || ref.watch(importTokenNotifierProvider).isLoading;

    return KeyboardVisibilityProvider(
      child: SheetContent(
        body: Column(
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_import_token_title),
            ),
            Expanded(
              child: ScreenSideOffset.small(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      child: SingleChildScrollView(
                        restorationId: 'wallet_import_token_page_scroll',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ImportTokenForm(),
                            SecurityRisks(),
                          ],
                        ),
                      ),
                    ),
                    Button(
                      onPressed: () => ref.read(importTokenNotifierProvider.notifier).importToken(),
                      label: Text(context.i18n.wallet_import_token_import_button),
                      type: isButtonDisabled ? ButtonType.disabled : ButtonType.primary,
                      disabled: isButtonDisabled,
                      leadingIcon: Assets.svg.iconImportcoin.icon(),
                      trailingIcon: ref.watch(importTokenNotifierProvider).isLoading
                          ? const IONLoadingIndicator()
                          : null,
                    ),
                    ScreenBottomOffset(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTokenImported(BuildContext context) {
    if (context.mounted) {
      context.go(WalletRoute().location);
    }
  }
}
