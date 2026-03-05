// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/components/screen_offset/screen_top_offset.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_back_button.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({required this.showBackButton, super.key});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenTopOffset(
        child: SingleChildScrollView(
          restorationId: 'user_profile_skeleton_scroll',
          child: Column(
            children: [
              if (showBackButton) _Header(showBackButton: showBackButton),
              Skeleton(
                child: Column(
                  children: [
                    _ProfileInfo(showBackButton: showBackButton),
                    SizedBox(height: 12.0.s),
                    const _Divider(),
                    const _AdditionalInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({required this.showBackButton});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: Column(
        children: [
          if (!showBackButton)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 12.0.s),
                  child: _SkeletonBox.square(size: 24.0.s, borderRadius: 8.0.s),
                ),
                _SkeletonBox.square(size: 65.0.s),
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 12.0.s),
                  child: _SkeletonBox.square(size: 24.0.s, borderRadius: 8.0.s),
                ),
              ],
            ),
          SizedBox(height: 16.0.s),
          _SkeletonBox(
            width: 320.0.s,
            height: 20.0.s,
            borderRadius: 8.0.s,
          ),
          SizedBox(height: 6.0.s),
          _SkeletonBox(
            width: 280.0.s,
            height: 16.0.s,
          ),
          SizedBox(height: 12.0.s),
          _SkeletonBox(
            width: 120.0.s,
            height: 28.0.s,
          ),
          SizedBox(height: 16.0.s),
          const _ProfileDetails(),
        ],
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails();

  @override
  Widget build(BuildContext context) {
    final items = [
      _SkeletonBox(width: 343.0.s, height: 36.0.s),
      SizedBox(height: 12.0.s),
      _SkeletonBox(width: 218.0.s, height: 16.0.s),
      SizedBox(height: 32.0.s),
      Row(
        children: [
          _SkeletonBox(
            width: 80.0.s,
            height: 20.0.s,
            borderRadius: 8.0.s,
          ),
          SizedBox(width: 24.0.s),
          _SkeletonBox(
            width: 80.0.s,
            height: 20.0.s,
            borderRadius: 8.0.s,
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4.0.s,
      color: Colors.white,
    );
  }
}

class _AdditionalInfo extends StatelessWidget {
  const _AdditionalInfo();

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: Column(
        children: [
          SizedBox(height: 12.0.s),
          _SkeletonBox(
            width: double.infinity,
            height: 30.0.s,
          ),
          SizedBox(height: 12.0.s),
          _SkeletonBox(
            width: double.infinity,
            height: 100.0.s,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showBackButton});

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return ScreenSideOffset.small(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (showBackButton) NavigationBackButton(context.pop),
          _SkeletonBox.square(size: 65.0.s),
          _SkeletonBox.square(size: 24.0.s, borderRadius: 8.0.s),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });
  const _SkeletonBox.square({
    required double size,
    double? borderRadius,
  }) : this(
          width: size,
          height: size,
          borderRadius: borderRadius,
        );

  final double width;
  final double height;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? 16.0.s;
    return Skeleton(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.theme.appColors.secondaryBackground,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
