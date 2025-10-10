// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/skeleton/skeleton.dart';
import 'package:ion/app/extensions/extensions.dart';

class E2eeConversationLoadingView extends HookConsumerWidget {
  const E2eeConversationLoadingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        final dateSkeletonHeight = 18.0.s + 12.0.s;
        final messageHeight = 42.0.s;
        final smallSpacing = 8.0.s;
        final mediumSpacing = 16.0.s;
        final topPadding = 12.0.s;

        var usedHeight = topPadding + dateSkeletonHeight;

        final allMessages = [
          (width: 238.0, isMe: false, spacing: smallSpacing),
          (width: 172.0, isMe: false, spacing: mediumSpacing),
          (width: 214.0, isMe: true, spacing: smallSpacing),
          (width: 282.0, isMe: true, spacing: mediumSpacing),
          (width: 86.0, isMe: false, spacing: smallSpacing),
          (width: 150.0, isMe: false, spacing: mediumSpacing),
          (width: 199.0, isMe: true, spacing: smallSpacing),
          (width: 168.0, isMe: true, spacing: mediumSpacing),
          (width: 86.0, isMe: false, spacing: smallSpacing),
          (width: 154.0, isMe: false, spacing: mediumSpacing),
          (width: 199.0, isMe: true, spacing: smallSpacing),
          (width: 168.0, isMe: true, spacing: mediumSpacing),
          (width: 86.0, isMe: false, spacing: smallSpacing),
          (width: 154.0, isMe: false, spacing: mediumSpacing),
          (width: 158.0, isMe: true, spacing: 0.0),
        ];

        // Calculate how many messages we can fit
        final messagesToShow = <({double width, bool isMe, double spacing})>[];
        for (final message in allMessages) {
          final messageWithSpacing = messageHeight + message.spacing;
          if (usedHeight + messageWithSpacing <= availableHeight) {
            messagesToShow.add(message);
            usedHeight += messageWithSpacing;
          } else {
            break;
          }
        }

        return Container(
          color: context.theme.appColors.primaryBackground,
          width: double.infinity,
          padding: EdgeInsetsDirectional.only(start: 16.0.s, end: 16.0.s, top: topPadding),
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
                  ...messagesToShow.expand(
                    (message) => [
                      _MessageSkeleton(
                        width: message.width,
                        isMe: message.isMe,
                      ),
                      if (message.spacing > 0) SizedBox(height: message.spacing),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
