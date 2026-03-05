// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/components/inputs/search_input/search_input.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/num.dart';

class RecentChatSkeleton extends StatelessWidget {
  const RecentChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Column(
        children: [
          Container(
            height: SearchInput.height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0.s),
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.0.s),
          Expanded(
            child: ListView.separated(
              restorationId: 'recent_chat_skeleton_scroll',
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Container(
                  height: 57.0.s,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0.s),
                    color: Colors.white,
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: 16.0.s);
              },
              itemCount: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentChatSkeletonItem extends StatelessWidget {
  const RecentChatSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Container(
        height: 57.0.s,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8.0.s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0.s),
          color: Colors.white,
        ),
      ),
    );
  }
}
