// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';

class TopHoldersSkeleton extends StatelessWidget {
  const TopHoldersSkeleton({required this.count, required this.seperatorHeight, super.key});

  final int count;
  final double seperatorHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;

    return Skeleton(
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30.s,
                height: 30.s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.s),
                  color: colors.primaryBackground,
                ),
              ),
              SizedBox(width: 12.0.s),
              Container(
                width: 30.s,
                height: 30.s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.s),
                  color: colors.primaryBackground,
                ),
              ),
              SizedBox(width: 8.0.s),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 94.s,
                    height: 16.s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.s),
                      color: colors.primaryBackground,
                    ),
                  ),
                  SizedBox(height: 2.0.s),
                  Container(
                    width: 110.s,
                    height: 12.s,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.s),
                      color: colors.primaryBackground,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 54.s,
                height: 22.s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.s),
                  color: colors.primaryBackground,
                ),
              ),
            ],
          );
        },
        separatorBuilder: (context, index) {
          return SizedBox(height: seperatorHeight);
        },
      ),
    );
  }
}
