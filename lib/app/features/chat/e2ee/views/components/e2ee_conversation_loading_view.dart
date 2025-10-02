// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';

class E2eeConversationLoadingView extends HookConsumerWidget {
  const E2eeConversationLoadingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: context.theme.appColors.primaryBackground,
      width: double.infinity,
      padding: EdgeInsetsDirectional.only(start: 16.0.s, end: 16.0.s, top: 12.0.s),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        child: Skeleton(
          baseColor: context.theme.appColors.onTertiaryFill,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DateSkeleton(),
              SizedBox(height: 12.0.s),
              const _MessageSkeleton(
                width: 238,
                isMe: false,
              ),
              SizedBox(height: 8.0.s),
              const _MessageSkeleton(
                width: 172,
                isMe: false,
              ),
              SizedBox(height: 16.0.s),
              const _MessageSkeleton(
                width: 214,
                isMe: true,
              ),
              SizedBox(height: 8.0.s),
              const _MessageSkeleton(
                width: 282,
                isMe: true,
              ),
              SizedBox(height: 16.0.s),
              const _MessageSkeleton(
                width: 86,
                isMe: false,
              ),
              SizedBox(height: 8.0.s),
              const _MessageSkeleton(
                width: 150,
                isMe: false,
              ),
              SizedBox(height: 16.0.s),
              const _MessageSkeleton(
                width: 199,
                isMe: true,
              ),
              SizedBox(height: 8.0.s),
              const _MessageSkeleton(
                width: 168,
                isMe: true,
              ),
              SizedBox(height: 16.0.s),
              const _MessageSkeleton(
                width: 86,
                isMe: false,
              ),
              SizedBox(height: 8.0.s),
              const _MessageSkeleton(
                width: 154,
                isMe: false,
              ),
              SizedBox(height: 16.0.s),
              const _MessageSkeleton(
                width: 158,
                isMe: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSkeleton extends StatelessWidget {
  const _DateSkeleton();

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        width: 52.0.s,
        height: 18.0.s,
        decoration: BoxDecoration(
          color: context.theme.appColors.primaryBackground,
          borderRadius: BorderRadius.circular(16.0.s),
        ),
      ),
    );
  }
}

class _MessageSkeleton extends StatelessWidget {
  const _MessageSkeleton({
    required this.width,
    required this.isMe,
  });

  final double width;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        width: width.s,
        height: 42.0.s,
        decoration: BoxDecoration(
          color: context.theme.appColors.primaryBackground,
          borderRadius: isMe
              ? BorderRadiusDirectional.only(
                  topStart: Radius.circular(12.0.s),
                  topEnd: Radius.circular(12.0.s),
                  bottomStart: Radius.circular(12.0.s),
                )
              : BorderRadiusDirectional.only(
                  topStart: Radius.circular(12.0.s),
                  topEnd: Radius.circular(12.0.s),
                  bottomEnd: Radius.circular(12.0.s),
                ),
        ),
      ),
    );
  }
}
