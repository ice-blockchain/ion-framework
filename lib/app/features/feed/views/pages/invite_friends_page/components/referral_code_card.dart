// SPDX-License-Identifier: ice License 1.0

part of '../invite_friends_page.dart';

class _ReferralCodeCard extends HookWidget {
  const _ReferralCodeCard({required this.referralCode});

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    final isCopied = useState<bool>(false);
    final tooltipLeftPosition = useState<double>(0);
    final tooltipTopPosition = useState<double>(0);

    final copyIconWidth = 16.0.s;

    useEffect(
      () {
        Timer? timer;

        if (isCopied.value) {
          timer = Timer(const Duration(seconds: 3), () {
            isCopied.value = false;
          });
        }

        return () {
          timer?.cancel();
        };
      },
      [isCopied.value],
    );

    return _IonCard(
      padding: EdgeInsets.symmetric(horizontal: 60.0.s, vertical: 22.0.s),
      child: Column(
        spacing: 10.0.s,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6.0.s,
            children: [
              Assets.svg.iconRecoveryCode.icon(
                size: 20.0.s,
                color: context.theme.appColors.secondaryText,
              ),
              Text(
                context.i18n.invite_friends_referral_code_label,
                style: context.theme.appTextThemes.subtitle3.copyWith(
                  color: context.theme.appColors.onTertiaryBackground,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              copyToClipboard(referralCode);

              isCopied.value = true;
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4.0.s,
              children: [
                Text(
                  referralCode,
                  style: context.theme.appTextThemes.subtitle.copyWith(
                    color: context.theme.appColors.primaryText,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Assets.svg.iconBlockCopyBlue.icon(
                      size: copyIconWidth,
                      color: context.theme.appColors.primaryAccent,
                    ),
                    PositionedDirectional(
                      top: tooltipTopPosition.value,
                      start: tooltipLeftPosition.value,
                      child: Opacity(
                        opacity: isCopied.value ? 1 : 0,
                        child: CopiedTooltip(
                          onLayout: (Size size) {
                            tooltipTopPosition.value = -size.height - 11.0.s;
                            tooltipLeftPosition.value = (copyIconWidth - size.width) / 2;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
