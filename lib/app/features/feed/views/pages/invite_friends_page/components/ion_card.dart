// SPDX-License-Identifier: ice License 1.0

part of '../invite_friends_page.dart';

class _IonCard extends StatelessWidget {
  const _IonCard({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.appColors.primaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Padding(
        padding: padding ?? EdgeInsetsDirectional.all(16.s),
        child: child,
      ),
    );
  }
}
