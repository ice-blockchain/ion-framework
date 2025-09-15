// SPDX-License-Identifier: ice License 1.0

part of '../list_item.dart';

class _ListItemPopup extends ListItem {
  _ListItemPopup({
    required Widget title,
    required Widget subtitle,
    super.key,
    super.trailing,
    super.leading,
    EdgeInsetsGeometry? leadingPadding,
  }) : super(
          leadingPadding: leadingPadding ?? EdgeInsetsDirectional.only(end: 8.0.s),
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Flexible(child: title),
            ],
          ),
          subtitle: subtitle,
        );

  @override
  Color _getBackgroundColor(BuildContext context) {
    return (isSelected ?? false)
        ? context.theme.appColors.primaryAccent
        : backgroundColor ?? Colors.transparent;
  }

  @override
  TextStyle _getDefaultTitleStyle(BuildContext context) {
    return context.theme.appTextThemes.subtitle3.copyWith(
      color: (isSelected ?? false)
          ? context.theme.appColors.onPrimaryAccent
          : context.theme.appColors.primaryText,
    );
  }

  @override
  TextStyle _getDefaultSubtitleStyle(BuildContext context) {
    return context.theme.appTextThemes.caption.copyWith(
      color: context.theme.appColors.quaternaryText,
    );
  }
}
