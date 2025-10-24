import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/views/components/pump_ion/pump_ion_bought.dart';
import 'package:ion/app/utils/num.dart';
import 'package:ion/generated/assets.gen.dart';

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

    final symbol = switch (type) {
      ProfileChartType.raising => r'+$',
      ProfileChartType.falling => r'-$',
    };

    return Container(
      decoration: ShapeDecoration(
        color: context.theme.appColors.primaryBackground.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0.s),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0.s, vertical: 4.0.s),
        child: Row(
          children: [
            SvgPicture.asset(
              Assets.svg.iconChartLine,
              width: 14.0.s,
              height: 14.0.s,
              colorFilter: ColorFilter.mode(
                color,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 4.0.s),
            Text(
              formatToCurrency(amount, symbol),
              style: context.theme.appTextThemes.body2.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
