// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/list_item/list_item.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

class GeneralSelectionButton extends StatelessWidget {
  const GeneralSelectionButton({
    required this.iconAsset,
    required this.title,
    this.onPress,
    this.selectedValue,
    this.enabled = true,
    super.key,
  });

  final String iconAsset;
  final String title;
  final String? selectedValue;
  final VoidCallback? onPress;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    final hasSelection = selectedValue != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: enabled ? Border.all(color: colors.strokeElements) : null,
        borderRadius: BorderRadius.circular(16.0.s),
        color: enabled ? colors.secondaryBackground : colors.primaryBackground,
      ),
      child: ListItem(
        contentPadding: EdgeInsetsDirectional.only(
          end: enabled ? 8.0.s : 16.0.s,
        ),
        leadingPadding: enabled
            ? ListItem.defaultLeadingPadding
            : EdgeInsetsDirectional.only(start: 16.0.s, end: 5.0.s),
        title: Text(
          title,
          style: textTheme.body
              .copyWith(color: hasSelection ? colors.primaryText : colors.tertiaryText),
        ),
        backgroundColor: Colors.transparent,
        leading: TextInputIcons(
          hasRightDivider: enabled,
          icons: [iconAsset.icon(color: colors.secondaryText)],
          minWidth: enabled ? null : 24.0.s,
        ),
        onTap: enabled ? onPress : null,
        trailing: enabled
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedValue != null)
                    Text(
                      selectedValue!,
                      style: textTheme.body.copyWith(color: colors.primaryAccent),
                    ),
                  GestureDetector(
                    onTap: onPress,
                    child: Padding(
                      padding: EdgeInsets.all(4.0.s),
                      child: Assets.svg.iconArrowRight.icon(color: colors.secondaryText),
                    ),
                  ),
                ],
              )
            : selectedValue != null
                ? Text(
                    selectedValue!,
                    textAlign: TextAlign.right,
                    style: textTheme.caption.copyWith(color: colors.primaryAccent),
                  )
                : null,
      ),
    );
  }
}
