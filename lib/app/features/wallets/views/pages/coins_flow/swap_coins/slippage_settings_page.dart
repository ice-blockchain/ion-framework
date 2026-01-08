// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/sheet_content/sheet_content.dart';
import 'package:ion/generated/assets.gen.dart';

class SlippageSettingsPage extends HookWidget {
  const SlippageSettingsPage({
    required this.slippage,
    required this.defaultSlippage,
    super.key,
  });

  final double slippage;
  final double defaultSlippage;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    final slippageValue = useState(slippage);

    return SheetContent(
      body: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12.0.s,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationAppBar.modal(
              title: Text(context.i18n.wallet_swap_slippage_settings_title),
            ),
            SizedBox(height: 8.0.s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.i18n.wallet_swap_slippage_settings_label,
                    style: textStyles.body,
                  ),
                  SizedBox(height: 8.0.s),
                  Text(
                    context.i18n.wallet_swap_slippage_settings_description,
                    style: textStyles.body.copyWith(color: colors.tertiaryText),
                  ),
                  SizedBox(height: 16.0.s),
                  _SlippageControls(
                    initialValue: slippage,
                    defaultSlippage: defaultSlippage,
                    onValueChanged: (value) {
                      slippageValue.value = value;
                    },
                  ),
                  SizedBox(height: 24.0.s),
                  Button(
                    onPressed: () {
                      Navigator.of(context).pop(slippageValue.value);
                    },
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.i18n.button_save),
                        SizedBox(width: 6.0.s),
                        const Icon(Icons.check_circle_outline, size: 16),
                      ],
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

class _SlippageControls extends HookConsumerWidget {
  const _SlippageControls({
    required this.initialValue,
    required this.defaultSlippage,
    required this.onValueChanged,
  });

  final double initialValue;
  final double defaultSlippage;
  final void Function(double value) onValueChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    final isAuto = useState(initialValue == defaultSlippage);
    final value = useState(initialValue);
    final textController = useTextEditingController(text: initialValue.toStringAsFixed(1));

    void setAuto({required bool isEnabled}) {
      isAuto.value = isEnabled;
      if (isEnabled) {
        value.value = defaultSlippage;
        textController.text = value.value.toStringAsFixed(1);
        onValueChanged(value.value);
      }
    }

    void changeValue(double delta) {
      isAuto.value = false;
      value.value = (value.value + delta).clamp(0.1, 99.9);
      textController.text = value.value.toStringAsFixed(1);
      onValueChanged(value.value);
    }

    void onTextChanged(String text) {
      // Normalize comma to dot for decimal parsing
      final normalizedText = text.replaceAll(',', '.');
      final parsed = double.tryParse(normalizedText);
      if (parsed == null) return;
      isAuto.value = false;
      value.value = parsed.clamp(0.1, 99.9);
      onValueChanged(value.value);
    }

    return SizedBox(
      height: 44.0.s,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Auto button
          Container(
            width: 100.0.s,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.0.s, vertical: 6.0.s),
            decoration: ShapeDecoration(
              color: colors.tertiaryBackground,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: isAuto.value ? colors.primaryAccent : colors.onTertiaryFill,
                ),
                borderRadius: BorderRadius.circular(12.0.s),
              ),
            ),
            child: GestureDetector(
              onTap: () => setAuto(isEnabled: true),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.i18n.wallet_swap_slippage_settings_auto,
                    style: textStyles.body.copyWith(
                      color: colors.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8.0.s),
          // Input container
          Expanded(
            child: Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.0.s, vertical: 6.0.s),
              decoration: ShapeDecoration(
                color: colors.tertiaryBackground,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: colors.onTertiaryFill,
                  ),
                  borderRadius: BorderRadius.circular(12.0.s),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decrement button
                  GestureDetector(
                    onTap: () => changeValue(-0.5),
                    child: Assets.svg.iconSwapMinus.icon(
                      size: 24.0.s,
                    ),
                  ),
                  // Percentage text with % symbol - centered
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IntrinsicWidth(
                          child: TextFormField(
                            controller: textController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.end,
                            style: textStyles.body.copyWith(
                              color: colors.primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: onTextChanged,
                          ),
                        ),
                        SizedBox(width: 2.0.s),
                        Text(
                          '%',
                          style: textStyles.body.copyWith(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Increment button
                  GestureDetector(
                    onTap: () => changeValue(0.5),
                    child: Assets.svg.iconSwapPlus.icon(
                      size: 24.0.s,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
