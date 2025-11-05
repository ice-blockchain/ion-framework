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
    required this.onPress,
    this.selectedValue,
    super.key,
  });

  final String iconAsset;
  final String title;
  final String? selectedValue;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textTheme = context.theme.appTextThemes;

    final hasSelection = selectedValue != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.strokeElements),
        borderRadius: BorderRadius.circular(16.0.s),
        color: colors.secondaryBackground,
      ),
      child: ListItem(
        contentPadding: EdgeInsetsDirectional.only(
          end: 8.0.s,
        ),
        title: Text(
          title,
          style: textTheme.body
              .copyWith(color: hasSelection ? colors.primaryText : colors.tertiaryText),
        ),
        backgroundColor: Colors.transparent,
        leading: TextInputIcons(
          hasRightDivider: true,
          icons: [iconAsset.icon(color: colors.secondaryText)],
        ),
        onTap: onPress,
        trailing: Row(
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
        ),
      ),
    );
  }
}
