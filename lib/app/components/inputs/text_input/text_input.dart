// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/inputs/text_input/components/text_field_context_menu.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_decoration.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class TextInput extends HookWidget {
  TextInput({
    super.key,
    this.controller,
    this.validator,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.labelText,
    this.initialValue,
    this.errorText,
    this.maxLines = 1,
    this.minLines,
    this.verified = false,
    this.enabled = true,
    this.numbersOnly = false,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onValidated,
    this.onFocused,
    this.maxLength,
    this.isLive = false,
    this.alwaysShowPrefixIcon = false,
    this.obscureText = false,
    this.onTapOutside,
    this.color,
    this.disabledBorder,
    this.fillColor,
    this.labelColor,
    this.floatingLabelColor,
    this.autoValidateMode,
    EdgeInsetsDirectional? scrollPadding,
    EdgeInsetsGeometry? contentPadding,
  })  : scrollPadding = scrollPadding ?? EdgeInsetsDirectional.all(20.0.s),
        contentPadding =
            contentPadding ?? EdgeInsets.symmetric(vertical: 13.0.s, horizontal: 16.0.s);

  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  final String? labelText;
  final String? errorText;
  final String? initialValue;

  final int? maxLines;
  final int? minLines;

  final bool enabled;
  final bool verified;
  final bool numbersOnly;

  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final EdgeInsetsDirectional scrollPadding;
  final EdgeInsetsGeometry contentPadding;

  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onValidated;
  final ValueChanged<bool>? onFocused;
  final bool alwaysShowPrefixIcon;
  final int? maxLength;
  final bool isLive;
  final bool obscureText;

  final Color? color;
  final InputBorder? disabledBorder;
  final Color? fillColor;
  final Color? labelColor;
  final Color? floatingLabelColor;

  final TapRegionCallback? onTapOutside;
  final AutovalidateMode? autoValidateMode;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final error = useState<String?>(null);
    final hasValue = useState(initialValue.isNotEmpty || (controller?.text.isNotEmpty ?? false));
    final hasFocus = useNodeFocused(focusNode);

    useOnInit(
      () {
        onFocused?.call(hasFocus.value);
      },
      [hasFocus.value],
    );

    String? validate(String? value) {
      final validatorError = validator?.call(value);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        error.value = validatorError;
        onValidated?.call(validatorError == null);
      });
      return validatorError;
    }

    void onChangedHandler(String text) {
      hasValue.value = text.isNotEmpty;
      onChanged?.call(text);
      if (isLive) {
        validate(text);
      }
    }

    return TextFormField(
      scrollPadding: scrollPadding.resolve(Directionality.of(context)),
      controller: controller,
      focusNode: focusNode,
      onChanged: onChangedHandler,
      onTapOutside: onTapOutside,
      initialValue: initialValue,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      textInputAction: textInputAction,
      keyboardType: numbersOnly ? TextInputType.number : keyboardType,
      inputFormatters: numbersOnly
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ]
          : inputFormatters,
      style: context.theme.appTextThemes.body.copyWith(
        color: color ?? context.theme.appColors.primaryText,
      ),
      cursorErrorColor: context.theme.appColors.primaryAccent,
      cursorColor: context.theme.appColors.primaryAccent,
      maxLength: maxLength,
      obscureText: obscureText,
      obscuringCharacter: '*',
      validator: validate,
      autovalidateMode: autoValidateMode,
      contextMenuBuilder: buildTextFieldContextMenu,
      decoration: TextInputDecoration(
        context: context,
        verified: verified,
        prefix: prefix,
        prefixIcon:
            alwaysShowPrefixIcon || (!hasFocus.value && !hasValue.value) ? prefixIcon : null,
        suffixIcon: suffixIcon,
        errorText: errorText ?? error.value,
        contentPadding: contentPadding,
        labelText: errorText.isNotEmpty
            ? errorText
            : error.value.isNotEmpty
                ? error.value
                : labelText,
        disabledBorder: disabledBorder,
        fillColor: fillColor,
        labelColor: labelColor,
        floatingLabelColor: floatingLabelColor,
      ),
    );
  }
}
