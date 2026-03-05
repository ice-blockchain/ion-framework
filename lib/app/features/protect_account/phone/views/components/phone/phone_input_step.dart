// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/inputs/hooks/use_text_changed.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_clear_button.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/constants/countries.f.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/protect_account/phone/provider/country_provider.r.dart';
import 'package:ion/app/features/protect_account/phone/views/components/countries/country_code_input.dart';
import 'package:ion/app/features/protect_account/secure_account/providers/request_twofa_code_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/utils/formatters.dart';
import 'package:ion/app/utils/validators.dart';

class PhoneInputStep extends HookConsumerWidget {
  const PhoneInputStep({
    required this.onNext,
    this.restorationId = 'phone_setup_input',
    super.key,
  });

  final void Function(String phone) onNext;
  final String restorationId;

  static const int minPhoneLength = 5;
  static const int maxPhoneLength = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.i18n;
    final formKey = useRef(GlobalKey<FormState>());
    final phoneController = useTextEditingController();
    final showClear = useState(false);

    final country = ref.watch(selectedCountryProvider);
    final isRequestingCode =
        ref.watch(requestTwoFaCodeNotifierProvider.select((state) => state.isLoading));

    useTextChanged(
      controller: phoneController,
      onTextChanged: (String text) {
        showClear.value = text.isNotEmpty;
      },
    );

    String? validatePhoneNumber(BuildContext context, String? countryCode, String? phoneNumber) {
      if (!Validators.isValidPhoneNumber(countryCode, phoneNumber)) {
        return context.i18n.phone_number_invalid;
      }
      return null;
    }

    return Form(
      key: formKey.value,
      child: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return ScreenSideOffset.large(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isKeyboardVisible) SizedBox(height: 58.0.s),
                const Spacer(),
                Padding(
                  padding: EdgeInsetsDirectional.only(bottom: 20.0.s),
                  child: TextInput(
                    restorationId: restorationId,
                    alwaysShowPrefixIcon: true,
                    prefix: Text('${country.iddCode} '),
                    prefixIcon: CountryCodeInput(
                      country: country,
                      onTap: () async {
                        final data = await SelectCountriesRoute().push<Country>(context);

                        if (data != null) {
                          ref.read(selectedCountryProvider.notifier).country = data;
                        }
                      },
                    ),
                    suffixIcon:
                        showClear.value ? TextInputClearButton(controller: phoneController) : null,
                    labelText: context.i18n.phone_number,
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (phone) => validatePhoneNumber(context, country.iddCode, phone),
                    textInputAction: TextInputAction.done,
                    numbersOnly: true,
                  ),
                ),
                const Spacer(),
                ScreenBottomOffset(
                  margin: 48.0.s,
                  child: Button(
                    mainAxisSize: MainAxisSize.max,
                    label: Text(locale.button_next),
                    disabled: isRequestingCode,
                    trailingIcon: isRequestingCode ? const IONLoadingIndicator() : null,
                    onPressed: () async {
                      final isFormValid = formKey.value.currentState?.validate() ?? false;
                      if (!isFormValid) {
                        return;
                      }

                      final phoneNumber = formatPhoneNumber(
                        country.iddCode,
                        phoneController.text.trim(),
                      );

                      onNext(phoneNumber);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
