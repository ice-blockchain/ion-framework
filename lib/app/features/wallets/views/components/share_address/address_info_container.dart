// SPDX-License-Identifier: ice License 1.0

part of 'receive_info_card.dart';

class _AddressInfoContainer extends StatelessWidget {
  const _AddressInfoContainer({
    required this.title,
    required this.value,
    required this.onTapInfo,
    this.valueToCopy,
  });

  final String title;
  final String value;
  final String? valueToCopy;
  final VoidCallback onTapInfo;

  @override
  Widget build(BuildContext context) {
    return _ContainerWithBackground(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapInfo,
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: context.theme.appTextThemes.body,
                      ),
                      SizedBox(width: 4.s),
                      Assets.svg.iconBlockInformation.icon(
                        size: 14.s,
                        color: context.theme.appColors.primaryAccent,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.s),
                Text(
                  value,
                  style: context.theme.appTextThemes.body2.copyWith(
                    color: context.theme.appColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.s),
          CopyBuilder(
            defaultIcon: Assets.svg.iconBlockCopyBlue.icon(
              size: 20.s,
              color: context.theme.appColors.primaryText,
            ),
            defaultText: context.i18n.button_copy,
            defaultBorderColor: context.theme.appColors.onTertiaryFill,
            builder: (context, onCopy, content) => Button.icon(
              size: 36.s,
              icon: content.icon,
              borderColor: content.borderColor,
              borderRadius: BorderRadius.circular(12.s),
              onPressed: () => onCopy(valueToCopy ?? value),
              type: ButtonType.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
