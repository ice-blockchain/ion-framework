// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/inputs/text_input/components/text_field_context_menu.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_decoration.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/logger/logger.dart';

class TextInput extends HookWidget {
  TextInput({
    super.key,
    this.restorationId,
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
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final error = useState<String?>(null);

    final hasValue = useState(
      initialValue.isNotEmpty || (controller?.text.isNotEmpty ?? false),
    );
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

    final useWrapper = restorationId != null && controller != null;

    Widget textFormField = TextFormField(
      restorationId: useWrapper ? null : restorationId,
      scrollPadding: scrollPadding.resolve(Directionality.of(context)),
      controller: controller,
      focusNode: focusNode,
      onChanged: onChangedHandler,
      onTapOutside: onTapOutside,
      initialValue: controller == null ? initialValue : null,
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

    if (useWrapper) {
      textFormField = _RestorableTextFieldWrapper(
        restorationId: restorationId!,
        controller: controller!,
        onHasValueChanged: (value) => hasValue.value = value,
        child: textFormField,
      );
    }

    return textFormField;
  }
}

class _RestorableTextFieldWrapper extends StatefulWidget {
  const _RestorableTextFieldWrapper({
    required this.restorationId,
    required this.controller,
    required this.onHasValueChanged,
    required this.child,
  });

  final String restorationId;
  final TextEditingController controller;
  final ValueChanged<bool> onHasValueChanged;
  final Widget child;

  @override
  State<_RestorableTextFieldWrapper> createState() =>
      _RestorableTextFieldWrapperState();
}

class _RestorableTextFieldWrapperState
    extends State<_RestorableTextFieldWrapper> with RestorationMixin {
  final _text = RestorableString('');

  @override
  String get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_text, 'text');
    if (_text.value.isNotEmpty && widget.controller.text != _text.value) {
      widget.controller.text = _text.value;
      widget.onHasValueChanged(true);
      Logger.log(
        '[StateRestoration] TextInput restored: '
        'id=$restorationId, text=${_text.value}',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller.text.isNotEmpty) {
      _text.value = widget.controller.text;
    }
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(_RestorableTextFieldWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _text.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_text.value != widget.controller.text) {
      _text.value = widget.controller.text;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
