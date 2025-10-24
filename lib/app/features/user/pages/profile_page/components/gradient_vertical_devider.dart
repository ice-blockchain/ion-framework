import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/extensions.dart';

class GradientVerticalDevider extends StatelessWidget {
  const GradientVerticalDevider({super.key});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.40,
      child: Container(
        height: 25.0.s,
        width: 0.5.s,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0x00ffffff),
              Color(0xccffffff),
              Color(0x00ffffff),
            ],
          ),
        ),
      ),
    );
  }
}
