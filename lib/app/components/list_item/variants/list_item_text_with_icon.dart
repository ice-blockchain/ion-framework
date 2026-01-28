// SPDX-License-Identifier: ice License 1.0

part of '../list_item.dart';

class _ListItemTextWithIcon extends ListItem {
  _ListItemTextWithIcon({
    String? value,
    Widget? icon,
    super.secondary,
    super.title,
    super.key,
    super.backgroundColor,
    EdgeInsetsGeometry? contentPadding,
    BoxConstraints? constraints,
  }) : super(
          trailing: _TrailingTextWithIcon(
            value: value,
            icon: icon,
            secondary: secondary,
          ),
          trailingPadding: EdgeInsets.zero,
          contentPadding: contentPadding ?? defaultTextContentPadding,
          constraints: constraints ?? const BoxConstraints(),
        );

  static EdgeInsets get defaultTextContentPadding => EdgeInsets.all(12.0.s);

  @override
  Color _getBackgroundColor(BuildContext context) {
    return context.theme.appColors.tertiaryBackground;
  }

  @override
  TextStyle _getDefaultTitleStyle(BuildContext context) {
    return context.theme.appTextThemes.caption3.copyWith(
      color: context.theme.appColors.secondaryText,
    );
  }
}

class _TrailingTextWithIcon extends StatelessWidget {
  const _TrailingTextWithIcon({
    this.value,
    this.icon,
    this.secondary,
  });

  final String? value;
  final Widget? icon;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: 8.0.s),
          ],
          if (value != null)
            Flexible(
              child: Text(
                value!,
                style: context.theme.appTextThemes.caption3.copyWith(height: 1),
              ),
            ),
        ],
      ),
    );
  }
}
