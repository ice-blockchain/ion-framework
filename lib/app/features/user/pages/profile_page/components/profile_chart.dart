import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/generated/assets.gen.dart';

enum ProfileChartType {
  raising,
  falling,
}

class ProfileChart extends StatelessWidget {
  const ProfileChart({
    required this.type,
    required this.amount,
    super.key,
  });

  final ProfileChartType type;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ProfileChartType.raising => const Color(0xFF00FF00),
      ProfileChartType.falling => const Color(0xFFFF396E),
    };

    return Container(
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.53.s),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconChartLine,
              width: 24.0.s,
              height: 24.0.s,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 4.0.s),
            Expanded(
              child: Text(
                amount.toString(),
                style: context.theme.appTextThemes.body2.copyWith(
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
