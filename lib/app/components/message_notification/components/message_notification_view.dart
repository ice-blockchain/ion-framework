import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ion/app/extensions/extensions.dart';

class MessageNotificationView extends StatelessWidget {
  const MessageNotificationView({
    required this.icon,
    required this.message,
    super.key,
  });

  final SvgPicture? icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.0.s,
      decoration: BoxDecoration(
        color: context.theme.appColors.primaryAccent,
        borderRadius: BorderRadius.circular(12.0.s),
        boxShadow: [
          BoxShadow(
            color: context.theme.appColors.primaryAccent.withValues(alpha: 0.36),
            blurRadius: 20.0.s,
            spreadRadius: 0.0.s,
          ),
        ],
      ),
    );
  }
}
