// SPDX-License-Identifier: ice License 1.0

part of '../list_item.dart';

class _ListItemTokenCreator extends ListItem {
  _ListItemTokenCreator({
    required Widget title,
    required Widget subtitle,
    super.key,
    super.border,
    super.trailingPadding,
    super.backgroundColor,
    super.onTap,
    super.trailing,
    Widget? leading,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? leadingPadding,
    BoxConstraints? constraints,
    bool verifiedBadge = false,
    String? avatarUrl,
    double? avatarSize,
  }) : super(
          leading: leading ??
              Avatar(
                imageWidget: avatarUrl != null
                    ? IonNetworkImage(
                        imageUrl: avatarUrl,
                        height: avatarSize ?? ListItem.defaultAvatarSize,
                        width: avatarSize ?? ListItem.defaultAvatarSize,
                      )
                    : DefaultAvatar(size: avatarSize ?? ListItem.defaultAvatarSize),
                size: avatarSize ?? ListItem.defaultAvatarSize,
                borderRadius: borderRadius,
                fit: BoxFit.cover,
              ),
          borderRadius: borderRadius ?? BorderRadius.zero,
          contentPadding: contentPadding ?? EdgeInsets.zero,
          leadingPadding: leadingPadding ?? EdgeInsetsDirectional.only(end: 8.0.s),
          constraints: constraints ?? const BoxConstraints(),
          title: Row(
            children: [
              Flexible(child: title),
              if (verifiedBadge)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 4.0.s),
                  child: Assets.svg.iconBadgeVerify.icon(size: defaultBadgeSize),
                ),
            ],
          ),
          subtitle: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: subtitle),
            ],
          ),
        );

  static double get defaultBadgeSize => 16.0.s;

  @override
  Color _getBackgroundColor(BuildContext context) {
    return backgroundColor ?? Colors.transparent;
  }

  @override
  TextStyle _getDefaultTitleStyle(BuildContext context) {
    return context.theme.appTextThemes.subtitle3.copyWith(
      color: context.theme.appColors.primaryText,
    );
  }

  @override
  TextStyle _getDefaultSubtitleStyle(BuildContext context) {
    return context.theme.appTextThemes.caption.copyWith(
      color: context.theme.appColors.tertiaryText,
    );
  }
}
