import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';

class OutlinedNotificationIcon extends StatelessWidget {
  const OutlinedNotificationIcon({
    required this.size,
    required this.asset,
    required this.backgroundColor,
    super.key,
  });

  final double size;
  final String asset;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(6.0.s),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.0.s),
      ),
      child: asset.icon(size: 18.0.s, color: context.theme.appColors.secondaryBackground),
    );
  }
}
