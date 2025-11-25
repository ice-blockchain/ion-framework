// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/inputs/hooks/use_text_changed.dart';
import 'package:ion/app/components/inputs/search_input/components/cancel_button.dart';
import 'package:ion/app/components/inputs/search_input/components/search_clear_button.dart';
import 'package:ion/app/components/inputs/search_input/components/search_loading_indicator.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/extensions/asset_gen_image.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/extensions/num.dart';
import 'package:ion/app/extensions/theme_data.dart';
import 'package:ion/generated/assets.gen.dart';

class SearchInput extends HookWidget {
  const SearchInput({
    super.key,
    this.onTextChanged,
    this.loading = false,
    this.onCancelSearch,
    this.defaultValue = '',
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.showCancelButton = true,
    this.onTap,
    this.hintText,
    FocusNode? focusNode,
    TextEditingController? controller,
  })  : externalFocusNode = focusNode,
        externalController = controller;

  static double get height => 40.0.s;

  final void Function(String)? onTextChanged;
  final VoidCallback? onCancelSearch;
  final bool loading;
  final bool showCancelButton;
  final String defaultValue;
  final FocusNode? externalFocusNode;
  final TextEditingController? externalController;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final ValueSetter<String>? onTap;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final searchController = externalController ?? useTextEditingController(text: defaultValue);
    final focusNode = externalFocusNode ?? useFocusNode();

    final showClear = useState(false);
    final focused = useNodeFocused(focusNode);

    useTextChanged(
      controller: searchController,
      onTextChanged: (String text) {
        onTextChanged?.call(text);
        showClear.value = text.isNotEmpty;
      },
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: height,
            child: IonTextField(
              onTap: () => onTap?.call(searchController.text),
              focusNode: focusNode,
              style: context.theme.appTextThemes.body.copyWith(
                color: context.theme.appColors.primaryText,
              ),
              cursorColor: context.theme.appColors.primaryAccent,
              decoration: InputDecoration(
                isCollapsed: true,
                isDense: true,
                contentPadding: EdgeInsets.all(11.0.s),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: context.theme.appColors.primaryBackground,
                  ),
                  borderRadius: BorderRadius.circular(16.0.s),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: context.theme.appColors.primaryAccent,
                  ),
                  borderRadius: BorderRadius.circular(16.0.s),
                ),
                hintText: hintText ?? context.i18n.search_placeholder,
                hintStyle: context.theme.appTextThemes.body.copyWith(
                  color: context.theme.appColors.tertiaryText,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsetsDirectional.only(start: 12.0.s, end: 2.0.s),
                  child: Assets.svg.iconFieldSearch.icon(
                    color: context.theme.appColors.tertiaryText,
                    size: 16.0.s,
                  ),
                ),
                suffixIcon: suffix ??
                    (loading
                        ? const SearchLoadingIndicator()
                        : showClear.value
                            ? TextFieldTapRegion(
                                child: SearchClearButton(onPressed: searchController.clear),
                              )
                            : null),
                prefixIconConstraints: const BoxConstraints(),
                filled: true,
                fillColor: context.theme.appColors.primaryBackground,
              ),
              controller: searchController,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
            ),
          ),
        ),
        if (focused.value && showCancelButton)
          TextFieldTapRegion(
            child: SearchCancelButton(
              onPressed: () {
                onCancelSearch?.call();
                focusNode.unfocus();
              },
            ),
          ),
      ],
    );
  }
}
