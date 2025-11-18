// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_app_bar.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';

class CreatePostAppBar extends StatelessWidget {
  const CreatePostAppBar({
    required this.createOption,
    required this.onClose,
    super.key,
  });

  final CreatePostOption createOption;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isVideo = createOption == CreatePostOption.video;

    return NavigationAppBar.modal(
      showBackButton: isVideo,
      title: Text(createOption.getTitle(context)),
      onBackPress: onClose,
      actions: [
        NavigationCloseButton(
          onPressed: onClose,
        ),
      ],
    );
  }
}
