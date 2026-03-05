// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/text_input/components/paste_suffix_button.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/select/select_network_button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/components/disabled_input_field.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/components/token_already_exists_dialog.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/components/token_not_found_dialog.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/providers/token_already_exists_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/providers/token_data_notifier_provider.r.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/providers/token_form_notifier_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/router/utils/show_simple_bottom_sheet.dart';
import 'package:ion/app/services/clipboard/clipboard.dart';

class ImportTokenForm extends HookConsumerWidget {
  const ImportTokenForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdditionalInputFieldsEnabled = useState(false);
    final tokenAddressController = useTextEditingController();
    final tokenSymbolController = useTextEditingController();
    final tokenDecimalsController = useTextEditingController();
    final selectedNetwork = ref.watch(tokenFormNotifierProvider.select((state) => state.network));

    ref
      ..listen(tokenDataNotifierProvider, (previous, next) {
        final token = next.valueOrNull;
        final decimals = token?.decimals ?? 0;
        final decimalsString = decimals == 0 ? '' : decimals.toString();

        tokenSymbolController.text = token?.abbreviation ?? '';
        tokenDecimalsController.text = decimalsString;

        if (tokenAddressController.text.isNotEmpty && !next.isLoading) {
          if (isTokenNotFound(token)) {
            if (context.mounted) {
              showSimpleBottomSheet<void>(
                context: context,
                child: const TokenNotFoundDialog(),
              );
            }
            isAdditionalInputFieldsEnabled.value = true;
          }
        }
      })
      ..listenSuccess(
        tokenAlreadyExistsProvider,
        (exists) => _onTokenAlreadyExists(context, exists: exists ?? false),
      );

    useEffect(
      () {
        void onTokenAddressChanged() {
          ref.read(tokenFormNotifierProvider.notifier).address = tokenAddressController.text;
          isAdditionalInputFieldsEnabled.value = false;
        }

        tokenAddressController.addListener(onTokenAddressChanged);
        return () => tokenAddressController.removeListener(onTokenAddressChanged);
      },
      [tokenAddressController],
    );

    useEffect(
      () {
        void onDecimalsChanged() {
          ref.read(tokenFormNotifierProvider.notifier).decimals =
              int.tryParse(tokenDecimalsController.text);
        }

        tokenDecimalsController.addListener(onDecimalsChanged);
        return () => tokenDecimalsController.removeListener(onDecimalsChanged);
      },
      [tokenDecimalsController],
    );

    useEffect(
      () {
        void onTokenSymbolChanged() {
          ref.read(tokenFormNotifierProvider.notifier).symbol = tokenSymbolController.text;
        }

        tokenSymbolController.addListener(onTokenSymbolChanged);
        return () => tokenSymbolController.removeListener(onTokenSymbolChanged);
      },
      [tokenSymbolController],
    );

    return Column(
      children: [
        SelectNetworkButton(
          selectedNetwork: selectedNetwork,
          onTap: () => _onNetworkPressed(ref),
        ),
        SizedBox(height: 16.0.s),
        TextInput(
          restorationId: 'import_token_address_input',
          labelText: context.i18n.wallet_import_token_address_label,
          controller: tokenAddressController,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          suffixIcon: PasteSuffixButton(
            onTap: () async {
              tokenAddressController.text = await getClipboardText();
              unawaited(ref.read(tokenDataNotifierProvider.notifier).fetchTokenData());
            },
          ),
          onFocused: (hasFocus) {
            if (!hasFocus) {
              ref.read(tokenDataNotifierProvider.notifier).fetchTokenData();
            }
          },
        ),
        SizedBox(height: 16.0.s),
        if (isAdditionalInputFieldsEnabled.value)
          TextInput(
            restorationId: 'import_token_symbol_input',
            labelText: context.i18n.wallet_import_token_symbol_label,
            controller: tokenSymbolController,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          )
        else
          DisabledTextInput(
            restorationId: 'import_token_symbol_disabled_input',
            labelText: context.i18n.wallet_import_token_symbol_label,
            controller: tokenSymbolController,
          ),
        SizedBox(height: 16.0.s),
        if (isAdditionalInputFieldsEnabled.value)
          TextInput(
            restorationId: 'import_token_decimals_input',
            keyboardType: TextInputType.number,
            labelText: context.i18n.wallet_import_token_decimals_label,
            controller: tokenDecimalsController,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
          )
        else
          DisabledTextInput(
            restorationId: 'import_token_decimals_disabled_input',
            labelText: context.i18n.wallet_import_token_decimals_label,
            controller: tokenDecimalsController,
          ),
      ],
    );
  }

  Future<void> _onNetworkPressed(WidgetRef ref) async {
    final newNetwork = await SelectNetworkForTokenRoute().push<NetworkData?>(ref.context);
    if (newNetwork != null) {
      ref.read(tokenFormNotifierProvider.notifier).network = newNetwork;
      unawaited(ref.read(tokenDataNotifierProvider.notifier).fetchTokenData());
    }
  }

  void _onTokenAlreadyExists(BuildContext context, {required bool exists}) {
    if (context.mounted && exists) {
      showSimpleBottomSheet<void>(
        context: context,
        child: const TokenAlreadyExistsDialog(),
      );
    }
  }

  bool isTokenNotFound(CoinData? token) =>
      token == null || token.name.isEmpty || token.abbreviation.isEmpty || token.decimals == 0;
}
